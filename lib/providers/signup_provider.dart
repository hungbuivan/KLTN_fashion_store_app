// file: lib/providers/signup_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Giả sử bạn có các model cho địa chỉ (sẽ dùng sau khi có API backend)
// class Province { final String id; final String name; Province(this.id, this.name); }
// class District { final String id; final String name; District(this.id, this.name); }
// class Ward { final String id; final String name; Ward(this.id, this.name); }

class SignupProvider with ChangeNotifier {
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // Controllers cho các trường input
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController streetAddressController = TextEditingController(); // Số nhà, đường

  // Trạng thái cho Dropdowns địa chỉ
  // Ban đầu sẽ dùng dữ liệu giả, sau này sẽ lấy từ API
  List<String> provinces = ['Chọn Tỉnh/Thành phố', 'Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng'];
  String? selectedProvince = 'Chọn Tỉnh/Thành phố';

  List<String> districts = ['Chọn Quận/Huyện'];
  String? selectedDistrict = 'Chọn Quận/Huyện';

  List<String> wards = ['Chọn Phường/Xã'];
  String? selectedWard = 'Chọn Phường/Xã';

  // Trạng thái ẩn/hiện mật khẩu
  bool _hidePassword = true;
  bool get hidePassword => _hidePassword;

  bool _hideConfirmPassword = true;
  bool get hideConfirmPassword => _hideConfirmPassword;

  // Trạng thái loading và thông báo
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void toggleHidePassword() {
    _hidePassword = !_hidePassword;
    notifyListeners();
  }

  void toggleHideConfirmPassword() {
    _hideConfirmPassword = !_hideConfirmPassword;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    // notifyListeners(); // Có thể không cần notify ngay, để hàm signup làm
  }

  // Hàm cập nhật khi chọn Tỉnh/Thành
  void onProvinceChanged(String? newValue) {
    if (newValue != null && newValue != 'Chọn Tỉnh/Thành phố') {
      selectedProvince = newValue;
      // TODO: Gọi API để lấy danh sách Quận/Huyện dựa trên selectedProvince
      // Ví dụ:
      if (newValue == 'Hà Nội') {
        districts = ['Chọn Quận/Huyện', 'Ba Đình', 'Hoàn Kiếm', 'Hai Bà Trưng'];
      } else if (newValue == 'TP. Hồ Chí Minh') {
        districts = ['Chọn Quận/Huyện', 'Quận 1', 'Quận 3', 'Quận Bình Thạnh'];
      } else {
        districts = ['Chọn Quận/Huyện']; // Reset
      }
      selectedDistrict = 'Chọn Quận/Huyện'; // Reset quận/huyện
      wards = ['Chọn Phường/Xã']; // Reset phường/xã
      selectedWard = 'Chọn Phường/Xã';
    } else {
      // Nếu chọn lại "Chọn Tỉnh/Thành phố"
      selectedProvince = 'Chọn Tỉnh/Thành phố';
      districts = ['Chọn Quận/Huyện'];
      selectedDistrict = 'Chọn Quận/Huyện';
      wards = ['Chọn Phường/Xã'];
      selectedWard = 'Chọn Phường/Xã';
    }
    notifyListeners();
  }

  // Hàm cập nhật khi chọn Quận/Huyện
  void onDistrictChanged(String? newValue) {
    if (newValue != null && newValue != 'Chọn Quận/Huyện') {
      selectedDistrict = newValue;
      // TODO: Gọi API để lấy danh sách Phường/Xã dựa trên selectedDistrict
      // Ví dụ:
      if (newValue == 'Ba Đình') {
        wards = ['Chọn Phường/Xã', 'Phúc Xá', 'Trúc Bạch'];
      } else if (newValue == 'Quận 1') {
        wards = ['Chọn Phường/Xã', 'Bến Nghé', 'Bến Thành'];
      } else {
        wards = ['Chọn Phường/Xã']; // Reset
      }
      selectedWard = 'Chọn Phường/Xã'; // Reset phường/xã
    } else {
      selectedDistrict = 'Chọn Quận/Huyện';
      wards = ['Chọn Phường/Xã'];
      selectedWard = 'Chọn Phường/Xã';
    }
    notifyListeners();
  }

  // Hàm cập nhật khi chọn Phường/Xã
  void onWardChanged(String? newValue) {
    if (newValue != null && newValue != 'Chọn Phường/Xã') {
      selectedWard = newValue;
    } else {
      selectedWard = 'Chọn Phường/Xã';
    }
    notifyListeners();
  }

  // Hàm xử lý logic đăng ký
  Future<bool> signupUser() async {
    if (!signupFormKey.currentState!.validate()) {
      _setErrorMessage("Vui lòng điền đầy đủ và đúng thông tin.");
      notifyListeners();
      return false;
    }
    if (selectedProvince == 'Chọn Tỉnh/Thành phố' ||
        selectedDistrict == 'Chọn Quận/Huyện' ||
        selectedWard == 'Chọn Phường/Xã') {
      _setErrorMessage("Vui lòng chọn đầy đủ địa chỉ.");
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _setErrorMessage(null);

    // Tạo đối tượng địa chỉ hoàn chỉnh
    String fullAddress = "${streetAddressController.text.trim()}, $selectedWard, $selectedDistrict, $selectedProvince";

    // URL API đăng ký (thay đổi cho phù hợp)
    // Nếu dùng Android emulator: 'http://10.0.2.2:8080/api/auth/register'
    const String apiUrl = 'http://10.0.2.2:8080/api/auth/register';

    print('SignupProvider: Đang cố gắng đăng ký với email: ${emailController.text}');
    print('SignupProvider: Địa chỉ đầy đủ: $fullAddress');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'fullName': fullNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'address': fullAddress, // Gửi địa chỉ đầy đủ
          // Backend của bạn có thể cần các trường riêng cho tỉnh, huyện, xã
          // 'province': selectedProvince,
          // 'district': selectedDistrict,
          // 'ward': selectedWard,
          // 'street': streetAddressController.text.trim(),
        }),
      );

      print('SignupProvider: Phản hồi API Đăng ký - Status: ${response.statusCode}');
      print('SignupProvider: Phản hồi API Đăng ký - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) { // 201 Created hoặc 200 OK
        // Đăng ký thành công (backend đã gửi OTP và lưu user tạm)
        _setLoading(false);
        notifyListeners();
        return true; // Báo hiệu thành công để UI điều hướng sang màn hình OTP
      } else {
        String serverMessage = "Đăng ký thất bại.";
        try {
          final errorData = jsonDecode(response.body);
          serverMessage = errorData['message'] ?? errorData['error'] ?? 'Lỗi từ server (Code: ${response.statusCode})';
        } catch (e) {
          serverMessage = 'Lỗi không xác định từ server (Code: ${response.statusCode})';
        }
        _setErrorMessage(serverMessage);
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('SignupProvider: Lỗi API Đăng ký - $e');
      _setErrorMessage('Không thể kết nối đến máy chủ hoặc có lỗi xảy ra.');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    streetAddressController.dispose();
    super.dispose();
  }
}
