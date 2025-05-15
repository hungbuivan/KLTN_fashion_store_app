// file: lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Import package
import '../../providers/onboarding_provider.dart';        // Import Provider
import '../../models/onboarding_content_model.dart';    // Import Model và danh sách content
// ✅ Sửa đường dẫn import cho OnboardingPageContent
import '../widgets/onboarding_page_content.dart';
     // Giả sử OnboardingPageContent nằm trong thư mục con 'widgets'

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy instance của OnboardingProvider
    // context.watch sẽ làm widget này rebuild khi provider thay đổi
    final onboardingProvider = context.watch<OnboardingProvider>();
    // context.read chỉ để gọi hàm, không rebuild
    final onboardingProviderActions = context.read<OnboardingProvider>();

    return Scaffold(
      backgroundColor: Colors.white, // Màu nền cho màn hình onboarding
      body: SafeArea( // Đảm bảo nội dung không bị che
        child: Stack( // Sử dụng Stack để đặt các nút và indicator lên trên PageView
          children: [
            // PageView để hiển thị các trang onboarding
            PageView.builder(
              controller: onboardingProvider.pageController, // Sử dụng controller từ provider
              onPageChanged: onboardingProvider.onPageChanged, // Gọi hàm khi trang thay đổi
              itemCount: onboardingPagesContent.length, // Số lượng trang
              itemBuilder: (context, index) {
                // Đảm bảo OnboardingPageContent được import đúng và sử dụng
                return OnboardingPageContent(content: onboardingPagesContent[index]);
              },
            ),

            // Các nút điều khiển và chỉ báo trang
            Positioned(
              bottom: 40.0, // Vị trí từ dưới lên
              left: 20.0,
              right: 20.0,
              child: Column(
                children: [
                  // Chỉ báo trang (Dots Indicator)
                  SmoothPageIndicator(
                    controller: onboardingProvider.pageController, // Controller của PageView
                    count: onboardingPagesContent.length,        // Số lượng trang
                    effect: WormEffect( // Hiệu ứng cho dấu chấm (có nhiều loại khác)
                      dotHeight: 10.0,
                      dotWidth: 10.0,
                      activeDotColor: Theme.of(context).colorScheme.primary, // Màu dấu chấm hiện tại
                      dotColor: Colors.blue.shade300,                     // Màu dấu chấm không hiện tại
                    ),
                    onDotClicked: (index) { // Cho phép nhấn vào dấu chấm để chuyển trang
                      onboardingProvider.pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                  ),
                  const SizedBox(height: 30.0), // Khoảng cách

                  // Nút "Get Started" hoặc "Next"
                  SizedBox(
                    width: double.infinity, // Nút chiếm hết chiều rộng
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (onboardingProvider.isLastPage) {
                          // ✅ Nếu là trang cuối, gọi hàm mới để điều hướng đến WelcomeScreen
                          onboardingProviderActions.completeOnboardingAndGoToWelcome(context);
                        } else {
                          // Nếu không phải trang cuối, chuyển đến trang tiếp theo
                          onboardingProviderActions.nextPage();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Màu nút
                        foregroundColor: Colors.white, // Màu chữ trên nút
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0), // Bo góc nút
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Thay đổi text của nút tùy theo trang hiện tại
                      child: Text(onboardingProvider.isLastPage ? "Get Started" : "Next"),
                    ),
                  ),
                  const SizedBox(height: 15.0),

                  // Nút "Skip" (Bỏ qua) - chỉ hiển thị khi không phải trang cuối
                  if (!onboardingProvider.isLastPage)
                    TextButton(
                      onPressed: () {
                        // ✅ Gọi hàm mới để điều hướng đến WelcomeScreen
                        onboardingProviderActions.completeOnboardingAndGoToWelcome(context);
                      },
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 16,
                        ),
                      ),
                    )
                  else // Thêm khoảng trống để giữ vị trí nếu nút Skip ẩn đi
                    const SizedBox(height: 48), // Chiều cao tương đương TextButton + padding (nếu TextButton có padding mặc định)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
