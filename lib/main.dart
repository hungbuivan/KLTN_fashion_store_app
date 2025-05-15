// file: main.dart
import 'package:fashion_store_app/providers/signup_provider.dart';
import 'package:fashion_store_app/screens/onboarding_screen.dart';
import 'package:fashion_store_app/views/auth/decision_screen.dart';
import 'package:fashion_store_app/views/auth/login_screen.dart';
import 'package:fashion_store_app/views/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các provider của bạn
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';

// Import các màn hình của bạn

import 'screens/welcome_screen.dart'; // ✅ Màn hình Welcome (từ image_c13881.png)
// ✅ Màn hình nhập liệu Login (tên mới)
import 'screens/home_page.dart';
import 'screens/admin_panel_screen.dart';
// import 'screens/signup_screen.dart'; // Nếu có

// Không cần biến global _hasSeenOnboardingGlobal nữa
// bool _hasSeenOnboardingGlobal = false;

// Hàm main không cần async nếu không đọc SharedPreferences ở đây
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Vẫn cần thiết
  // Không đọc SharedPreferences ở đây nữa
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
        // Thêm các provider khác nếu cần, ví dụ SignupProvider
        // ChangeNotifierProvider(create: (_) => SignupProvider()),
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
        initialRoute: '/', // <- Đây là màn hình quyết định đầu tiên

        routes: {
          '/': (context) => const DecisionScreen(), // <- Màn hình trung gian điều hướng
          '/onboarding': (context) => const OnboardingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomePage(),
          '/admin_panel': (context) => const AdminPanelScreen(),
        },
      ),
    );
  }
}
