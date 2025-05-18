// file: lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart'; // Nếu bạn dùng Iconsax
import '../../providers/forgot_password_provider.dart';
// Import màn hình nhập OTP và mật khẩu mới (sẽ tạo ở Bước 3)
import 'reset_password_with_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  @override
  void initState() {
    super.initState();
    // Reset trạng thái của provider khi màn hình được khởi tạo
    // để đảm bảo không còn dữ liệu từ lần sử dụng trước
    // Tuy nhiên, emailController có thể muốn giữ lại nếu người dùng quay lại.
    // Hoặc reset khi provider được tạo nếu dùng Provider.value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider.of<ForgotPasswordProvider>(context, listen: false).resetState(); // Cân nhắc
    });
  }

  void _submitRequestOtp(BuildContext context) async {
    final provider = Provider.of<ForgotPasswordProvider>(context, listen: false);
    final success = await provider.requestPasswordResetOtp();

    if (success && context.mounted) {
      // Hiển thị SnackBar thông báo (có thể lấy message từ provider)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.message ?? 'Mã OTP đã được gửi (nếu email tồn tại).'),
          backgroundColor: Colors.green,
        ),
      );
      // Điều hướng đến màn hình nhập OTP, truyền email đã nhập
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResetPasswordWithOtpScreen(email: provider.emailController.text),
      ));
    } else if (context.mounted && provider.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.message!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForgotPasswordProvider>(); // Lắng nghe thay đổi

    // Màu sắc dựa trên thiết kế bạn cung cấp (image_a43e52.png)
    const Color kPrimaryColor = Color(0xFFF7F7F7); // Màu nền sáng
    const Color kTextColor = Color(0xFF333333);
    const Color kSecondaryTextColor = Colors.black54;
    final Color kButtonColor = Colors.blue.shade600; // Màu nút (ví dụ)
    final Color kAppBarActionColor = Colors.blue.shade700;

    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Nền trong suốt
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: provider.forgotPasswordEmailFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    "Forgot Password?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Enter your email address below, and if an account exists, we'll send you a code to reset your password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: kSecondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "EMAIL ADDRESS", // "New Email" trong thiết kế có vẻ là label
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: provider.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: kButtonColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email của bạn';
                      }
                      if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                        return 'Định dạng email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Hiển thị thông báo lỗi từ provider (nếu có, sau khi nhấn nút)
                  if (provider.message != null && !provider.otpRequestSuccessful&& !provider.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        provider.message!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  provider.isLoading
                      ? Center(child: CircularProgressIndicator(color: kButtonColor))
                      : ElevatedButton(
                    onPressed: () => _submitRequestOtp(context),
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
                    child: const Text("Reset Password", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
