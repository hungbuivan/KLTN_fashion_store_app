// lib/screens/admin/admin_home_page.dart
import 'package:fashion_store_app/screens/admin/pages/order_management_page.dart';
import 'package:fashion_store_app/screens/admin/pages/voucher_management_page.dart';
import 'package:flutter/material.dart';
import 'package:fashion_store_app/views/admin/admin_dashboard.dart';
import 'package:fashion_store_app/views/admin/admin_notifications.dart';
import 'package:fashion_store_app/views/admin/admin_profile.dart';
import 'package:fashion_store_app/views/admin/product_management_page.dart'; // Đã có
// ✅ Import UserManagementPage (điều chỉnh đường dẫn nếu cần)
import 'package:iconsax/iconsax.dart';
// ✅ Import AuthProvider nếu bạn cần cho chức năng đăng xuất trong Drawer
import 'package:provider/provider.dart';
import 'package:fashion_store_app/providers/auth_provider.dart';

import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../views/admin/chat_list_screen.dart';
import '../../views/admin/user_management_page.dart';
import 'package:fashion_store_app/views/admin/revenue_page.dart';



class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}
// ✅ THÊM `with WidgetsBindingObserver` ĐỂ GIỮ LẠI LOGIC CŨ
class _AdminHomePageState extends State<AdminHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<String> _pageTitles = const [
    'Trang chủ Admin',
    'Thông báo',
    'Tin nhắn',
    'Hồ sơ Admin',
  ];

  // ✅ SỬA LẠI DANH SÁCH PAGES ĐỂ TRUYỀN HÀM REFRESH
  // Chúng ta sẽ khởi tạo nó trong initState
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pages = [
      AdminDashboard(),
      AdminNotificationsScreen(onRefresh: _refreshData),
      ChatListScreen(onRefresh: _refreshData), // ✅ Thay thế AdminMessages
      const AdminProfile(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ HÀM NÀY GIỮ NGUYÊN, DÙNG KHI APP ĐƯỢC RESUME
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("App resumed. Refreshing admin data...");
      _refreshData();
    }
  }

  // ✅ HÀM NÀY SẼ LÀM MỚI TẤT CẢ DỮ LIỆU CẦN THIẾT
  Future<void> _refreshData() async {
    await Future.wait([
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(),
      Provider.of<ChatProvider>(context, listen: false).fetchChatRoomsForAdmin(),
    ]);
  }

  // ✅ CẬP NHẬT HÀM NÀY ĐỂ TỰ ĐỘNG LÀM MỚI
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Mỗi khi người dùng nhấn vào một tab, gọi hàm làm mới thông báo
    // để huy hiệu (badge) luôn được cập nhật.
    _refreshData();
  }

  // Hàm điều hướng đến trang Quản lý Sản phẩm
  void _navigateToProductManagement(BuildContext context) {
    if (Navigator.canPop(context)) { // Kiểm tra xem Drawer có đang mở không
      Navigator.of(context).pop(); // Đóng Drawer trước khi điều hướng
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ProductManagementPage(),
    ));
  }

  // ✅ Hàm điều hướng đến trang Quản lý Người dùng
  void _navigateToUserManagement(BuildContext context) {
    if (Navigator.canPop(context)) { // Kiểm tra xem Drawer có đang mở không
      Navigator.of(context).pop(); // Đóng Drawer trước khi điều hướng
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const UserManagementPage(), // Điều hướng đến UserManagementPage
    ));
  }
//Hàm điều hướng quản lý doanh thu
  void _navigateToRevenueManagement(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Đóng drawer
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const RevenuePage(), // Trang doanh thu
    ));
  }

  //quản lý voucher
  void _navigateToVoucherManagement(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Đóng drawer
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AdminVoucherManagementPage(), // Trang doanh thu
    ));
  }

  //quản lý order
  void _navigateToOrderManagement(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Đóng drawer
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AdminOrderManagementPage(), // Trang doanh thu
    ));
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>(); // Để dùng cho logout

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Colors.blue, // Bạn có thể dùng Theme.of(context).colorScheme.primary
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue, // Đồng bộ màu
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
              leading: Icon(Iconsax.box),
              title: const Text('Quản lý Sản phẩm'),
              onTap: () {
                _navigateToProductManagement(context);
              },
            ),
            // ✅ Thêm mục Quản lý Người dùng
            ListTile(
              leading: Icon(Iconsax.profile_2user), // Icon cho quản lý người dùng
              title: const Text('Quản lý Người dùng'),
              onTap: () {
                _navigateToUserManagement(context);
              },
            ),
            ListTile(
              leading: Icon(Iconsax.receipt_item),
              title: const Text('Quản lý Đơn hàng'),
              onTap: () {
                _navigateToOrderManagement(context);
              },
            ),
            ListTile(
              leading: Icon(Iconsax.ticket_discount), // hoặc Icons.bar_chart
              title: const Text('Quản lý Mã giảm giá'),
              onTap: () {
                _navigateToVoucherManagement(context);
              },
            ),
            ListTile(
              leading: Icon(Iconsax.graph), // hoặc Icons.bar_chart
              title: const Text('Quản lý Doanh thu'),
              onTap: () {
                _navigateToRevenueManagement(context);
              },
            ),

            // Thêm các mục khác cho Drawer nếu cần
            const Divider(),
            ListTile(
              leading: Icon(Iconsax.logout_1), // Sử dụng Icon logout từ Iconsax
              title: Text('Đăng xuất'),
              onTap: () async {
                // TODO: Xử lý đăng xuất
                Navigator.of(context).pop(); // Đóng Drawer
                await authProvider.logout(); // Gọi hàm logout từ AuthProvider
                if (mounted) { // Kiểm tra context còn mounted không
                  // Điều hướng về màn hình đăng nhập và xóa hết stack cũ
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
            ),
          ],
        ),
      ),
      body: IndexedStack( // ✅ Sử dụng IndexedStack để giữ state của các tab bottom nav
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        elevation: 0,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        //indicatorColor: Colors.transparent, // ❌ Ẩn nền xanh nhạt khi chọn
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(icon: Icon(Iconsax.home), label: 'Trang chủ'),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return NavigationDestination(
                icon: Badge(
                  isLabelVisible: notificationProvider.unreadCount > 0,
                  label: Text(notificationProvider.unreadCount.toString()),
                  child: const Icon(Iconsax.notification_bing),
                ),
                label: 'Thông báo',
              );
            },
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              return NavigationDestination(
                icon: Badge(
                  isLabelVisible: provider.totalUnreadRoomsCount > 0,
                  label: Text(provider.totalUnreadRoomsCount.toString()),
                  child: const Icon(Iconsax.message_text_1),
                ),
                label: 'Tin nhắn',
              );
            },
          ),
          const NavigationDestination(icon: Icon(Iconsax.user), label: 'Tài khoản'),
        ],
      ),

    );
  }
}