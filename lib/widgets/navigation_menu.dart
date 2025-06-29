// file: lib/widgets/navigation_menu.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các provider cần thiết
import '../providers/cart_provider.dart';
import '../providers/notification_provider.dart';

// Import các màn hình và widget con
import '../screens/home_page.dart';
import '../screens/category_page.dart';
import '../screens/cart_page.dart';
import '../screens/wishlist_screen.dart';
import '../screens/account_page.dart';
import 'app_bottom_nav_bar.dart';

class NavigationMenu extends StatefulWidget {
  final int selectedIndex;

  const NavigationMenu({super.key, this.selectedIndex = 0});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

// ✅ THÊM `with WidgetsBindingObserver` ĐỂ LẮNG NGHE VÒNG ĐỜI APP
class _NavigationMenuState extends State<NavigationMenu> with WidgetsBindingObserver {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;

    // ✅ Đăng ký observer
    WidgetsBinding.instance.addObserver(this);

    // Tải dữ liệu lần đầu tiên khi widget được xây dựng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    // ✅ Gỡ bỏ observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ HÀM NÀY SẼ ĐƯỢC GỌI KHI APP RESUME
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("App resumed. Refreshing user data...");
      _refreshData();
    }
  }

  // ✅ TẠO MỘT HÀM RIÊNG ĐỂ LÀM MỚI DỮ LIỆU
  Future<void> _refreshData() async {
    // Sử dụng context.read vì chúng ta chỉ trigger hành động
    final cartProvider = context.read<CartProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    print("Refreshing cart and notifications...");

    // Gọi API để lấy dữ liệu mới nhất cho cả hai
    // Dùng Future.wait để chúng có thể chạy song song
    await Future.wait([
      cartProvider.fetchCart(),
      notificationProvider.fetchNotifications(),
    ]);
  }

  // ✅ HÀM NÀY SẼ ĐƯỢC GỌI KHI NGƯỜI DÙNG NHẤN VÀO MỘT TAB
  void _onItemTapped(int index) {
    // Cập nhật UI để hiển thị màn hình mới
    setState(() {
      _currentIndex = index;
    });

    // Sau khi chuyển tab, gọi hàm để làm mới dữ liệu
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng IndexedStack để giữ trạng thái của các trang khi chuyển tab
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      // Sử dụng widget AppBottomNavBar của bạn và truyền hàm _onItemTapped vào
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped, // ✅ GỌI HÀM ĐÃ SỬA
      ),
    );
  }

  List<Widget> _buildScreens() {
    return const [
      HomePage(),
      CategoryPage(),
      CartPage(),
      WishlistScreen(),
      AccountPage(),
    ];
  }
}
