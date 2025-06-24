// file: lib/screens/admin/pages/add_edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io'; // Để làm việc với File
import 'package:image_picker/image_picker.dart'; // Import image_picker
import '../../../models/admin/product_admin_model.dart';
import '../../../providers/product_admin_provider.dart';

const String backendBaseUrl = "http://10.0.2.2:8080";
String _fixImageUrl(String? originalUrlFromApi) {
  const String serverBase = "http://10.0.2.2:8080";
  if (originalUrlFromApi == null || originalUrlFromApi.isEmpty) return '';
  if (originalUrlFromApi.startsWith('http')) return originalUrlFromApi;
  if (originalUrlFromApi.startsWith('/')) return serverBase + originalUrlFromApi;
  return '$serverBase/images/products/$originalUrlFromApi';
}

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
      'id': variantDbId, // Gửi id nếu là cập nhật
      'size': sizeController.text.trim(),
      'color': colorController.text.trim(),
      'stock': int.tryParse(stockController.text.trim()) ?? 0,
      'price': priceController.text.trim().isEmpty
          ? null
          : double.tryParse(priceController.text.trim()),
      // 'imageUrl': ... // Logic ảnh cho variant sẽ phức tạp hơn
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
  File? _selectedImageFile; // State để lưu file ảnh đã chọn

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController; // Vẫn giữ để hiển thị URL hiện tại hoặc nếu người dùng muốn nhập thủ công (tùy chọn)

  bool _isPopular = false;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _removeCurrentImage = false; // Cờ để xóa ảnh hiện tại khi edit



  // ✅ STATE MỚI: Thêm các biến này vào đầu class _AddEditProductScreenState
  List<VariantInputData> _variantRows = [];
  int _nextVariantId = 0; // Để tạo id duy nhất cho mỗi dòng variant

  // ✅ HÀM MỚI: Thêm một dòng variant trống
  void _addVariantRow() {
    setState(() {
      _variantRows.add(VariantInputData(id: _nextVariantId++));
    });
  }

  // ✅ HÀM MỚI: Xóa một dòng variant
  void _removeVariantRow(int id) {
    setState(() {
      _variantRows.removeWhere((row) => row.id == id);
    });
  }

  @override
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.product != null;

    print("AddEditScreen initState: widget.product is null? ${widget.product == null}");
    if (widget.product != null) {
      print("AddEditScreen initState: widget.product.id = ${widget.product!.id}");
      print("AddEditScreen initState: widget.product.name = ${widget.product!.name}");
      print("AddEditScreen initState: raw widget.product.imageUrl = '${widget.product!.imageUrl}'"); // QUAN TRỌNG
      final p = widget.product!;
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

    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price?.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock?.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');
    _isPopular = widget.product?.isPopular ?? false;
    // _isFavorite = widget.product?.isFavorite ?? false; // Nếu dùng

    print("AddEditScreen initState: _imageUrlController.text = '${_imageUrlController.text}'"); // QUAN TRỌNG
  }
    @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    for (var row in _variantRows) {
      row.dispose();
    }
    super.dispose();

  }
  // ✅ HÀM HELPER PHẢI ĐƯỢC ĐẶT BÊN TRONG CLASS _AddEditVoucherScreenState
  InputDecoration _inputDecoration(String label, {String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _imageUrlController.clear(); // Xóa URL cũ trong controller khi đã chọn file mới
        _removeCurrentImage = false; // Nếu chọn ảnh mới thì không xóa nữa
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      print("Form không hợp lệ.");
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    final productAdminProvider = Provider.of<ProductAdminProvider>(context, listen: false);

    // Thu thập dữ liệu từ các dòng variant
    List<Map<String, dynamic>> variantsData = _variantRows
        .where((row) => row.sizeController.text.isNotEmpty || row.colorController.text.isNotEmpty)
        .map((row) => row.toJson())
        .toList();

    // Map dữ liệu sản phẩm chính
    Map<String, dynamic> productDataMap = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()),
      // 'stock' sẽ được tính ở backend từ tổng stock của variants
      'isPopular': _isPopular,
      // 'categoryId': _selectedCategoryId, // Thêm category dropdown nếu cần
      // 'brandId': _selectedBrandId, // Thêm brand dropdown nếu cần
      'variants': variantsData, // Thêm danh sách variants vào request
    };

    print("✅ Base productDataMap: $productDataMap");

    if (_isEditMode) {
      productDataMap['removeCurrentImage'] = _removeCurrentImage && _selectedImageFile == null;

      if (_selectedImageFile == null && !_removeCurrentImage) {
        String currentUrl = _imageUrlController.text.trim();
        if (currentUrl.isNotEmpty &&
            (currentUrl.startsWith('http://') || currentUrl.startsWith('https://'))) {
          productDataMap['imageUrl'] = currentUrl;
          print("✅ imageUrl được giữ nguyên khi cập nhật: $currentUrl");
        } else {
          print("⚠️ Không gửi imageUrl vì là path tương đối hoặc trống.");
        }
      } else if (_selectedImageFile == null && _removeCurrentImage) {
        productDataMap['imageUrl'] = null;
        print("🗑️ Đánh dấu xóa ảnh hiện tại.");
      } else {
        print("🖼️ Có ảnh mới được chọn -> gửi qua Multipart.");
      }
    } else {
      // Chế độ tạo mới
      String newImageUrl = _imageUrlController.text.trim();
      if (_selectedImageFile == null && newImageUrl.isNotEmpty) {
        if (newImageUrl.startsWith('http://') || newImageUrl.startsWith('https://')) {
          productDataMap['imageUrl'] = newImageUrl;
          print("✅ imageUrl được gửi khi tạo mới: $newImageUrl");
        } else {
          print("⚠️ URL hình ảnh không hợp lệ khi tạo mới, không gửi: $newImageUrl");
        }
      }
    }

    ProductAdminModel? resultProduct;

    try {
      if (_isEditMode) {
        print("🚀 Đang cập nhật sản phẩm với ID: ${widget.product?.id}");
        resultProduct = await productAdminProvider.updateProduct(
          productId: widget.product!.id,
          productDataMap: productDataMap,
          imageFile: _selectedImageFile,
        );
      } else {
        print("🚀 Đang tạo mới sản phẩm...");
        resultProduct = await productAdminProvider.createProduct(
          productDataMap,
          imageFile: _selectedImageFile,
        );
      }


      print("✅ Kết quả trả về từ server: $resultProduct");
    } catch (error) {
      print("❌ Lỗi khi gửi dữ liệu: ${error.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi không mong muốn: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      resultProduct = null;
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }

    if (mounted) {
      if (resultProduct != null) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Sản phẩm đã được cập nhật!' : 'Sản phẩm đã được tạo!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorMsg = productAdminProvider.errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((errorMsg?.isNotEmpty ?? false)
                  ? errorMsg!
                  : 'Lỗi khi lưu sản phẩm. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            )

        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    String? imageToShowUrl; // Đổi tên biến để tránh nhầm lẫn
    Widget imageWidget;

    if (_selectedImageFile != null) {
      // Ưu tiên hiển thị file đã chọn (nếu có)
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.file(
          _selectedImageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
      print("AddEditScreen build: Displaying selected file: ${_selectedImageFile!.path}");
    } else if (_isEditMode && _imageUrlController.text.isNotEmpty) {
      // Nếu là chế độ sửa, chưa chọn file mới, và có URL/path trong controller
      String pathOrUrl = _imageUrlController.text;
      if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
        imageToShowUrl = pathOrUrl;
      } else if (pathOrUrl.startsWith('/')) {
        imageToShowUrl = backendBaseUrl + pathOrUrl;
      } else {
        // Giả sử là tên file nếu không phải URL và không bắt đầu bằng /
        imageToShowUrl = "$backendBaseUrl/images/products/$pathOrUrl";
      }
      print("AddEditScreen build: Value PASSED to Image.network: '$imageToShowUrl'"); // << IN Ở ĐÂY
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(
          imageToShowUrl, // Chắc chắn không null ở đây do điều kiện if
          //key: ValueKey(imageToShowUrl),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print("AddEditScreen Image.network ERROR using URL '$imageToShowUrl': $error");
            print("AddEditScreen Image.network StackTrace: $stackTrace");
            return const Center(child: Icon(Iconsax.gallery_slash, size: 50, color: Colors.grey));
          },
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            // ... loading indicator ...
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    } else {
      // Không có file chọn, không phải chế độ sửa có ảnh, hoặc tạo mới chưa chọn ảnh
      print("AddEditScreen build: No image to display.");
      imageWidget = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.gallery_export, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text('Chưa có ảnh', style: TextStyle(color: Colors.grey)),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa Sản phẩm' : 'Thêm Sản phẩm Mới'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Lưu',
            onPressed: _isSaving ? null : _saveProduct,
          )
        ],
      ),

      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),

        child: Form(

          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(

            children: <Widget>[
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,

                decoration: const InputDecoration(labelText: 'Tên Sản phẩm', border: OutlineInputBorder(), prefixIcon: Icon(Iconsax.box_1)),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên sản phẩm' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder(), prefixIcon: Icon(Iconsax.document_text)),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá (VND)', border: OutlineInputBorder(), prefixIcon: Icon(Iconsax.money_2)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Vui lòng nhập giá';
                  final price = double.tryParse(value.trim());
                  if (price == null) return 'Giá không hợp lệ';
                  if (price < 0) return 'Giá không được âm';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Số lượng tồn kho', border: OutlineInputBorder(), prefixIcon: Icon(Iconsax.box_add)),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số lượng';
                  final stock = int.tryParse(value.trim());
                  if (stock == null) return 'Số lượng không hợp lệ';
                  if (stock < 0) return 'Số lượng không được âm';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- PHẦN HÌNH ẢNH ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hình ảnh sản phẩm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _selectedImageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.file(
                          _selectedImageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                          : (_imageUrlController.text.isNotEmpty)
                          ? Builder(
                        builder: (context) {
                          final imageUrlToShow = _fixImageUrl(_imageUrlController.text);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              imageUrlToShow,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                print("Image.network ERROR URL: $imageUrlToShow");
                                return const Center(child: Icon(Iconsax.gallery_slash, size: 50, color: Colors.grey));
                              },
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      )
                          : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.gallery_export, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Chưa có ảnh', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Iconsax.gallery_add),
                        label: const Text('Chọn/Thay đổi ảnh'),
                        onPressed: _pickImage,
                      ),
                      if (_isEditMode && (_selectedImageFile != null || _imageUrlController.text.isNotEmpty))
                        TextButton.icon(
                          icon: Icon(Iconsax.trash, color: Colors.red.shade700),
                          label: Text('Xóa ảnh hiện tại', style: TextStyle(color: Colors.red.shade700)),
                          onPressed: () {
                            setState(() {
                              _selectedImageFile = null;
                              _imageUrlController.clear();
                              _removeCurrentImage = true;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
              // ✅ KHU VỰC QUẢN LÝ VARIANTS
              const Divider(height: 40, thickness: 1.5, indent: 20, endIndent: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Các phiên bản sản phẩm", style: Theme.of(context).textTheme.titleLarge),
                  IconButton.filled(
                    icon: const Icon(Iconsax.add),
                    onPressed: _addVariantRow,
                    tooltip: 'Thêm phiên bản',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_variantRows.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Sản phẩm này chưa có phiên bản (size, màu).', style: TextStyle(color: Colors.grey)))),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _variantRows.length,
                itemBuilder: (context, index) {
                  final variantRow = _variantRows[index];
                  return _buildVariantInputRow(variantRow);
                },
              ),

              const SizedBox(height: 16),

              // TODO: Thêm DropdownButtonFormField cho Category ID và Brand ID

              SwitchListTile(
                title: const Text('Sản phẩm phổ biến?'),
                value: _isPopular,
                onChanged: (bool value) => setState(() => _isPopular = value),
                secondary: Icon(_isPopular ? Iconsax.star_1 : Iconsax.star, color: _isPopular ? Colors.amber : Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Iconsax.save_2),
                label: Text(_isEditMode ? 'Lưu Thay đổi' : 'Thêm Sản phẩm'),
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget mới để xây dựng một hàng nhập liệu cho variant
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
                Expanded(child: TextFormField(controller: variantData.sizeController, decoration: _inputDecoration('Size', hint: 'S, M, 39...'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: variantData.colorController, decoration: _inputDecoration('Màu sắc', hint: 'Đen...'))),
                IconButton(
                  icon: const Icon(Iconsax.trash, color: Colors.redAccent),
                  onPressed: () => _removeVariantRow(variantData.id),
                  tooltip: 'Xóa phiên bản này',
                ),
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

}