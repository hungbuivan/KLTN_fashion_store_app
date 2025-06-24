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
  static const _userDataKey = 'current_user_data_v3'; // Key để lưu trữ dữ liệu user

  // AuthProvider() {
  //   _tryAutoLogin();
  // }

  bool get isAuthenticated => _authInitStatus == AuthInitStatus.authenticated && _user != null;
  bool get isGuest => _authInitStatus == AuthInitStatus.unauthenticated || _user == null;
  bool get isAdmin => isAuthenticated && _user?.role == 'admin';
  bool get isRegularUser => isAuthenticated && _user?.role == 'user';

  // // Thử tự động đăng nhập khi khởi động app
  // Future<void> _tryAutoLogin() async {
  //   _authInitStatus = AuthInitStatus.unknown;
  //   notifyListeners();
  //
  //   User? potentialUser;
  //   AuthInitStatus determinedStatus = AuthInitStatus.unauthenticated;
  //
  //   try {
  //     final String? storedUserDataString = await _secureStorage.read(key: _userDataKey);
  //     if (storedUserDataString != null && storedUserDataString.isNotEmpty) {
  //       print("AuthProvider: Tìm thấy dữ liệu người dùng đã lưu.");
  //       try {
  //         final Map<String, dynamic> userDataMap = jsonDecode(storedUserDataString);
  //         potentialUser = User.fromJson(userDataMap);
  //         determinedStatus = AuthInitStatus.authenticated;
  //         print("AuthProvider: Tự động đăng nhập thành công cho: ${potentialUser.email}");
  //       } catch (e) {
  //         print("AuthProvider: Lỗi parse dữ liệu khi tự động đăng nhập: $e");
  //         await _clearAuthDataInternal();
  //       }
  //     }
  //   } catch (e) {
  //     print("AuthProvider: Lỗi nghiêm trọng trong _tryAutoLogin: $e");
  //   } finally {
  //     _user = potentialUser;
  //     _authInitStatus = determinedStatus;
  //     notifyListeners();
  //   }
  // }

  // Hàm nội bộ để xử lý và lưu dữ liệu sau khi đăng nhập/đăng ký/cập nhật thành công
  Future<void> processSuccessfulAuth(Map<String, dynamic> responseDataFromServer) async {
    _errorMessage = null;
    try {
      final userJson = responseDataFromServer['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw Exception("Dữ liệu 'user' không hợp lệ từ server.");
      }
      _user = User.fromJson(userJson);
      await _secureStorage.write(key: _userDataKey, value: jsonEncode(_user!.toJson()));
      _authInitStatus = AuthInitStatus.authenticated;
      print("AuthProvider: Đã xử lý xác thực thành công. User: ${_user!.email}, Role: ${_user!.role}");
      print("Thông tin user:");
      print("Họ tên: ${_user!.fullName}");
      print("Email: ${_user!.email}");
      print("Vai trò: ${_user!.role}");

    } catch (e) {
      print("AuthProvider: Lỗi khi xử lý dữ liệu xác thực: $e");
      _errorMessage = "Lỗi xử lý dữ liệu người dùng: ${e.toString()}";
      await _clearAuthDataInternal();
    }
  }

  // Hàm đăng nhập
  Future<String?> login() async {
    if (!(loginFormKey.currentState?.validate() ?? false)) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    const String apiUrl = 'http://10.0.2.2:8080/api/auth/login';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        print("Response body: ${response.body}");
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        await processSuccessfulAuth(responseData);
        return _user?.role;

      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = errorData['message'] ?? 'Đăng nhập thất bại.';
      }
    } catch (e) {
      _errorMessage = 'Không thể kết nối đến máy chủ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Hàm nội bộ để xóa dữ liệu lưu trữ
  Future<void> _clearAuthDataInternal() async {
    _user = null;
    _authInitStatus = AuthInitStatus.unauthenticated;
    await _secureStorage.delete(key: _userDataKey);
  }

  // Hàm đăng xuất
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _clearAuthDataInternal();
    emailController.clear();
    passwordController.clear();
    _isLoading = false;
    notifyListeners();
    print("AuthProvider: Người dùng đã đăng xuất.");
  }

  // ✅ HÀM MỚI ĐƯỢC THÊM VÀO
  /**
   * Tải lại thông tin người dùng từ server và cập nhật state.
   * Rất hữu ích sau khi người dùng đã cập nhật thông tin cá nhân của họ.
   */
  Future<bool> fetchAndSetUser() async {
    if (user == null) {
      print("AuthProvider: Không có user để làm mới thông tin.");
      return false;
    }

    final int userId = user!.id;
    // API backend để lấy chi tiết user
    final url = Uri.parse('http://10.0.2.2:8080/api/users/$userId');

    try {
      print("AuthProvider: Đang tải thông tin user mới từ $url");
      // TODO: Thêm header xác thực (token) nếu API yêu cầu
      // final response = await http.get(url, headers: {'Authorization': 'Bearer $_token'});
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));

        // Backend có thể trả về user object trực tiếp hoặc lồng trong một key.
        // Giả sử nó trả về trực tiếp.
        final Map<String, dynamic> newUserData = responseData as Map<String, dynamic>;

        // Tạo một map mới để tái sử dụng hàm processSuccessfulAuth
        // (giả định rằng hàm này không cần token/expiryDate)
        final dataToProcess = {'user': newUserData};

        await processSuccessfulAuth(dataToProcess);
        print("AuthProvider: Thông tin user đã được làm mới thành công.");
        notifyListeners(); // Thông báo cho UI cập nhật với thông tin user mới
        return true;
      } else {
        print("AuthProvider: Lỗi tải thông tin user mới. Status: ${response.statusCode}");
        _errorMessage = "Không thể làm mới thông tin tài khoản.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi làm mới thông tin.";
      print("AuthProvider: Lỗi khi gọi API fetchAndSetUser: $e");
      notifyListeners();
      return false;
    }
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