// file: lib/providers/notification_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/notification_model.dart';
import '../models/page_response_model.dart';
import 'auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  AuthProvider authProvider;
  final String _baseUrl = 'http://10.0.2.2:8080/api/notifications';

  NotificationProvider(this.authProvider);

  // State
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ✅ HÀM NÀY ĐÃ ĐƯỢC CẬP NHẬT
  /// Tải danh sách thông báo.
  /// Tự động gọi API cho user hoặc admin dựa trên vai trò.
  Future<void> fetchNotifications() async {
    // Không làm gì nếu là khách hoặc chưa xác thực
    if (authProvider.isGuest || authProvider.user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String apiUrl;
    // Kiểm tra vai trò để xác định đúng API endpoint
    if (authProvider.isAdmin) {
      apiUrl = '$_baseUrl/admin';
      print("NotificationProvider: Fetching for ADMIN from $apiUrl");
    } else {
      apiUrl = '$_baseUrl/user/${authProvider.user!.id}';
      print("NotificationProvider: Fetching for USER from $apiUrl");
    }

    try {
      // TODO: Thêm header Authorization nếu API yêu cầu
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final pageData = PageResponse.fromJson(responseData, (json) => NotificationModel.fromJson(json));
        _notifications = pageData.content;

        _updateUnreadCount();
      } else {
        _errorMessage = 'Lỗi tải thông báo: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    final notificationIndex = _notifications.indexWhere((n) => n.id == notificationId);
    if (notificationIndex != -1 && !_notifications[notificationIndex].isRead) {
      _notifications[notificationIndex] = NotificationModel(
        id: _notifications[notificationIndex].id,
        orderId: _notifications[notificationIndex].orderId,
        title: _notifications[notificationIndex].title,
        message: _notifications[notificationIndex].message,
        isRead: true, // Đánh dấu là đã đọc ở client ngay lập tức
        createdAt: _notifications[notificationIndex].createdAt,
      );
      _updateUnreadCount();
      notifyListeners();

      try {
        await http.post(Uri.parse('$_baseUrl/$notificationId/read'));
      } catch (e) {
        print("Lỗi khi đánh dấu đã đọc: $e");
      }
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // Hàm để xóa dữ liệu khi người dùng đăng xuất
  void clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
