// file: lib/providers/bottom_nav_provider.dart
import 'package:flutter/material.dart';

class BottomNavProvider with ChangeNotifier {
  int _selectedIndex = 0; // Mặc định tab đầu tiên (Trang chủ) được chọn

  int get selectedIndex => _selectedIndex;

  void changeTab(int index) {
    if (_selectedIndex == index) return; // Không làm gì nếu đã ở tab đó rồi
    _selectedIndex = index;
    notifyListeners(); // Thông báo cho các widget đang lắng nghe để cập nhật UI
  }
}
