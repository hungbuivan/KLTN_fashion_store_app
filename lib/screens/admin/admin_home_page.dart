// lib/screens/admin/admin_home_page.dart
import 'package:flutter/material.dart';
import 'package:fashion_store_app/views/admin/admin_dashboard.dart';
import 'package:fashion_store_app/views/admin/admin_notifications.dart';
import 'package:fashion_store_app/views/admin/admin_messages.dart';
import 'package:fashion_store_app/views/admin/admin_profile.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboard(),        // Hiển thị chart thống kê
    AdminNotifications(),    // Thông báo mua hàng
    AdminMessages(),         // Nhắn tin với user
    AdminProfile(),          // Thông tin admin
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tôi'),
        ],
      ),
    );
  }
}
