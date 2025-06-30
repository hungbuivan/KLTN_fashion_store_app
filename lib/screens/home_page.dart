// file: lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các provider cần thiết
import '../providers/notification_provider.dart';
import '../providers/product_provider.dart';
// import '../providers/banner_provider.dart'; // Ví dụ nếu bạn có provider cho banner

// Import các widget con
import '../views/home/app_header.dart';
import '../views/home/search_area.dart';
import '../widgets/banner_slider.dart';
import '../widgets/categories_part.dart';
import '../widgets///all_product.dart';
import '../widgets/popular_selection.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin<HomePage> {
  @override
  bool get wantKeepAlive => true; // 👈 BẮT BUỘC khi dùng AutomaticKeepAliveClientMixin

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInitialData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final notificationProvider = context.read<NotificationProvider>();
    final productProvider = context.read<ProductProvider>();

    await Future.wait([
      notificationProvider.fetchNotifications(),
      productProvider.fetchPopularProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Vì dùng AutomaticKeepAliveClientMixin

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitialData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppHeader(),
                SearchArea(),
                CategoriesPart(),
                SizedBox(height: 10),
                BannerSlider(),
                SizedBox(height: 20),
                PopularSection(),
                AllProducts(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

