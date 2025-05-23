// lib/screens/admin/admin_home_page.dart
import 'package:fashion_store_app/screens/admin/pages/add_edit_product_screen.dart';
import 'package:fashion_store_app/views/admin/product_management_page.dart';
import 'package:flutter/material.dart';
import 'package:fashion_store_app/views/admin/admin_dashboard.dart';
import 'package:fashion_store_app/views/admin/admin_notifications.dart';
import 'package:fashion_store_app/views/admin/admin_messages.dart';
import 'package:fashion_store_app/views/admin/admin_profile.dart';
// Giả sử bạn tạo ProductListScreen ở đây, điều chỉnh đường dẫn nếu cần
import 'package:fashion_store_app/widgets/all_product.dart';// << THÊM IMPORT NÀY
import 'package:iconsax/iconsax.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  // Danh sách các tiêu đề tương ứng với mỗi trang trong BottomNavigationBar
  final List<String> _pageTitles = const [
    'Trang chủ Admin',
    'Thông báo',
    'Tin nhắn',
    'Hồ sơ Admin',
  ];

  final List<Widget> _pages = const [
    AdminDashboard(), // Hiển thị chart thống kê
    AdminNotifications(), // Thông báo mua hàng
    AdminMessages(), // Nhắn tin với user
    AdminProfile(), // Thông tin admin
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProductManagement(BuildContext context) {
    Navigator.of(context).pop(); // Đóng Drawer trước khi điều hướng
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ProductManagementPage(), // Điều hướng đến ProductListScreen
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // THÊM AppBar VÀO ĐÂY
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]), // Tiêu đề thay đổi theo tab
        backgroundColor: Colors.blue, // Đồng bộ màu với selectedItemColor
        foregroundColor: Colors.white, // Màu chữ và icon trên AppBar
      ),
      // THÊM Drawer VÀO ĐÂY
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero, // Xóa padding mặc định của ListView
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu Quản trị',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Iconsax.box), // Icon cho quản lý sản phẩm
              title: const Text('Quản lý Sản phẩm'),
              onTap: () {
                _navigateToProductManagement(context);
              },
            ),
            ListTile(
              leading: Icon(Iconsax.receipt_item), // Ví dụ: Icon cho quản lý đơn hàng
              title: const Text('Quản lý Đơn hàng'),
              onTap: () {
                // TODO: Điều hướng đến trang quản lý đơn hàng
                Navigator.of(context).pop(); // Đóng Drawer
                // Navigator.of(context).push(...);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chức năng đang phát triển!')));
              },
            ),
            // Thêm các mục khác cho Drawer nếu cần
            const Divider(),
            ListTile(
              leading: Icon(Iconsax.logout),
              title: Text('Đăng xuất'),
              onTap: () {
                // TODO: Xử lý đăng xuất
                Navigator.of(context).pop(); // Đóng Drawer
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xử lý đăng xuất!')));
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Iconsax.chart), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Iconsax.notification), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Iconsax.message), label: 'Tin nhắn'),
          BottomNavigationBarItem(
              icon: Icon(Iconsax.profile_circle), label: 'Tôi'),
        ],
      ),
    );
  }
}