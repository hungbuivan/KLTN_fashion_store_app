// file: screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Vẫn dùng cho các icon khác nếu có
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // ✅ Import FontAwesome

// Import các màn hình bạn sẽ điều hướng tới
// import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final Color kButtonLoginColor = Colors.blue.shade700; // Màu blue đậm cho nút Login
    final Color kButtonSignUpBorderColor = Colors.blue.shade700; // Màu viền blue cho nút Sign Up
    final Color kButtonSignUpTextColor = Colors.blue.shade700;
    const Color kTitleColor = Colors.black87;
    const Color kSubtitleColor = Colors.black54;
    const Color kSocialLoginTextColor = Colors.grey;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: [
                  SizedBox(
                    height: screenSize.height * 0.35,
                    // ✅ Thay thế Icon bằng Image.asset
                    child: Image.asset(
                      'assets/images/wellcome/wellcome.png', // 👈 THAY THẾ BẰNG TÊN FILE ẢNH CỦA BẠN
                      // Ví dụ: 'assets/images/welcome/illustration.png'
                      fit: BoxFit.contain, // Hoặc BoxFit.cover, BoxFit.fitHeight, etc. tùy theo ảnh
                      errorBuilder: (context, error, stackTrace) {
                        // Hiển thị placeholder hoặc thông báo lỗi nếu ảnh không tải được
                        print("Lỗi tải ảnh welcome: $error"); // Log lỗi ra console
                        return Center(
                          child: Icon(
                            Iconsax.gallery_slash, // Icon báo lỗi ảnh từ Iconsax
                            size: screenSize.height * 0.15,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),

                  ),
                  SizedBox(height: screenSize.height * 0.04),
                  const Text(
                    "Hello",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: kTitleColor,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.015),
                  const Text(
                    "Welcome, where\nyou shopping everything",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: kSubtitleColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenSize.height * 0.05),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                        print("Login button pressed");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonLoginColor,
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text("Login", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        print("Sign Up button pressed");

                         Navigator.pushNamed(context, '/signup');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        side: const BorderSide(color: Colors.blue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text("Sign Up", style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.04),
                  const Text(
                    "Sign up using",
                    style: TextStyle(
                      fontSize: 14,
                      color: kSocialLoginTextColor,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildSocialIconButton(
                        icon: FontAwesomeIcons.facebookF, // ✅ Sử dụng FontAwesome cho Facebook
                        color: const Color(0xFF3b5998),
                        onPressed: () {
                          print("Facebook login pressed");
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildSocialIconButton(
                        icon: FontAwesomeIcons.google, // ✅ Sử dụng FontAwesome cho Google
                        color: const Color(0xFFDB4437),
                        onPressed: () {
                          print("Google login pressed");
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildSocialIconButton(
                        // Giữ lại Iconsax cho LinkedIn nếu bạn muốn, hoặc đổi sang FontAwesomeIcons.linkedinIn
                        icon: Iconsax.instagram, // Hoặc FontAwesomeIcons.linkedinIn
                        color: const Color(0xFF0077b5), // Màu LinkedIn
                        onPressed: () {
                          print("LinkedIn/Instagram login pressed");
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIconButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        // Quan trọng: FontAwesomeIcons cần được truyền trực tiếp cho Icon widget
        child: FaIcon(icon, color: color, size: 24), // ✅ Sử dụng FaIcon cho FontAwesome
      ),
    );
  }
}
