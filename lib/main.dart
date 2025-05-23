// file: main.dart
import 'package:fashion_store_app/providers/bottom_nav_provider.dart';
import 'package:fashion_store_app/providers/cart_provider.dart';
import 'package:fashion_store_app/providers/dashboard_provider.dart';
import 'package:fashion_store_app/providers/forgot_password_provider.dart';
import 'package:fashion_store_app/providers/product_admin_provider.dart';
import 'package:fashion_store_app/providers/product_detail_provider.dart';
import 'package:fashion_store_app/providers/signup_provider.dart';
import 'package:fashion_store_app/providers/stats_provider.dart';
import 'package:fashion_store_app/providers/user_admin_provider.dart';
import 'package:fashion_store_app/providers/wishlist_provider.dart';
import 'package:fashion_store_app/screens/admin/admin_home_page.dart';
import 'package:fashion_store_app/screens/onboarding_screen.dart';
import 'package:fashion_store_app/views/auth/login_screen.dart';
import 'package:fashion_store_app/views/auth/signup_screen.dart';
import 'package:fashion_store_app/views/home/product_details_screen.dart';
import 'package:fashion_store_app/widgets/navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:fashion_store_app/screens/wishlist_screen.dart';
// Import các provider của bạn
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';

// Import các màn hình của bạn

import 'screens/welcome_screen.dart'; // ✅ Màn hình Welcome (từ image_c13881.png)
// ✅ Màn hình nhập liệu Login (tên mới)
// import 'screens/signup_screen.dart'; // Nếu có

// Không cần biến global _hasSeenOnboardingGlobal nữa
// bool _hasSeenOnboardingGlobal = false;
final storage = FlutterSecureStorage();
// Hàm main không cần async nếu không đọcFuture<void>redPrefeasync rences ở đây
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Vẫn cần thiết
  // Không đọc SharedPreferences ở đây nữa

  await storage.deleteAll();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => ProductAdminProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (_) => UserAdminProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),


        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          // Hàm create tạo một instance ban đầu của WishlistProvider.
          // Nó nhận AuthProvider (lấy bằng Provider.of với listen: false vì đây là lúc tạo).
          create: (context) => WishlistProvider(Provider.of<AuthProvider>(context, listen: false)),

          // Hàm update được gọi mỗi khi AuthProvider (dependency) thay đổi.
          // Nó nhận AuthProvider mới (auth) và WishlistProvider cũ (previousWishlist).
          update: (context, auth, previousWishlist) {
            // Nếu previousWishlist là null (lần đầu tạo proxy), tạo mới.
            if (previousWishlist == null) return WishlistProvider(auth);

            // Kiểm tra xem trạng thái đăng nhập trong AuthProvider có thay đổi không.
            // Ví dụ: nếu người dùng vừa đăng nhập hoặc đăng xuất.
            if (auth.isAuthenticated && (previousWishlist.authProvider.user?.id != auth.user?.id || !previousWishlist.authProvider.isAuthenticated) ) {
              // Người dùng vừa đăng nhập hoặc user thay đổi
              print("Main.dart: Auth state changed to authenticated or user changed. Fetching wishlist.");
              previousWishlist.fetchWishlist(); // Tải lại wishlist cho user mới
            } else if (!auth.isAuthenticated && previousWishlist.authProvider.isAuthenticated) {
              // Người dùng vừa đăng xuất
              print("Main.dart: Auth state changed to unauthenticated. Clearing wishlist.");
              previousWishlist.clearWishlistOnLogout(); // Xóa dữ liệu wishlist ở client
            }
            // Trả về instance WishlistProvider (có thể là cũ hoặc mới nếu bạn muốn tạo lại)
            // Ở đây, chúng ta cập nhật trên instance cũ.
            return previousWishlist;
          },


        ),
        ChangeNotifierProvider(create: (_) => ProductDetailProvider()),
        // ✅ THÊM CARTPROVIDER VÀO ĐÂY
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) => CartProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previousCart) {
            if (previousCart == null) return CartProvider(auth);
            // Xử lý thay đổi trạng thái đăng nhập
            // (Bạn có thể cần một hàm updateAuthProvider trong CartProvider tương tự như WishlistProvider)
            previousCart.updateAuthProvider(auth); // Giả sử có hàm này
            return previousCart;
          },
        ),



        // Thêm các provider khác nếu cần, ví dụ SignupProvider
        // ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => ProductDetailProvider()),
      ],
      child: MaterialApp(
        title: 'Fashion Store',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Poppins',

        ),
        // ✅ Luôn bắt đầu với màn hình onboarding
        // Thay đổi:
        initialRoute: '/onboarding', // <- Đây là màn hình quyết định đầu tiên

        routes: {

          '/onboarding': (context) => const OnboardingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const NavigationMenu(),
          '/admin_panel': (context) => const AdminHomePage(),
          '/wishlist': (context) => const WishlistScreen(),
        },


        // ✅ Sử dụng onGenerateRoute để xử lý các route có tham số động
        // như ProductDetailScreen
        onGenerateRoute: (settings) {
          print("Navigate to: ${settings.name}"); // Log để debug route

          // Xử lý route cho ProductDetailScreen
          if (settings.name == '/product-detail') {
            // Lấy arguments được truyền vào (dưới dạng Map)
            final args = settings.arguments as Map<String, dynamic>?;

            if (args != null && args.containsKey('productId')) {
              final productId = args['productId'];
              // Kiểm tra kiểu dữ liệu của productId
              if (productId is int) {
                return MaterialPageRoute(
                  builder: (context) {
                    // Khởi tạo ProductDetailScreen với productId
                    return ProductDetailScreen(productId: productId);
                  },
                );
              } else {
                print("Lỗi: productId không phải là kiểu int. Giá trị nhận được: $productId");
                // Trả về trang lỗi nếu productId không đúng kiểu
                return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Lỗi: Product ID không hợp lệ (kiểu dữ liệu sai).'))));
              }
            }
            // Trả về một trang lỗi nếu productId không được cung cấp
            print("Lỗi: Product ID không được cung cấp cho route /product-detail.");
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Lỗi: Product ID không được cung cấp.'))));
          }

          // Xử lý các route động khác nếu có
          // ...

          // Nếu không có route nào khớp, có thể trả về null để fallback về onUnknownRoute
          // hoặc trả về một trang lỗi mặc định
          print("Route không được định nghĩa: ${settings.name}");
          return MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text('Lỗi 404: Trang không tồn tại - ${settings.name}'))));
        },
      ),
    );
  }
}
