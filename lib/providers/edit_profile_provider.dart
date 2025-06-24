// file: lib/providers/edit_profile_provider.dart
import 'dart:convert';
import 'dart:io'; // Để làm việc với File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'auth_provider.dart'; // Để cập nhật lại thông tin user

class EditProfileProvider with ChangeNotifier {
   AuthProvider authProvider;

  EditProfileProvider(this.authProvider);

  // Controllers cho các trường input
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Lưu trữ file ảnh đã chọn
  XFile? _pickedImageFile;
  XFile? get pickedImageFile => _pickedImageFile;

  // Trạng thái loading và message
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Điền dữ liệu ban đầu vào các controller từ user hiện tại
  void initialize() {
    if (authProvider.user != null) {
      fullNameController.text = authProvider.user!.fullName ?? '';
      phoneController.text = authProvider.user!.phone ?? '';
      _pickedImageFile = null; // Reset ảnh đã chọn mỗi khi vào màn hình
    }
  }

  // Hàm chọn ảnh từ thư viện
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        _pickedImageFile = image;
        notifyListeners(); // Cập nhật UI để hiển thị ảnh mới đã chọn
      }
    } catch (e) {
      _errorMessage = "Không thể chọn ảnh: ${e.toString()}";
      notifyListeners();
    }
  }

  // Xóa ảnh đã chọn
  void clearImage() {
    _pickedImageFile = null;
    notifyListeners();
  }

  // Hàm gọi API để cập nhật thông tin
   Future<bool> updateUserProfile() async {
     if (authProvider.user == null) {
       _errorMessage = "Bạn cần đăng nhập để thực hiện việc này.";
       return false;
     }

     _isLoading = true;
     _errorMessage = null;
     notifyListeners();

     try {
       final int userId = authProvider.user!.id;
       final url = Uri.parse('http://10.0.2.2:8080/api/users/$userId'); // URL backend

       var request = http.MultipartRequest('PUT', url);

       // Thêm các trường text
       request.fields['fullName'] = fullNameController.text.trim();
       request.fields['phone'] = phoneController.text.trim();

       // Nếu có ảnh thì thêm ảnh vào form-data
       if (_pickedImageFile != null) {
         request.files.add(
           await http.MultipartFile.fromPath(
             'avatarFile', // key phải trùng với @RequestPart("avatarFile") ở backend
             _pickedImageFile!.path,
           ),
         );
       }

       // ❗ FIX LỖI: Xoá header mặc định để không bị charset=UTF-8
       request.headers.clear();
       request.headers['Accept'] = 'application/json';
       // request.headers['Authorization'] = 'Bearer ${authProvider.token}'; // nếu cần xác thực

       print("Updating profile for user $userId...");
       final streamedResponse = await request.send();
       final response = await http.Response.fromStream(streamedResponse);

       print("Update profile response: ${response.statusCode} - ${response.body}");

       if (response.statusCode == 200) {
         await authProvider.fetchAndSetUser(); // cập nhật lại thông tin user mới
         _errorMessage = "Cập nhật thông tin thành công!";
         notifyListeners();
         return true;
       } else {
         final responseData = jsonDecode(response.body);
         _errorMessage = responseData['message'] ?? 'Cập nhật thất bại.';
       }
     } catch (e) {
       _errorMessage = "Lỗi kết nối hoặc xử lý: ${e.toString()}";
       print("Error updating profile: $e");
     } finally {
       _isLoading = false;
       notifyListeners();
     }

     return false;
   }

}