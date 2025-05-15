// providers/forgot_password_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordProvider with ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _message; // Có thể là success hoặc error message
  String? get message => _message;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;


  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setMessage(String? newMessage, {bool success = false}) {
    _message = newMessage;
    _isSuccess = success;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail() async {
    if (!formKey.currentState!.validate()) {
      _setMessage("Please enter a valid email address.", success: false);
      return;
    }

    _setLoading(true);
    _setMessage(null); // Xóa message cũ

    // QUAN TRỌNG: Chọn đúng URL API tùy theo môi trường bạn chạy Flutter
    // 1. Nếu chạy trên Android Emulator:
    // const String apiUrl = 'http://10.0.2.2:8080/api/auth/forgot-password';
    // 2. Nếu chạy trên iOS Simulator hoặc thiết bị thật (thay YOUR_COMPUTER_IP bằng IP máy bạn):
    // const String apiUrl = 'http://YOUR_COMPUTER_IP:8080/api/auth/forgot-password';
    // 3. Nếu chạy Flutter Web trên cùng máy với backend:
    const String apiUrl = 'http://10.0.2.2:8080/api/auth/forgot-password'; // Dùng tạm, CẨN THẬN URL NÀY

    final String email = emailController.text.trim();
    print('Attempting to send password reset for email: $email to URL: $apiUrl');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email}),
      );

      print('Forgot Password API Response Status: ${response.statusCode}');
      print('Forgot Password API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _setMessage(responseData['message'] ?? "If your email is registered, you will receive a password reset link shortly.", success: true);
      } else {
        String errorMessage = "Failed to send password reset email.";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Error: ${response.statusCode}';
        } catch (e) {
          // Giữ nguyên errorMessage mặc định nếu không parse được JSON
        }
        _setMessage(errorMessage, success: false);
      }
    } catch (e) {
      print('Forgot Password API Error: $e');
      _setMessage('Could not connect to the server or an error occurred. Please try again.', success: false);
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
