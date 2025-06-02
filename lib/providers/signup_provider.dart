// file: lib/providers/signup_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Import AuthProvider nếu bạn muốn tự động đăng nhập hoặc cập nhật trạng thái auth sau khi đăng ký
// import 'auth_provider.dart';
// Import User model nếu API đăng ký trả về User object và bạn muốn lưu nó
// import '../models/user_model.dart';

class SignupProvider with ChangeNotifier {
  // final AuthProvider? authProvider; // Tùy chọn
  // SignupProvider({this.authProvider});

  // TextEditingControllers cho các trường input
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  // Controller cho địa chỉ chi tiết (số nhà, tên đường)
  final TextEditingController streetAddressController = TextEditingController();


  String? _selectedGender; // Lưu giá trị giới tính đã chọn
  String? get selectedGender => _selectedGender;

  bool _hidePassword = true;
  bool get hidePassword => _hidePassword;

  bool _hideConfirmPassword = true;
  bool get hideConfirmPassword => _hideConfirmPassword;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _message; // Thông báo lỗi hoặc thành công
  String? get message => _message;

  void toggleHidePassword() {
    _hidePassword = !_hidePassword;
    notifyListeners();
  }

  void toggleHideConfirmPassword() {
    _hideConfirmPassword = !_hideConfirmPassword;
    notifyListeners();
  }

  void setSelectedGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setMessage(String? newMessage) {
    _message = newMessage;
    // Sẽ được gọi bởi setLoading hoặc hàm chính sau khi tất cả state được cập nhật
  }

  // Hàm reset trạng thái
  void resetState() {
    fullNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    phoneController.clear();
    streetAddressController.clear(); // Xóa cả địa chỉ chi tiết
    _selectedGender = null;
    _hidePassword = true;
    _hideConfirmPassword = true;
    _isLoading = false;
    _message = null;
    // Gọi notifyListeners() nếu bạn muốn UI reset ngay lập tức dựa trên các giá trị này
    // Thường thì widget gọi resetState sẽ tự build lại.
    // Hoặc bạn có thể gọi ở đây nếu cần.
    // notifyListeners();
  }

  Future<bool> signupUser({
    // Các tên Tỉnh, Huyện, Xã đã chọn từ AddressProvider
    String? provinceName,
    String? districtName,
    String? wardName,
  }) async {
    _setLoading(true);
    _setMessage(null); // Xóa message cũ

    // Xây dựng địa chỉ đầy đủ từ các thành phần
    List<String> addressParts = [];
    // Chỉ thêm phần địa chỉ chi tiết nếu nó không rỗng
    if (streetAddressController.text.trim().isNotEmpty) {
      addressParts.add(streetAddressController.text.trim());
    }
    // Thêm Phường/Xã, Quận/Huyện, Tỉnh/Thành phố nếu có
    if (wardName != null && wardName.isNotEmpty) {
      addressParts.add(wardName);
    }
    if (districtName != null && districtName.isNotEmpty) {
      addressParts.add(districtName);
    }
    if (provinceName != null && provinceName.isNotEmpty) {
      addressParts.add(provinceName);
    }
    // Ghép các phần lại, phân cách bằng dấu phẩy và dấu cách
    String fullAddress = addressParts.join(', ');

    // URL API đăng ký của bạn
    const String apiUrl = 'http://10.0.2.2:8080/api/auth/register'; // Thay đổi IP nếu cần

    final Map<String, dynamic> signupData = {
      'fullName': fullNameController.text.trim(),
      'email': emailController.text.trim().toLowerCase(),
      'password': passwordController.text,
      // Gửi null nếu phone rỗng, backend sẽ xử lý việc cho phép null hay không
      'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      // Gửi null nếu fullAddress rỗng
      'address': fullAddress.isEmpty ? null : fullAddress,
      'gender': _selectedGender, // Có thể là null nếu người dùng không chọn
      // Backend của bạn cần nhận trường 'address' này
      // và các trường khác như 'province', 'district', 'ward' nếu bạn quyết định gửi riêng.
    };

    print("SignupProvider: Đang gửi dữ liệu đăng ký đến $apiUrl: $signupData");

    bool success = false;
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(signupData),
      );

      Map<String, dynamic> responseData = {};
      try {
        responseData = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        print("SignupProvider: Không thể parse JSON response body: ${response.body}");
      }

      print("SignupProvider: Phản hồi API đăng ký - Status: ${response.statusCode}");
      print("SignupProvider: Phản hồi API đăng ký - Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) { // 201 Created hoặc 200 OK
        _setMessage(responseData['message'] as String? ?? "Đăng ký thành công!");
        success = true;
        // Ở đây bạn có thể không muốn tự động đăng nhập,
        // mà yêu cầu người dùng đăng nhập lại để đảm bảo luồng.
        // Nếu muốn tự động đăng nhập:
        // if (authProvider != null && responseData.containsKey('user') && responseData.containsKey('token')) {
        //   await authProvider.processLoginSuccess(responseData);
        // }
      } else {
        _setMessage(responseData['message'] as String? ?? "Đăng ký thất bại. Mã lỗi: ${response.statusCode}");
        success = false;
      }
    } catch (e) {
      _setMessage("Lỗi kết nối hoặc xử lý khi đăng ký: ${e.toString()}");
      print("SignupProvider: Lỗi trong quá trình đăng ký: $e");
      success = false;
    } finally {
      _setLoading(false); // Đảm bảo isLoading được đặt lại và UI được cập nhật
    }
    return success;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    streetAddressController.dispose(); // ✅ Nhớ dispose controller mới
    super.dispose();
  }
}