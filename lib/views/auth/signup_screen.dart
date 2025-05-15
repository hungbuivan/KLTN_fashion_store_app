// file: lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart'; // Nếu bạn muốn dùng Iconsax
import '../../providers/signup_provider.dart';
// Import màn hình OTP (bạn sẽ tạo sau)
// import 'otp_verification_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  // Hàm helper để tạo InputDecoration cho TextFormField, giúp code gọn hơn
  InputDecoration _buildInputDecoration(String hintText, {IconData? prefixIcon, Widget? suffixIcon, Color hintColor = Colors.grey}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600], size: 20) : null,
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
    );
  }

  // Hàm helper để tạo DropdownButtonFormField
  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String hintText,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first, // Đảm bảo value hợp lệ hoặc là item đầu tiên
        hint: Text(hintText, style: const TextStyle(color: Colors.grey)),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 5.0), // Điều chỉnh padding cho dropdown
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.black87)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator ?? (val) {
          if (val == null || val == items.firstWhere((item) => item.startsWith('Chọn'))) {
            return 'Vui lòng chọn một mục';
          }
          return null;
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final signupProvider = context.watch<SignupProvider>();
    final signupProviderActions = context.read<SignupProvider>();

    // Màu sắc (tương tự LoginScreen)
    final Color kPrimaryGradientStart = Colors.blue.shade900;
    final Color kPrimaryGradientMid = Colors.blue.shade800;
    final Color kPrimaryGradientEnd = Colors.blue.shade400;
    const Color kFormBackgroundColor = Colors.white;
    const Color kButtonColor = Colors.blue; // Màu nút Sign Up

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [kPrimaryGradientStart, kPrimaryGradientMid, kPrimaryGradientEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[

                const SizedBox(height: 100), // Giảm bớt để có không gian cho nút back
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text("Join us and start your journey!", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: kFormBackgroundColor,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50)),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Form(
                          key: signupProvider.signupFormKey,
                          child: Column(
                            children: <Widget>[
                              const SizedBox(height: 20),
                              // Form Fields Container
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(25, 77, 161, .15),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: <Widget>[
                                    // Họ và tên
                                    TextFormField(
                                      controller: signupProvider.fullNameController,
                                      decoration: _buildInputDecoration("Họ và tên", prefixIcon: Iconsax.user),
                                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                                    ),
                                    _buildDivider(),
                                    // Số điện thoại
                                    TextFormField(
                                      controller: signupProvider.phoneController,
                                      decoration: _buildInputDecoration("Số điện thoại", prefixIcon: Iconsax.call),
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                                        if (!RegExp(r"^(?:[+0]9)?[0-9]{10}$").hasMatch(value)) return 'Số điện thoại không hợp lệ';
                                        return null;
                                      },
                                    ),
                                    _buildDivider(),
                                    // Email
                                    TextFormField(
                                      controller: signupProvider.emailController,
                                      decoration: _buildInputDecoration("Email", prefixIcon: Iconsax.direct_right),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
                                        if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) return 'Email không hợp lệ';
                                        return null;
                                      },
                                    ),
                                    _buildDivider(),
                                    // Mật khẩu
                                    TextFormField(
                                      controller: signupProvider.passwordController,
                                      obscureText: signupProvider.hidePassword,
                                      decoration: _buildInputDecoration(
                                        "Mật khẩu",
                                        prefixIcon: Iconsax.key,
                                        suffixIcon: IconButton(
                                          icon: Icon(signupProvider.hidePassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey[600]),
                                          onPressed: signupProviderActions.toggleHidePassword,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                                        if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                                        return null;
                                      },
                                    ),
                                    _buildDivider(),
                                    // Xác nhận mật khẩu
                                    TextFormField(
                                      controller: signupProvider.confirmPasswordController,
                                      obscureText: signupProvider.hideConfirmPassword,
                                      decoration: _buildInputDecoration(
                                        "Xác nhận mật khẩu",
                                        prefixIcon: Iconsax.key,
                                        suffixIcon: IconButton(
                                          icon: Icon(signupProvider.hideConfirmPassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey[600]),
                                          onPressed: signupProviderActions.toggleHideConfirmPassword,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                                        if (value != signupProvider.passwordController.text) return 'Mật khẩu không khớp';
                                        return null;
                                      },
                                    ),
                                    _buildDivider(),
                                    // Địa chỉ - Tỉnh/Thành phố
                                    _buildDropdownField(
                                      value: signupProvider.selectedProvince,
                                      items: signupProvider.provinces,
                                      hintText: 'Tỉnh/Thành phố',
                                      onChanged: signupProviderActions.onProvinceChanged,
                                    ),
                                    _buildDivider(),
                                    // Địa chỉ - Quận/Huyện
                                    _buildDropdownField(
                                      value: signupProvider.selectedDistrict,
                                      items: signupProvider.districts,
                                      hintText: 'Quận/Huyện',
                                      onChanged: signupProviderActions.onDistrictChanged,
                                    ),
                                    _buildDivider(),
                                    // Địa chỉ - Phường/Xã
                                    _buildDropdownField(
                                      value: signupProvider.selectedWard,
                                      items: signupProvider.wards,
                                      hintText: 'Phường/Xã',
                                      onChanged: signupProviderActions.onWardChanged,
                                    ),
                                    _buildDivider(),
                                    // Địa chỉ - Số nhà, tên đường
                                    TextFormField(
                                      controller: signupProvider.streetAddressController,
                                      decoration: _buildInputDecoration("Số nhà, tên đường", prefixIcon: Iconsax.location),
                                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập số nhà, tên đường' : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Hiển thị thông báo lỗi từ Provider
                              if (signupProvider.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 15.0),
                                  child: Text(
                                    signupProvider.errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              // Nút Sign Up
                              signupProvider.isLoading
                                  ? CircularProgressIndicator(color: kButtonColor)
                                  : MaterialButton(
                                onPressed: () async {
                                  final success = await signupProviderActions.signupUser();
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Đăng ký thành công! Vui lòng kiểm tra email để kích hoạt."), backgroundColor: Colors.green),
                                    );
                                    Navigator.pushReplacementNamed(context, '/home');

                                  }

                                },
                                height: 50,
                                minWidth: double.infinity,
                                color: kButtonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                                  TextButton(
                                    onPressed: () {
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context); // Quay lại màn hình trước (thường là Login hoặc Welcome)
                                      } else {
                                        Navigator.pushReplacementNamed(context, '/login'); // Nếu không pop được thì về login
                                      }
                                    },
                                    child: Text("Login", style: TextStyle(color: kButtonColor, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          // Nút Back
          Positioned(
            top: MediaQuery.of(context).padding.top + 5,
            left: 5,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper để tạo đường kẻ phân cách
  Widget _buildDivider() {
    return Divider(height: 0, color: Colors.grey.shade200, thickness: 1);
  }
}
