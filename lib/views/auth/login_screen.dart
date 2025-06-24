// file: screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart'; // Đường dẫn đến AuthProvider

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final authProviderActions = context.read<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    colors: [
                      Colors.blue.shade900,
                      Colors.blue.shade800,
                      Colors.blue.shade400
                    ]
                )
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 80,),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Đăng nhập", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),),
                      SizedBox(height: 10,),
                      Text("Chào mừng trở lại!", style: TextStyle(color: Colors.white, fontSize: 18),),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(50), topRight: Radius.circular(50))
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Form(
                          key: authProvider.loginFormKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const SizedBox(height: 40,),
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [BoxShadow(
                                        color: Color.fromRGBO(25, 77, 161, .2),
                                        blurRadius: 20,
                                        offset: Offset(0, 10)
                                    )]
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(color: Colors.grey.shade200))
                                      ),
                                      child: TextFormField(
                                        // ✅ SỬA Ở ĐÂY:
                                        controller: authProvider.emailController, // Đổi từ emailOrPhoneController
                                        decoration: const InputDecoration(
                                            hintText: "Email của bạn", // Có thể đổi hintText nếu chỉ chấp nhận email
                                            hintStyle: TextStyle(color: Colors.grey),
                                            border: InputBorder.none
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            // Sửa thông báo cho phù hợp
                                            return 'Vui lòng nhập email';
                                          }
                                          if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                            return 'Định dạng email không hợp lệ';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      child: TextFormField(
                                        controller: authProvider.passwordController,
                                        obscureText: authProvider.hidePassword,
                                        decoration: InputDecoration(
                                          hintText: "Mật khẩu",
                                          hintStyle: const TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              authProvider.hidePassword ? Iconsax.eye_slash : Iconsax.eye,
                                              color: Colors.grey,
                                            ),
                                            onPressed: authProviderActions.toggleHidePassword,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Vui lòng nhập mật khẩu';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40,),
                              TextButton(
                                  onPressed: () {
                                    // Reset trạng thái của ForgotPasswordProvider trước khi điều hướng (tùy chọn)
                                    // Provider.of<ForgotPasswordProvider>(context, listen: false).resetState();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                    );
                                  },
                                  child: const Text("Bạn quên mật khẩu?", style: TextStyle(color: Colors.grey),)
                              ),
                              const SizedBox(height: 30,),
                              authProvider.isLoading
                                  ? CircularProgressIndicator(color: Colors.blue.shade700,)
                                  : MaterialButton(
                                onPressed: () async {
                                  // ✅ SỬA Ở ĐÂY:
                                  final String? userRole = await authProviderActions.login();
                                  if (userRole != null && context.mounted) { // Kiểm tra userRole không null
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Đăng nhập thành công!"), backgroundColor: Colors.green)
                                    );
                                    // Điều hướng dựa trên vai trò
                                    if (userRole == 'admin') {
                                      Navigator.pushReplacementNamed(context, '/admin_panel');
                                    } else {
                                      Navigator.pushReplacementNamed(context, '/home');
                                    }
                                  } else if (context.mounted && authProvider.errorMessage != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(authProvider.errorMessage!), backgroundColor: Colors.redAccent)
                                    );
                                  }
                                },
                                height: 50,
                                minWidth: double.infinity,
                                color: Colors.blue[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Center(
                                  child: Text("Đăng nhập", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),),
                                ),
                              ),
                              const SizedBox(height: 40,),
                              const Text("Tiêp tục với", style: TextStyle(color: Colors.grey),),
                              const SizedBox(height: 30,),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: MaterialButton(
                                      onPressed: (){
                                        // TODO: Xử lý đăng nhập Facebook
                                      },
                                      height: 50,
                                      color: Colors.blue.shade800,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Center(
                                        child: Text("Facebook", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20,),
                                  Expanded(
                                    child: MaterialButton(
                                      onPressed: () {
                                        // TODO: Xử lý đăng nhập Github/Google
                                      },
                                      height: 50,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      color: Colors.black,
                                      child: const Center(
                                        child: Text("Google", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                                      ),
                                    ),
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                } else {
                  print("Không thể quay lại từ màn hình này.");
                }
              },
              tooltip: 'Back',
            ),
          ),
        ],
      ),
    );
  }
}
