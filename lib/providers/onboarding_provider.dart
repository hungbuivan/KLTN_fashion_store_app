// file: lib/providers/onboarding_provider.dart
import 'package:flutter/material.dart';
// Bỏ import 'package:shared_preferences/shared_preferences.dart;' nếu không dùng nữa

class OnboardingProvider with ChangeNotifier {
  final PageController pageController = PageController();
  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  // Giả sử onboardingPagesContent được định nghĩa ở đâu đó (ví dụ: trong model)
  // final int totalOnboardingPages = onboardingPagesContent.length;
  // Để đơn giản, bạn có thể hardcode số lượng trang hoặc lấy từ danh sách content
  bool get isLastPage => _currentPageIndex == (3 - 1); // Giả sử có 3 trang onboarding

  void onPageChanged(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void nextPage() {
    if (!isLastPage) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  // Hàm xử lý khi người dùng nhấn "Get Started" hoặc "Skip"
  // Sẽ điều hướng đến WelcomeScreen
  Future<void> completeOnboardingAndGoToWelcome(BuildContext context) async {
    // Không cần lưu SharedPreferences nữa nếu muốn onboarding luôn hiển thị
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('hasSeenOnboarding', true);

    print('OnboardingProvider: Hoàn thành onboarding, điều hướng đến /welcome');
    if (context.mounted) {
      // Điều hướng đến WelcomeScreen và thay thế màn hình onboarding hiện tại
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
