// file: lib/providers/forgot_password_provider.dart
import 'dart:convert'; // Để sử dụng jsonEncode và jsonDecode
import 'package:flutter/material.dart'; // Cần cho ChangeNotifier
import 'package:http/http.dart' as http; // Package để thực hiện HTTP requests

class ForgotPasswordProvider with ChangeNotifier {
  // GlobalKey để quản lý Form cho màn hình nhập email
  final GlobalKey<FormState> forgotPasswordEmailFormKey = GlobalKey<FormState>();
  // GlobalKey để quản lý Form cho màn hình nhập OTP và mật khẩu mới
  final GlobalKey<FormState> resetPasswordFormKey = GlobalKey<FormState>();

  // Controllers cho các trường TextField
  final TextEditingController emailController = TextEditingController(); // Cho màn hình nhập email
  final TextEditingController otpController = TextEditingController();     // Cho màn hình nhập OTP
  final TextEditingController newPasswordController = TextEditingController(); // Mật khẩu mới
  final TextEditingController confirmNewPasswordController = TextEditingController(); // Xác nhận mật khẩu mới

  // Trạng thái ẩn/hiện mật khẩu (cho màn hình nhập mật khẩu mới)
  bool _hideNewPassword = true;
  bool get hideNewPassword => _hideNewPassword;

  bool _hideConfirmNewPassword = true;
  bool get hideConfirmNewPassword => _hideConfirmNewPassword;

  // Trạng thái loading chung cho các thao tác bất đồng bộ
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Thông báo (có thể là thành công hoặc lỗi)
  String? _message;
  String? get message => _message;

  // Cờ để xác định xem yêu cầu gửi OTP có thành công không (email tồn tại và server đã xử lý)
  // Dùng để quyết định có điều hướng sang màn hình nhập OTP hay không
  bool _otpRequestSuccessful = false;
  bool get otpRequestSuccessful => _otpRequestSuccessful;

  // Hàm toggle cho ẩn/hiện mật khẩu mới
  void toggleHideNewPassword() {
    _hideNewPassword = !_hideNewPassword;
    notifyListeners();
  }

  // Hàm toggle cho ẩn/hiện mật khẩu xác nhận
  void toggleHideConfirmNewPassword() {
    _hideConfirmNewPassword = !_hideConfirmNewPassword;
    notifyListeners();
  }

  // Hàm nội bộ để quản lý trạng thái loading
  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Tránh gọi notifyListeners không cần thiết
    _isLoading = loading;
    notifyListeners();
  }

  // Hàm nội bộ để đặt thông báo và có thể kèm trạng thái thành công/thất bại chung
  void _setMessage(String? newMessage) {
    _message = newMessage;
    // Không gọi notifyListeners() ở đây ngay, hàm chính sẽ gọi sau khi cập nhật tất cả state
  }

  // Hàm để reset các trạng thái khi bắt đầu một quy trình mới hoặc rời màn hình
  // (Ví dụ: khi người dùng quay lại từ màn hình OTP về màn hình nhập email)
  void resetForgotPasswordState() {
    // emailController.clear(); // Có thể không muốn clear email ngay
    _isLoading = false;
    _message = null;
    _otpRequestSuccessful = false;
    notifyListeners();
  }

  void resetOtpAndNewPasswordFields() {
    otpController.clear();
    newPasswordController.clear();
    confirmNewPasswordController.clear();
    _hideNewPassword = true;
    _hideConfirmNewPassword = true;
    _message = null; // Xóa message cũ liên quan đến OTP/reset
    _isLoading = false; // Đảm bảo không còn loading
    notifyListeners();
  }


  // Bước 1: Gửi yêu cầu tạo và gửi OTP reset mật khẩu
  Future<bool> requestPasswordResetOtp() async {
    // Validate form nhập email
    if (!forgotPasswordEmailFormKey.currentState!.validate()) {
      _setMessage("Vui lòng nhập địa chỉ email hợp lệ.");
      notifyListeners(); // Hiển thị lỗi validation ngay
      return false;
    }

    _setLoading(true); // Bắt đầu loading
    _setMessage(null);     // Xóa message cũ
    _otpRequestSuccessful = false; // Đặt lại cờ
    // notifyListeners(); // _setLoading đã gọi notifyListeners

    final String email = emailController.text.trim();
    // QUAN TRỌNG: Đảm bảo URL này đúng với backend và cấu hình mạng của bạn
    // Nếu dùng Android emulator: 'http://10.0.2.2:8080/api/auth/forgot-password'
    // Nếu dùng iOS simulator/thiết bị thật: 'http://YOUR_COMPUTER_IP:8080/api/auth/forgot-password'
    const String apiUrl = 'http://10.0.2.2:8080/api/auth/forgot-password'; // THAY THẾ NẾU CẦN

    print('ForgotPasswordProvider: Yêu cầu OTP cho email: $email tới URL: $apiUrl');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email}),
      );

      print('ForgotPasswordProvider: Phản hồi API /forgot-password - Status: ${response.statusCode}');
      print('ForgotPasswordProvider: Phản hồi API /forgot-password - Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) { // Backend trả về 200 OK nếu email tồn tại và OTP đã được xử lý để gửi
        _setMessage(responseData['message'] ?? "Mã OTP đã được gửi. Vui lòng kiểm tra email của bạn.");
        _otpRequestSuccessful = true; // Đặt cờ thành công để UI có thể điều hướng
      } else if (response.statusCode == 404) { // Backend trả về 404 nếu email không tồn tại
        _setMessage(responseData['message'] ?? "Email này chưa được đăng ký trong hệ thống.");
        _otpRequestSuccessful = false;
      } else { // Các lỗi khác từ server (400, 500, ...)
        _setMessage(responseData['message'] ?? "Không thể gửi yêu cầu. Vui lòng thử lại. (Code: ${response.statusCode})");
        _otpRequestSuccessful = false;
      }
    } catch (e) {
      print('ForgotPasswordProvider: Lỗi API /forgot-password - $e');
      _setMessage('Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại.');
      _otpRequestSuccessful = false;
    } finally {
      _setLoading(false); // Kết thúc loading
      // notifyListeners(); // _setMessage (nếu được gọi) và _setLoading đã gọi notifyListeners
    }
    return _otpRequestSuccessful; // Trả về kết quả của việc yêu cầu OTP
  }

  // Bước 2: Xác thực OTP và đặt lại mật khẩu mới
  Future<bool> verifyOtpAndResetPassword() async {
    // Validate form nhập OTP và mật khẩu mới
    if (!resetPasswordFormKey.currentState!.validate()) {
      _setMessage("Vui lòng điền đầy đủ OTP và mật khẩu mới hợp lệ.");
      notifyListeners();
      return false;
    }
    // Kiểm tra mật khẩu xác nhận có khớp không
    if (newPasswordController.text.trim() != confirmNewPasswordController.text.trim()) {
      _setMessage("Mật khẩu xác nhận không khớp.");
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _setMessage(null);
    // notifyListeners(); // _setLoading đã gọi

    final String email = emailController.text.trim(); // Email đã được nhập ở màn hình trước và vẫn còn trong controller
    final String otpCode = otpController.text.trim();
    final String newPassword = newPasswordController.text.trim();

    const String apiUrl = 'http://10.0.2.2:8080/api/auth/reset-password'; // THAY ĐỔI IP NẾU CẦN
    print('ForgotPasswordProvider: Đặt lại mật khẩu cho email: $email với OTP: $otpCode');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'otpCode': otpCode,
          'newPassword': newPassword,
        }),
      );

      print('ForgotPasswordProvider: Phản hồi API /reset-password - Status: ${response.statusCode}');
      print('ForgotPasswordProvider: Phản hồi API /reset-password - Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _setMessage(responseData['message'] ?? "Mật khẩu đã được đặt lại thành công!");
        _setLoading(false);
        notifyListeners();
        return true; // Đặt lại mật khẩu thành công
      } else {
        _setMessage(responseData['message'] ?? "Đặt lại mật khẩu thất bại. (Code: ${response.statusCode})");
        _setLoading(false);
        notifyListeners();
        return false; // Đặt lại mật khẩu thất bại
      }
    } catch (e) {
      print('ForgotPasswordProvider: Lỗi API /reset-password - $e');
      _setMessage('Không thể kết nối đến máy chủ hoặc có lỗi xảy ra.');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }
}
