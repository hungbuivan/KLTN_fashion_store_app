// file: lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart'; // Đảm bảo đường dẫn này đúng

enum AuthInitStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  // ✅ _isLoading giờ chỉ dành cho hành động login/signup thủ công
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthInitStatus _authInitStatus = AuthInitStatus.unknown;
  AuthInitStatus get authInitStatus => _authInitStatus;

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _hidePassword = true;
  bool get hidePassword => _hidePassword;

  final _secureStorage = const FlutterSecureStorage();
  static const _userDataKey = 'current_user_data_v3';

  AuthProvider() {
    _tryAutoLogin();
  }

  bool get isAuthenticated => _authInitStatus == AuthInitStatus.authenticated && _user != null;
  bool get isGuest => _authInitStatus == AuthInitStatus.unauthenticated || _user == null;
  bool get isAdmin => isAuthenticated && _user?.role == 'admin';
  bool get isRegularUser => isAuthenticated && _user?.role == 'user';

  Future<void> _tryAutoLogin() async {
    // ✅ Không set _isLoading = true ở đây nữa.
    // Chỉ cập nhật _authInitStatus để DecisionScreen có thể hiển thị màn hình chờ.
    _authInitStatus = AuthInitStatus.unknown;
    notifyListeners(); // Thông báo app đang kiểm tra trạng thái ban đầu

    User? potentialUser;
    AuthInitStatus determinedStatus = AuthInitStatus.unauthenticated;

    try {
      final String? storedUserDataString = await _secureStorage.read(key: _userDataKey);

      if (storedUserDataString != null && storedUserDataString.isNotEmpty) {
        print("AuthProvider: Tìm thấy dữ liệu người dùng đã lưu.");
        try {
          final Map<String, dynamic> userDataMap = jsonDecode(storedUserDataString);
          potentialUser = User.fromJson(userDataMap);
          determinedStatus = AuthInitStatus.authenticated;
          print("AuthProvider: Tự động đăng nhập thành công cho: ${potentialUser.email}, Role: ${potentialUser.role}");
        } catch (e) {
          print("AuthProvider: Lỗi parse dữ liệu người dùng khi tự động đăng nhập: $e");
          await _clearAuthDataInternal();
          potentialUser = null;
          // determinedStatus vẫn là AuthInitStatus.unauthenticated
        }
      } else {
        print("AuthProvider: Không tìm thấy dữ liệu người dùng đã lưu.");
        // potentialUser là null, determinedStatus là AuthInitStatus.unauthenticated
      }
    } catch (e) {
      print("AuthProvider: Lỗi nghiêm trọng trong _tryAutoLogin: $e");
      potentialUser = null;
      determinedStatus = AuthInitStatus.unauthenticated;
    } finally {
      // Cập nhật _user và _authInitStatus. _isLoading không bị ảnh hưởng.
      _user = potentialUser;
      _authInitStatus = determinedStatus;
      notifyListeners(); // Thông báo trạng thái cuối cùng cho UI
      print("AuthProvider: _tryAutoLogin hoàn tất. authStatus: $_authInitStatus, User: ${_user?.email}");
      // print("AuthProvider: _tryAutoLogin hoàn tất. isLoading (không đổi): $_isLoading, authStatus: $_authInitStatus, User: ${_user?.email}");
    }
  }

  Future<void> processSuccessfulAuth(Map<String, dynamic> responseDataFromServer) async {
    // Hàm này được gọi bởi login() hoặc signupUser() (từ SignupProvider)
    // _isLoading đã được set true bởi hàm gọi nó.
    _errorMessage = null;

    User? authenticatedUser;
    AuthInitStatus statusAfterProcess = AuthInitStatus.unauthenticated;

    try {
      final userJson = responseDataFromServer['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw Exception("Dữ liệu 'user' không hợp lệ từ server.");
      }
      authenticatedUser = User.fromJson(userJson);
      await _secureStorage.write(key: _userDataKey, value: jsonEncode(authenticatedUser.toJson()));
      statusAfterProcess = AuthInitStatus.authenticated;
      print("AuthProvider: Đã xử lý xác thực thành công. User: ${authenticatedUser.email}, Role: ${authenticatedUser.role}");
    } catch (e) {
      print("AuthProvider: Lỗi khi xử lý dữ liệu xác thực: $e");
      _errorMessage = "Lỗi xử lý dữ liệu người dùng: ${e.toString()}";
      await _clearAuthDataInternal();
      authenticatedUser = null;
      // statusAfterProcess vẫn là unauthenticated
    }
    // Cập nhật state. _isLoading sẽ được hàm gọi (login/signup) đặt lại thành false.
    _user = authenticatedUser;
    _authInitStatus = statusAfterProcess;
    // Không gọi notifyListeners() ở đây, để hàm login/signup kiểm soát việc notify cuối cùng
  }

  Future<String?> login() async {
    if (!loginFormKey.currentState!.validate()) {
      _errorMessage = "Vui lòng điền đầy đủ thông tin.";
      notifyListeners();
      return null;
    }

    _isLoading = true; // ✅ Chỉ set isLoading = true khi hành động login bắt đầu
    _errorMessage = null;
    notifyListeners(); // Thông báo UI rằng đang loading

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    const String apiUrl = 'http://10.0.2.2:8080/api/auth/login';
    print('AuthProvider: Đang cố gắng đăng nhập với email: $email');

    String? resultRole;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('AuthProvider: Phản hồi API Đăng nhập - Status: ${response.statusCode}');
      print('AuthProvider: Phản hồi API Đăng nhập - Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        await processSuccessfulAuth(responseData); // Cập nhật _user và _authInitStatus
        resultRole = _user?.role;
      } else {
        String serverMessage = "Đăng nhập thất bại.";
        try {
          final errorData = jsonDecode(response.body);
          serverMessage = errorData['message'] ?? errorData['error'] ?? 'Lỗi từ server (Code: ${response.statusCode})';
        } catch (e) {
          serverMessage = 'Lỗi không xác định từ server (Code: ${response.statusCode})';
        }
        _errorMessage = serverMessage;
        _authInitStatus = AuthInitStatus.unauthenticated;
        resultRole = null;
      }
    } catch (e) {
      print('AuthProvider: Lỗi API Đăng nhập - $e');
      _errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại.';
      _authInitStatus = AuthInitStatus.unauthenticated;
      resultRole = null;
    } finally {
      _isLoading = false; // ✅ Luôn đặt lại isLoading khi login hoàn tất
      notifyListeners(); // Thông báo trạng thái cuối cùng của hành động login
    }
    return resultRole;
  }

  Future<void> _clearAuthDataInternal() async {
    _user = null;
    await _secureStorage.delete(key: _userDataKey);
  }

  Future<void> logout() async {
    _isLoading = true; // Có thể có loading cho logout
    notifyListeners();

    await _clearAuthDataInternal();
    _authInitStatus = AuthInitStatus.unauthenticated;
    emailController.clear();
    passwordController.clear();
    _isLoading = false; // Kết thúc loading cho logout
    notifyListeners();
    print("AuthProvider: Người dùng đã đăng xuất, dữ liệu đã được xóa.");
  }

  void toggleHidePassword() {
    _hidePassword = !_hidePassword;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
