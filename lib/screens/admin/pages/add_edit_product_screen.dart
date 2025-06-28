// file: lib/screens/admin/pages/add_edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Import các model và provider cần thiết
import '../../../models/admin/product_admin_model.dart';
import '../../../models/admin/product_variant_admin_model.dart';
import '../../../providers/brand_admin_provider.dart';
import '../../../providers/category_admin_provider.dart';
import '../../../providers/product_admin_provider.dart';

// Class helper để quản lý state của mỗi dòng variant trên UI
class VariantInputData {
  final int id; // ID tạm thời để xác định widget trong list
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final int? variantDbId; // ID thực tế từ database (nếu là variant đã có)

  VariantInputData({required this.id, this.variantDbId});

  // Chuyển đổi dữ liệu từ form thành Map để gửi lên API
  Map<String, dynamic> toJson() {
    return {
      'id': variantDbId,
      'size': sizeController.text.trim(),
      'color': colorController.text.trim(),
      'stock': int.tryParse(stockController.text.trim()) ?? 0,
      'price': priceController.text.trim().isEmpty
          ? null
          : double.tryParse(priceController.text.trim()),
    };
  }

  void dispose() {
    sizeController.dispose();
    colorController.dispose();
    stockController.dispose();
    priceController.dispose();
  }
}

class AddEditProductScreen extends StatefulWidget {
  final ProductAdminModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho sản phẩm chính
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedBrandId;

  // State quản lý ảnh
  List<XFile> _newImageFiles = [];
  List<String> _existingImageUrls = [];

  bool _isPopular = false;
  bool _isEditMode = false;
  bool _isSaving = false;

  // State quản lý variants
  List<VariantInputData> _variantRows = [];
  int _nextVariantId = 0;




  @override
  void initState() {
    super.initState();
    _isEditMode = widget.product != null;

    // ✅ Gán giá trị ban đầu cho dropdown khi edit
    _selectedCategoryId = widget.product?.categoryId;
    _selectedBrandId = widget.product?.brandId;

    // ✅ Gọi provider để tải danh sách
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryAdminProvider>().fetchAllCategories();
      context.read<BrandAdminProvider>().fetchAllBrands();
    });

    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _priceController.text = p.price?.toStringAsFixed(0) ?? '';
      _isPopular = p.isPopular ?? false;
      _selectedCategoryId = p.categoryId;
      _selectedBrandId = p.brandId;

      // Lưu lại danh sách URL ảnh đã có một cách an toàn
      _existingImageUrls = List<String>.from(p.imageUrls ?? []);

      // Điền dữ liệu cho các variant đã có
      if (p.variants.isNotEmpty) {
        _variantRows = p.variants.map((variant) {
          final newRow = VariantInputData(id: _nextVariantId++, variantDbId: variant.id);
          newRow.sizeController.text = variant.size ?? '';
          newRow.colorController.text = variant.color ?? '';
          newRow.stockController.text = variant.stock?.toString() ?? '0';
          newRow.priceController.text = variant.price?.toStringAsFixed(0) ?? '';
          return newRow;
        }).toList();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (var row in _variantRows) {
      row.dispose();
    }
    super.dispose();
  }

  String _fixImageUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return 'https://via.placeholder.com/150';
    if (url.startsWith('http')) {
      if (url.contains('://localhost:8080')) return url.replaceFirst('://localhost:8080', serverBase);
      return url;
    }
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/products/$url';
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final int maxImages = 3 - _existingImageUrls.length - _newImageFiles.length;
    if (maxImages <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn đã đạt số lượng ảnh tối đa (3 ảnh).')));
      return;
    }

    final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(pickedFiles.take(maxImages));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() { _newImageFiles.removeAt(index); });
  }

  void _removeExistingImage(int index) {
    setState(() { _existingImageUrls.removeAt(index); });
  }

  void _addVariantRow() {
    setState(() {
      _variantRows.add(VariantInputData(id: _nextVariantId++));
    });
  }

  void _removeVariantRow(int id) {
    setState(() {
      _variantRows.removeWhere((row) => row.id == id);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<ProductAdminProvider>();

    List<Map<String, dynamic>> variantsData = _variantRows
        .where((row) => row.sizeController.text.isNotEmpty || row.colorController.text.isNotEmpty)
        .map((row) => row.toJson())
        .toList();

    Map<String, dynamic> productDataMap = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()),
      'isPopular': _isPopular,
      'categoryId': _selectedCategoryId,
      'brandId': _selectedBrandId,
      'variants': variantsData,
      'existingImageUrls': _existingImageUrls
    };

    ProductAdminModel? resultProduct;
    try {
      if (_isEditMode) {
        resultProduct = await provider.updateProduct(productId: widget.product!.id, productDataMap: productDataMap, imageFiles: _newImageFiles);
      } else {
        resultProduct = await provider.createProduct(productDataMap, imageFiles: _newImageFiles);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${error.toString()}'), backgroundColor: Colors.red));
      }
    }

    // ✅ Thêm categoryId và brandId vào map dữ liệu
    final Map<String, dynamic> productData = {
      'name': _nameController.text.trim(),
      // ... (các trường khác)
      'categoryId': _selectedCategoryId,
      'brandId': _selectedBrandId,
      'variants': variantsData,
    };

    if (mounted) {
      setState(() => _isSaving = false);
      if (resultProduct != null) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Lỗi khi lưu sản phẩm.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    // ✅ Lấy dữ liệu từ provider để hiển thị trong dropdown
    final categoryProvider = context.watch<CategoryAdminProvider>();
    final brandProvider = context.watch<BrandAdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa Sản phẩm' : 'Thêm Sản phẩm Mới'),
        actions: [IconButton(icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Icon(Iconsax.save_2), onPressed: _isSaving ? null : _saveProduct, tooltip: 'Lưu')],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildSectionTitle("Thông tin chung"),
              const SizedBox(height: 16),
              TextFormField(controller: _nameController, decoration: _inputDecoration('Tên Sản phẩm *', prefixIcon: Iconsax.box_1), validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionController, decoration: _inputDecoration('Mô tả', prefixIcon: Iconsax.document_text), maxLines: 4),
              const SizedBox(height: 16),
              TextFormField(controller: _priceController, decoration: _inputDecoration('Giá gốc (VNĐ)', prefixIcon: Iconsax.money_2), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              // TODO: Thêm Dropdown cho Category và Brand ở đây
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                isExpanded: true,
                decoration: _inputDecoration('Danh mục'),
                hint: categoryProvider.isLoading ? const Text("Đang tải...") : const Text('Chọn danh mục'),
                items: categoryProvider.categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() { _selectedCategoryId = value; });
                },
              ),

              // ✅ THÊM DROPDOWN CHO BRAND
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedBrandId,
                isExpanded: true,
                decoration: _inputDecoration('Thương hiệu'),
                hint: brandProvider.isLoading ? const Text("Đang tải...") : const Text('Chọn thương hiệu'),
                items: brandProvider.brands.map((brand) {
                  return DropdownMenuItem<int>(
                    value: brand.id,
                    child: Text(brand.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() { _selectedBrandId = value; });
                },
              ),

              SwitchListTile(title: const Text('Sản phẩm phổ biến?'), value: _isPopular, onChanged: (bool value) => setState(() => _isPopular = value), secondary: Icon(_isPopular ? Iconsax.star_1 : Iconsax.star, color: _isPopular ? Colors.amber : Colors.grey)),
              _buildSectionTitle("Hình ảnh sản phẩm"),
              const Text("Ảnh đầu tiên sẽ là ảnh đại diện.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              _buildImagePickerSection(),
              _buildSectionTitle("Các phiên bản (Size, Màu sắc)"),
              if (_variantRows.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Sản phẩm này chưa có phiên bản.', style: TextStyle(color: Colors.grey)))),
              ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _variantRows.length, itemBuilder: (context, index) => _buildVariantInputRow(_variantRows[index])),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: TextButton.icon(icon: const Icon(Iconsax.add_square), label: const Text('Thêm phiên bản'), onPressed: _addVariantRow)),
              const SizedBox(height: 30),
              ElevatedButton.icon(icon: const Icon(Iconsax.save_2), label: Text(_isEditMode ? 'Cập nhật Sản phẩm' : 'Tạo Sản phẩm'), onPressed: _isSaving ? null : _saveProduct, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(top: 24, bottom: 8), child: Text(title, style: Theme.of(context).textTheme.titleLarge));
  }

  Widget _buildImagePickerSection() {
    final List<Widget> imageWidgets = [];
    final totalImages = _existingImageUrls.length + _newImageFiles.length;
    for (int i = 0; i < _existingImageUrls.length; i++) {
      imageWidgets.add(_buildImageContainer(image: Image.network(_fixImageUrl(_existingImageUrls[i]), fit: BoxFit.cover), onRemove: () => _removeExistingImage(i), isMain: i == 0));
    }
    for (int i = 0; i < _newImageFiles.length; i++) {
      imageWidgets.add(_buildImageContainer(image: Image.file(File(_newImageFiles[i].path), fit: BoxFit.cover), onRemove: () => _removeNewImage(i), isMain: imageWidgets.isEmpty));
    }
    if (totalImages < 3) {
      imageWidgets.add(_buildAddImageButton());
    }
    return Wrap(spacing: 10, runSpacing: 10, children: imageWidgets);
  }

  Widget _buildImageContainer({required Widget image, required VoidCallback onRemove, bool isMain = false}) {
    return SizedBox(width: 100, height: 100, child: Stack(children: [Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: image)), if (isMain) Positioned(bottom: 0, left: 0, right: 0, child: Container(color: Colors.black.withOpacity(0.6), padding: const EdgeInsets.symmetric(vertical: 2), child: const Text('Ảnh bìa', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10)))), Positioned(top: -10, right: -10, child: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: onRemove, tooltip: 'Xóa ảnh'))]));
  }

  Widget _buildAddImageButton() {
    return GestureDetector(onTap: _pickImages, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400, style: BorderStyle.none)), child: const Center(child: Icon(Iconsax.gallery_add, color: Colors.grey))));
  }

  Widget _buildVariantInputRow(VariantInputData variantData) {
    return Card(
      key: ValueKey(variantData.id),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: TextFormField(controller: variantData.sizeController, decoration: _inputDecoration('Size', hintText: 'S, M, 39...'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: variantData.colorController, decoration: _inputDecoration('Màu sắc', hintText: 'Đen...'))),
                IconButton(icon: const Icon(Iconsax.trash, color: Colors.redAccent), onPressed: () => _removeVariantRow(variantData.id), tooltip: 'Xóa phiên bản này'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: variantData.stockController, decoration: _inputDecoration('Tồn kho *'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (v == null || v.isEmpty) ? 'Nhập kho' : null)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: variantData.priceController, decoration: _inputDecoration('Giá riêng (tùy chọn)'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String labelText, {
        String? hintText,
        IconData? prefixIcon,
      }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

}
