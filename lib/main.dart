// file: lib/main.dart
import 'package:fashion_store_app/providers/address_provider.dart';
import 'package:fashion_store_app/providers/bottom_nav_provider.dart';
import 'package:fashion_store_app/providers/brand_admin_provider.dart';
import 'package:fashion_store_app/providers/cart_provider.dart';
import 'package:fashion_store_app/providers/category_admin_provider.dart';
import 'package:fashion_store_app/providers/category_provider.dart';
import 'package:fashion_store_app/providers/chat_provider.dart';
import 'package:fashion_store_app/providers/dashboard_provider.dart';
import 'package:fashion_store_app/providers/forgot_password_provider.dart';
import 'package:fashion_store_app/providers/notification_provider.dart';
import 'package:fashion_store_app/providers/payment_provider.dart';
import 'package:fashion_store_app/providers/product_admin_provider.dart';
import 'package:fashion_store_app/providers/product_detail_provider.dart';
import 'package:fashion_store_app/providers/product_provider.dart';
import 'package:fashion_store_app/providers/product_review_provider.dart';
import 'package:fashion_store_app/providers/products_by_category_provider.dart';
import 'package:fashion_store_app/providers/signup_provider.dart';
import 'package:fashion_store_app/providers/stats_provider.dart';
import 'package:fashion_store_app/providers/user_admin_provider.dart';
import 'package:fashion_store_app/providers/voucher_admin_provider.dart';
import 'package:fashion_store_app/providers/wishlist_provider.dart';
import 'package:fashion_store_app/screens/account_page.dart';
import 'package:fashion_store_app/screens/add_review_screen.dart';
import 'package:fashion_store_app/screens/admin/admin_home_page.dart';
import 'package:fashion_store_app/screens/cart_page.dart';
import 'package:fashion_store_app/screens/chat_message_screen.dart';
import 'package:fashion_store_app/screens/checkout_screen.dart';
import 'package:fashion_store_app/screens/edit_profile_screen.dart';
import 'package:fashion_store_app/screens/notification_screen.dart';
import 'package:fashion_store_app/screens/onboarding_screen.dart';
import 'package:fashion_store_app/screens/order_history_screen.dart';
import 'package:fashion_store_app/screens/order_success_screen.dart';
import 'package:fashion_store_app/screens/products_by_category_screen.dart';
import 'package:fashion_store_app/screens/test/test.dart';
import 'package:fashion_store_app/screens/test/test2.dart';
import 'package:fashion_store_app/screens/test/test3.dart';
import 'package:fashion_store_app/views/admin/admin_notifications.dart';
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
import 'providers/order_provider.dart'; // ✅ 1. IMPORT ORDERPROVIDER
import 'providers/voucher_provider.dart'; // Đảm bảo VoucherProvider đã được import nếu OrderProvider dùng

// Import các màn hình của bạn
import 'screens/welcome_screen.dart'; // Ví dụ, bạn sẽ cần màn hình này
import 'package:fashion_store_app/screens/order_detail_screen.dart';


final storage = FlutterSecureStorage();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await storage.deleteAll(); // Cẩn thận khi dùng deleteAll() ở đây
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
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => ProductAdminProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (_) => UserAdminProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        ChangeNotifierProvider(create: (_) => VoucherAdminProvider()),
        // ProductDetailProvider được cung cấp 2 lần, bạn có thể bỏ 1 dòng nếu chúng giống hệt nhau
        ChangeNotifierProvider(create: (_) => ProductDetailProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductsByCategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryAdminProvider()),
        ChangeNotifierProvider(create: (_) => BrandAdminProvider()),


        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (context) => WishlistProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previousWishlist) {
            if (previousWishlist == null) return WishlistProvider(auth);
            previousWishlist.updateAuthProvider(auth);
            return previousWishlist;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) => CartProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previousCart) {
            if (previousCart == null) return CartProvider(auth);
            previousCart.updateAuthProvider(auth);
            return previousCart;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, VoucherProvider>( // VoucherProvider cần AuthProvider
            create: (context) => VoucherProvider(Provider.of<AuthProvider>(context, listen: false)),
            update: (context, auth, previousVoucher) {
              if (previousVoucher == null) return VoucherProvider(auth);
              previousVoucher.updateAuthProvider(auth); // Đảm bảo VoucherProvider có hàm này
              return previousVoucher;
            }
        ),

        // ✅ 2. CUNG CẤP ORDERPROVIDER
        // OrderProvider phụ thuộc vào AuthProvider, CartProvider, và VoucherProvider
        ChangeNotifierProxyProvider3<AuthProvider, CartProvider, VoucherProvider, OrderProvider>(
          create: (context) => OrderProvider(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
            cartProvider: Provider.of<CartProvider>(context, listen: false),
            voucherProvider: Provider.of<VoucherProvider>(context, listen: false),
          ),
          update: (context, auth, cart, voucher, previousOrder) {
            if (previousOrder == null) {
              return OrderProvider(authProvider: auth, cartProvider: cart, voucherProvider: voucher);
            }
            previousOrder.updateAuthProvider(auth); // Đảm bảo OrderProvider có hàm này
            // Bạn có thể thêm logic để OrderProvider phản ứng với thay đổi của CartProvider hoặc VoucherProvider nếu cần
            // previousOrder.updateCartProvider(cart); // Ví dụ
            // previousOrder.updateVoucherProvider(voucher); // Ví dụ
            return previousOrder;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (context) => PaymentProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previousPayment) {
            if (previousPayment == null) return PaymentProvider(auth);
            // Gọi hàm updateAuthProvider trong PaymentProvider nếu bạn có logic
            // cần phản ứng với việc đăng nhập/đăng xuất.
            // previousPayment.updateAuthProvider(auth);
            return previousPayment;
          },
        ),

    // ✅ THÊM PROXY PROVIDER MỚI VÀO ĐÂY
    // ProductReviewProvider phụ thuộc vào AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, ProductReviewProvider>(
          create: (context) => ProductReviewProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, authProvider, previous) => ProductReviewProvider(authProvider),
        ),

        // ✅ THÊM PROXY PROVIDER MỚI VÀO ĐÂY
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) {
            previous?.authProvider = auth;
            return previous ?? NotificationProvider(auth);
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) => ChatProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => ChatProvider(auth),
        ),



      ],
      child: MaterialApp(
        title: 'Fashion Store',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade700), // Sử dụng màu seed nhất quán
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        initialRoute: '/onboarding',
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(), // Đảm bảo LoginScreen được import đúng
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const NavigationMenu(),
          '/admin_panel': (context) => const AdminHomePage(),
          '/wishlist': (context) => const WishlistScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/account': (context) => const AccountPage(),

          '/test': (context) => const Test(),
          '/test2': (context) => const Test2(),
          '/test3': (context) => const Test3(),
          //CheckoutScreen.routeName: (context) => const CheckoutScreen(), // Ví dụ nếu CheckoutScreen có routeName
          // '/cart': (context) => const CartPage(), // Nếu bạn đã có CartPage
          OrderHistoryScreen.routeName: (context) => const OrderHistoryScreen(), // Đăng ký route tĩnh
          EditProfileScreen.routeName: (context) => const EditProfileScreen(),
          NotificationScreen.routeName: (context) => const NotificationScreen(),
          AdminNotificationsScreen.routeName: (context) => const AdminNotificationsScreen(),


        },
        onGenerateRoute: (settings) {
          print("Navigate to: ${settings.name}");

          if (settings.name == '/product-detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('productId')) {
              final productId = args['productId'];
              if (productId is int) {
                return MaterialPageRoute(
                  builder: (context) {
                    return ProductDetailScreen(productId: productId);
                  },
                );
              }
            }
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Lỗi: Product ID không hợp lệ'))));
          }
          // Thêm onGenerateRoute cho CartPage nếu nó nhận arguments hoặc để nhất quán
          if (settings.name == '/cart') {
            return MaterialPageRoute(builder: (context) => const CartPage());
          }
          // TODO: Xử lý onGenerateRoute cho OrderHistoryScreen, OrderDetailScreen (nếu chúng nhận arguments)
          // ✅ THÊM LOGIC CHO /order-detail
          if (settings.name == '/order-detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('orderId')) {
              final orderId = args['orderId'];
              if (orderId is int) {
                return MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(orderId: orderId),
                  settings: settings, // ✅ Truyền settings để giữ lại tên route
                );
              }
            }
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Lỗi: Order ID không hợp lệ'))));
          }

          if (settings.name == '/order-success') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('orderId')) {
              final orderId = args['orderId'];
              if (orderId is int) {
                return MaterialPageRoute(
                  builder: (context) => OrderSuccessScreen(orderId: orderId),
                  settings: settings, // ✅ Truyền settings để giữ lại tên route
                );
              }
            }
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Lỗi: Order ID không hợp lệ'))));
          }


          // ✅ THÊM LOGIC NÀY
          if (settings.name == AddReviewScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null &&
                args.containsKey('orderId') &&
                args.containsKey('productToReview')) {

              return MaterialPageRoute(
                builder: (context) => AddReviewScreen(
                  orderId: args['orderId'],
                  productToReview: args['productToReview'],
                ),
              );
            }
          }
          if (settings.name == ChatMessageScreen.routeName) {
            if (settings.arguments != null && settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => ChatMessageScreen(
                  roomId: args['roomId'],
                  userName: args['userName'],

                ),
              );
            } else {
              // Nếu không có arguments thì có thể trả về một trang lỗi hoặc thông báo
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text("Lỗi: Thiếu dữ liệu phòng chat")),
                ),
              );
            }
          }


          // Thêm logic để xử lý route cho ProductsByCategoryScreen
          if (settings.name == ProductsByCategoryScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>?;

            // Kiểm tra xem arguments có được truyền đúng không
            if (args != null && args.containsKey('categoryId') && args.containsKey('categoryName')) {
              final categoryId = args['categoryId'] as int;
              final categoryName = args['categoryName'] as String;

              return MaterialPageRoute(
                builder: (context) {
                  // Tạo màn hình với các tham số đã nhận
                  return ProductsByCategoryScreen(
                    categoryId: categoryId,
                    categoryName: categoryName,
                  );
                },
                settings: settings, // Giữ lại tên route và các thông tin khác
              );
            }
            // Trả về trang lỗi nếu không có arguments
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Lỗi: Thiếu thông tin danh mục'))));
          }

          return MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text("Lỗi")),body: Center(child: Text('Lỗi 404: Trang không tồn tại - ${settings.name}'))));
        },



      ),
    );
  }
}