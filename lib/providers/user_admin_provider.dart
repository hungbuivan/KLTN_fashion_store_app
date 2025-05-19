// file: lib/providers/admin/user_admin_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import model UserAdminModel và PageResponse
import '../../models/admin/user_admin_model.dart';
import '../models/page_response_model.dart'; // Sử dụng lại PageResponse<T>

// Import AuthProvider nếu cần lấy token cho API (hiện tại chưa dùng)
// import '../auth_provider.dart';

class UserAdminProvider with ChangeNotifier {
  List<UserAdminModel> _users = [];
  List<UserAdminModel> get users => _users;

  PageResponse<UserAdminModel>? _pageData;
  PageResponse<UserAdminModel>? get pageData => _pageData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // URL cơ sở cho API admin users (thay đổi IP nếu cần)
  final String _baseUrl = 'http://10.0.2.2:8080/api/admin/users';

  // AuthProvider? _authProvider; // Dùng để lấy token nếu API yêu cầu
  // UserAdminProvider(this._authProvider);

  // Future<Map<String, String>> _getHeaders() async {
  //   final headers = {'Content-Type': 'application/json; charset=UTF-8'};
  //   // final token = _authProvider?.token;
  //   // if (token != null) {
  //   //   headers['Authorization'] = 'Bearer $token';
  //   // }
  //   return headers;
  // }

  // Lấy danh sách người dùng
  Future<void> fetchUsers({
    int page = 0,
    int size = 10,
    String sort = 'id,asc',
    String? searchTerm,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    if (page == 0) { // Chỉ notify loading toàn trang khi tải lần đầu/refresh
      notifyListeners();
    }

    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };
      if (searchTerm != null && searchTerm.isNotEmpty) queryParams['searchTerm'] = searchTerm;

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      print("UserAdminProvider: Đang tải danh sách người dùng từ: $uri");

      // final headers = await _getHeaders();
      // final response = await http.get(uri, headers: headers);
      final response = await http.get(uri); // Hiện tại chưa có auth

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _pageData = PageResponse.fromJson(responseData, UserAdminModel.fromJson);
        if (page == 0) {
          _users = _pageData!.content;
        } else {
          _users.addAll(_pageData!.content);
        }
        _errorMessage = null;
      } else {
        _errorMessage = "Lỗi tải danh sách người dùng: ${response.statusCode} - ${response.body}";
        if (page == 0) _users = [];
        _pageData = null;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý: ${e.toString()}";
      if (page == 0) _users = [];
      _pageData = null;
      print("UserAdminProvider: Lỗi khi tải người dùng: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật vai trò người dùng
  Future<bool> updateUserRole(int userId, String newRole) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success = false;
    try {
      final uri = Uri.parse('$_baseUrl/$userId/role');
      print("UserAdminProvider: Cập nhật vai trò cho user ID $userId thành '$newRole'");
      // final headers = await _getHeaders();
      final response = await http.put(
        uri,
        // headers: headers,
        headers: {'Content-Type': 'application/json; charset=UTF-8'}, // Tạm thời
        body: jsonEncode({'newRole': newRole}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        // Cập nhật lại user trong danh sách _users (hoặc tải lại cả trang)
        int index = _users.indexWhere((user) => user.id == userId);
        if (index != -1) {
          _users[index] = UserAdminModel.fromJson(responseData); // Giả sử API trả về user đã cập nhật
        }
        _errorMessage = null;
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = "Lỗi cập nhật vai trò: ${responseData['message'] ?? response.reasonPhrase}";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi cập nhật vai trò: ${e.toString()}";
      print("UserAdminProvider: Lỗi khi cập nhật vai trò: $e");
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Cập nhật trạng thái active của người dùng
  Future<bool> updateUserStatus(int userId, bool isActive) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success = false;
    try {
      final uri = Uri.parse('$_baseUrl/$userId/status');
      print("UserAdminProvider: Cập nhật trạng thái active cho user ID $userId thành '$isActive'");
      // final headers = await _getHeaders();
      final response = await http.put(
        uri,
        // headers: headers,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'active': isActive}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        int index = _users.indexWhere((user) => user.id == userId);
        if (index != -1) {
          _users[index] = UserAdminModel.fromJson(responseData);
        }
        _errorMessage = null;
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = "Lỗi cập nhật trạng thái: ${responseData['message'] ?? response.reasonPhrase}";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi cập nhật trạng thái: ${e.toString()}";
      print("UserAdminProvider: Lỗi khi cập nhật trạng thái: $e");
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Xóa người dùng (CẨN THẬN - có thể bạn chỉ muốn vô hiệu hóa)
  Future<bool> deleteUser(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success = false;
    try {
      final uri = Uri.parse('$_baseUrl/$userId');
      print("UserAdminProvider: Đang xóa user ID: $uri");
      // final headers = await _getHeaders();
      // final response = await http.delete(uri, headers: headers);
      final response = await http.delete(uri);


      if (response.statusCode == 200 || response.statusCode == 204) {
        _errorMessage = null;
        success = true;
        // Tải lại danh sách người dùng sau khi xóa thành công
        await fetchUsers(
          page: _pageData?.number ?? 0,
          size: _pageData?.size ?? 10,
          sort: _pageData != null && _pageData!.content.isNotEmpty ? (_currentSortFromPageData() ?? 'id,asc') : 'id,asc',
          searchTerm: _pageData != null ? (_currentSearchTermFromPageData()) : null,
        );
      } else {
        try {
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          _errorMessage = "Lỗi xóa người dùng: ${responseData['message'] ?? response.reasonPhrase}";
        } catch(e) {
          _errorMessage = "Lỗi xóa người dùng: ${response.reasonPhrase} (Status: ${response.statusCode})";
        }
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi xóa người dùng: ${e.toString()}";
      print("UserAdminProvider: Lỗi khi xóa người dùng: $e");
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Hàm helper (ví dụ, bạn cần có cách lấy sort và filter hiện tại nếu muốn giữ chúng khi refresh)
  String? _currentSortFromPageData() {
    // Logic để lấy sort string từ _pageData hoặc một biến state khác
    return 'id,asc'; // Placeholder
  }
  String? _currentSearchTermFromPageData() {
    // Logic để lấy searchTerm string từ _pageData hoặc một biến state khác
    return null; // Placeholder
  }
}
