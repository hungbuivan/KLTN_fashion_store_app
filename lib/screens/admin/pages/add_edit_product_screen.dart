// file: lib/screens/admin/pages/add_edit_product_screen.dart
import 'package:fashion_store_app/core/theme/constant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io'; // Để làm việc với File
import 'package:image_picker/image_picker.dart'; // Import image_picker
import '../../../models/admin/product_admin_model.dart';
import '../../../providers/product_admin_provider.dart';

const String backendBaseUrl = "http://10.0.2.2:8080";

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
    super.dispose();
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
      return;
    }
    _formKey.currentState!.save();
    setState(() { _isSaving = true; });

    final productAdminProvider = Provider.of<ProductAdminProvider>(context, listen: false);

    // Tạo Map productDataMap để gửi đi
    Map<String, dynamic> productDataMap = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()),
      'stock': int.tryParse(_stockController.text.trim()),
      // 'categoryId': _selectedCategoryId, // TODO: Lấy từ state của bạn (ví dụ: int? _selectedCategoryId;)
      // 'brandId': _selectedBrandId,       // TODO: Lấy từ state của bạn (ví dụ: int? _selectedBrandId;)
      'isPopular': _isPopular,
      // 'isFavorite': _isFavorite, // Nếu bạn có trường isFavorite trong ProductUpdateRequest và ProductAdminModel
    };

    // Xử lý imageUrl và removeCurrentImage
    if (_isEditMode) {
      // Thêm cờ removeCurrentImage vào productDataMap cho chế độ update
      productDataMap['removeCurrentImage'] = _removeCurrentImage && _selectedImageFile == null;

      if (_selectedImageFile == null && !_removeCurrentImage && _imageUrlController.text.trim().isNotEmpty) {
        // Nếu không có file mới, không yêu cầu xóa, và có URL trong controller -> gửi URL đó
        productDataMap['imageUrl'] = _imageUrlController.text.trim();
      } else if (_selectedImageFile == null && _removeCurrentImage) {
        // Nếu yêu cầu xóa và không có file mới, backend sẽ xóa dựa trên removeCurrentImage = true
        // Không cần gửi imageUrl nếu nó sẽ bị xóa, hoặc gửi null nếu backend của bạn mong đợi vậy
        productDataMap['imageUrl'] = null; // Hoặc không thêm key này, tùy backend
      }
      // Nếu có _selectedImageFile, imageUrl sẽ được xử lý bởi backend từ file upload,
      // không cần thêm 'imageUrl' vào productDataMap từ _imageUrlController.
    } else { // Chế độ tạo mới
      if (_selectedImageFile == null && _imageUrlController.text.trim().isNotEmpty) {
        productDataMap['imageUrl'] = _imageUrlController.text.trim();
      }
      // Nếu có _selectedImageFile, không cần gửi 'imageUrl' trong productDataMap
    }

    // (Tùy chọn) Loại bỏ các key có giá trị null khỏi productDataMap nếu backend của bạn không muốn nhận chúng
    // productDataMap.removeWhere((key, value) => value == null);

    ProductAdminModel? resultProduct;
    try {
      if (_isEditMode) {
        productDataMap['removeCurrentImage'] = _removeCurrentImage && _selectedImageFile == null;

        if (_selectedImageFile == null && !_removeCurrentImage) {
          // Chỉ gửi imageUrl nếu người dùng thực sự sửa đổi nó trong _imageUrlController
          // và nó là một URL đầy đủ hợp lệ, HOẶC nếu bạn muốn cho phép gửi path tương đối
          // và backend sẽ bỏ qua validation @Pattern nếu nó là path tương đối (cần sửa backend).
          // Tạm thời, để tránh lỗi validation, chỉ gửi nếu nó thực sự là URL mới hoặc không gửi gì cả
          // nếu _imageUrlController.text vẫn là path tương đối cũ.
          String currentImageUrlInController = _imageUrlController.text.trim();
          if (currentImageUrlInController.isNotEmpty &&
              (currentImageUrlInController.startsWith('http://') || currentImageUrlInController.startsWith('https://'))) {
            // Nếu người dùng nhập một URL đầy đủ mới vào controller
            productDataMap['imageUrl'] = currentImageUrlInController;
          }
          // KHÔNG gửi productDataMap['imageUrl'] nếu _imageUrlController.text là path tương đối cũ
          // như "/images/products/..." hoặc "viettien_shirt.jpg".
          // Backend sẽ giữ nguyên imageUrl hiện tại của sản phẩm nếu không có file mới và không có
          // productDataMap['imageUrl'] mới được gửi (hoặc nếu nó null và removeCurrentImage là false).
        }
        // Nếu có _selectedImageFile, không cần gửi 'imageUrl' trong productDataMap
      } else { // Chế độ tạo mới
        if (_selectedImageFile == null && _imageUrlController.text.trim().isNotEmpty) {
          // Cho phép gửi URL từ controller khi tạo mới nếu nó hợp lệ
          if (_imageUrlController.text.trim().startsWith('http://') || _imageUrlController.text.trim().startsWith('https://')) {
            productDataMap['imageUrl'] = _imageUrlController.text.trim();
          } else {
            // Nếu không phải URL đầy đủ, không gửi hoặc báo lỗi ở client trước khi gửi
            print("URL hình ảnh không hợp lệ khi tạo mới, không gửi: ${_imageUrlController.text.trim()}");
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi không mong muốn: ${error.toString()}'), backgroundColor: Colors.red),
        );
      }
      resultProduct = null;
    }

    if (mounted) { // Kiểm tra mounted trước khi gọi setState
      setState(() { _isSaving = false; });
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
            content: Text(errorMsg != null && errorMsg.isNotEmpty ? errorMsg : 'Lỗi khi lưu sản phẩm. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
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
        imageToShowUrl = backendBaseUrl + "/images/products/" + pathOrUrl;
      }
      print("AddEditScreen build: Value PASSED to Image.network: '$imageToShowUrl'"); // << IN Ở ĐÂY
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(
          imageToShowUrl!, // Chắc chắn không null ở đây do điều kiện if
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
                          ? ClipRRect( // Để bo góc ảnh preview
                        borderRadius: BorderRadius.circular(7),
                        child: Image.file(
                          _selectedImageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                          : (_imageUrlController.text.isNotEmpty) // Kiểm tra URL từ controller
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          _imageUrlController.text,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            // Giá trị của imageToShowUrl tại thời điểm lỗi này là gì?
                            print("AddEditScreen Image.network INSIDE errorBuilder - URL was: '$imageToShowUrl' - ERROR: $error");
                            // Thử in lại _imageUrlController.text ở đây xem có gì lạ không
                            print("AddEditScreen Image.network INSIDE errorBuilder - _imageUrlController.text: '${_imageUrlController.text}'");
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
                              _removeCurrentImage = true; // Đặt cờ để báo cho backend xóa
                            });
                          },
                        ),
                    ],
                  ),
                  // Tùy chọn: Vẫn cho phép nhập URL nếu muốn
                  // TextFormField(
                  //   controller: _imageUrlController,
                  //   decoration: const InputDecoration(labelText: 'Hoặc nhập URL Hình ảnh', border: OutlineInputBorder()),
                  //   keyboardType: TextInputType.url,
                  //   validator: (value) {
                  //     if (_selectedImageFile == null && (value == null || value.trim().isEmpty) && !_removeCurrentImage) {
                  //       // return 'Vui lòng chọn ảnh hoặc nhập URL'; // Bỏ comment nếu muốn bắt buộc có ảnh
                  //     }
                  //     if (value != null && value.trim().isNotEmpty && !Uri.parse(value.trim()).isAbsolute) {
                  //       return 'URL không hợp lệ';
                  //     }
                  //     return null;
                  //   },
                  // ),
                ],
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
}