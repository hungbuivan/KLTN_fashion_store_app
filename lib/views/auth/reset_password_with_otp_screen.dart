// file: lib/screens/reset_password_with_otp_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart'; // Sử dụng Iconsax cho icon
import '../../providers/forgot_password_provider.dart';
 // Đường dẫn đến ForgotPasswordProvider

class ResetPasswordWithOtpScreen extends StatefulWidget {
  final String email; // Email được truyền từ màn hình ForgotPasswordScreen

  const ResetPasswordWithOtpScreen({super.key, required this.email});

  @override
  State<ResetPasswordWithOtpScreen> createState() => _ResetPasswordWithOtpScreenState();
}

class _ResetPasswordWithOtpScreenState extends State<ResetPasswordWithOtpScreen> {

  @override
  void initState() {
    super.initState();
    // Khi màn hình được tạo, reset các trường OTP và mật khẩu mới trong provider
    // để đảm bảo không còn dữ liệu từ lần trước (nếu có)
    // Email controller trong provider sẽ giữ nguyên giá trị từ ForgotPasswordScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ForgotPasswordProvider>(context, listen: false).resetOtpAndNewPasswordFields();
    });
  }

  // Hàm xử lý khi người dùng nhấn nút "Đặt lại Mật khẩu"
  void _submitResetPassword(BuildContext context) async {
    final provider = Provider.of<ForgotPasswordProvider>(context, listen: false);
    // Hàm verifyOtpAndResetPassword sẽ gọi API backend
    final success = await provider.verifyOtpAndResetPassword();

    if (success && context.mounted) { // Luôn kiểm tra context.mounted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.message ?? 'Mật khẩu đã được đặt lại thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3), // Hiển thị lâu hơn một chút
        ),
      );
      // Điều hướng về màn hình đăng nhập và xóa tất cả các route trước đó khỏi stack.
      // Đảm bảo '/login_input' (hoặc tên route màn hình đăng nhập của bạn) đã được định nghĩa.
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else if (context.mounted && provider.message != null) {
      // Hiển thị lỗi nếu đặt lại mật khẩu thất bại
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.message!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    // Nếu success là false và provider.message là null (trường hợp hiếm),
    // có thể hiển thị một lỗi chung chung hoặc không làm gì (vì provider đã log lỗi).
  }

  @override
  Widget build(BuildContext context) {
    // context.watch để lắng nghe thay đổi và rebuild UI (ví dụ: khi _message hoặc _isLoading thay đổi)
    final provider = context.watch<ForgotPasswordProvider>();
    // context.read để gọi hàm mà không rebuild widget
    final providerActions = context.read<ForgotPasswordProvider>();

    // Màu sắc (tương tự ForgotPasswordScreen)
    const Color kPrimaryScreenColor = Color(0xFFF7F7F7); // Màu nền sáng
    const Color kTextColor = Color(0xFF333333);
    final Color kButtonColor = Colors.blue.shade600; // Màu nút chính
    final Color kAppBarActionColor = Colors.blue.shade700; // Màu cho nút "Hủy"

    return Scaffold(
      backgroundColor: kPrimaryScreenColor,
      appBar: AppBar(
        title: const Text(
          "Reset Password!",
          style: TextStyle(color: kTextColor, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent, // Nền trong suốt
        elevation: 0, // Bỏ shadow
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () => Navigator.of(context).pop(), // Quay lại màn hình nhập email
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Quay về màn hình đầu tiên của stack (thường là Welcome hoặc Login)
              // Hoặc cụ thể hơn là pop cho đến khi gặp route Login
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              "Close",
              style: TextStyle(color: kAppBarActionColor, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0), // Giảm padding một chút
            child: Form(
              key: provider.resetPasswordFormKey, // Sử dụng key từ provider
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Các nút sẽ chiếm hết chiều rộng
                children: <Widget>[
                  Image.asset(
                    'assets/images/reset_password.png', // 👈 THAY BẰNG ĐƯỜNG DẪN ẢNH CỦA BẠN
                     //height: 150, // Điều chỉnh kích thước
                    errorBuilder: (ctx, err, st) => Icon(Iconsax.box_remove, size: 100, color: Colors.grey[400]), // Fallback
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Xác thực Tài khoản", // Tiêu đề chính
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24, // Giảm kích thước một chút
                      fontWeight: FontWeight.bold,
                      color: kTextColor.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    // Hiển thị email mà OTP đã được gửi tới
                    "Một mã OTP đã được gửi đến email:\n${widget.email}\nVui lòng nhập mã đó và đặt lại mật khẩu mới.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 35),

                  // Trường nhập OTP
                  TextFormField(
                    controller: provider.otpController, // Controller từ provider
                    keyboardType: TextInputType.number,

                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: _inputDecoration(
                      "Nhập mã OTP", // Hint text
                      Iconsax.message_edit, // Icon
                      kButtonColor,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mã OTP';
                      }
                      if (value.trim().length != 6) {
                        return 'Mã OTP phải có 6 chữ số';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Trường nhập Mật khẩu mới
                  TextFormField(
                    controller: provider.newPasswordController,
                    obscureText: provider.hideNewPassword,
                    decoration: _inputDecoration(
                      "Mật khẩu mới",
                      Iconsax.key,
                      kButtonColor,
                      suffixIcon: IconButton(
                        icon: Icon(provider.hideNewPassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey[600]),
                        onPressed: providerActions.toggleHideNewPassword,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu mới';
                      }
                      if (value.length < 6) { // Ví dụ: yêu cầu ít nhất 6 ký tự
                        return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Trường Xác nhận Mật khẩu mới
                  TextFormField(
                    controller: provider.confirmNewPasswordController,
                    obscureText: provider.hideConfirmNewPassword,
                    decoration: _inputDecoration(
                      "Xác nhận mật khẩu mới",
                      Iconsax.key,
                      kButtonColor,
                      suffixIcon: IconButton(
                        icon: Icon(provider.hideConfirmNewPassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey[600]),
                        onPressed: providerActions.toggleHideConfirmNewPassword,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu mới';
                      }
                      if (value != provider.newPasswordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Hiển thị thông báo lỗi từ provider (nếu có)
                  if (provider.message != null && !provider.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        provider.message!,
                        style: TextStyle(
                          // Màu sắc của message sẽ phụ thuộc vào việc reset có thành công không
                          // (mặc dù nếu thành công thì sẽ điều hướng đi)
                            color: provider.message!.toLowerCase().contains("thành công") ? Colors.green : Colors.redAccent,
                            fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Nút "Đặt lại Mật khẩu"
                  provider.isLoading
                      ? Center(child: CircularProgressIndicator(color: kButtonColor))
                      : ElevatedButton(
                    onPressed: () => _submitResetPassword(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text("Đặt lại Mật khẩu", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hàm helper cho InputDecoration (có thể tùy chỉnh thêm)
  InputDecoration _inputDecoration(String hintText, IconData prefixIcon, Color focusedBorderColor, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[500]), // Màu hint nhạt hơn
      prefixIcon: Icon(prefixIcon, color: Colors.grey[700], size: 20), // Màu prefix icon
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white, // Nền trắng cho input field
      border: OutlineInputBorder( // Border mặc định
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder( // Border khi không focus
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder( // Border khi focus
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
