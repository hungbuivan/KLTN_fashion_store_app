// file: lib/models/onboarding_content_model.dart

class OnboardingContentModel {
  final String imagePath;    // Đường dẫn đến ảnh trong assets
  final String title;        // Tiêu đề của trang onboarding
  final String description;  // Mô tả chi tiết của trang

  OnboardingContentModel({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

// Danh sách nội dung cho các trang onboarding
// Bạn có thể đặt danh sách này ở đây hoặc trong OnboardingProvider/OnboardingScreen
final List<OnboardingContentModel> onboardingPagesContent = [
  OnboardingContentModel(
    imagePath: 'assets/images/onboarding/onboarding_1.png', // Thay bằng tên file ảnh thực tế của bạn
    title: "Chào mừng đến với Fashion Store!",
    description: "",
  ),
  OnboardingContentModel(
    imagePath: 'assets/images/onboarding/onboarding_2.png', // Thay bằng tên file ảnh thực tế của bạn
    title: "Tìm Kiếm Phong Cách Của Bạn",
    description: "",
  ),
  OnboardingContentModel(
    imagePath: 'assets/images/onboarding/onboarding_3.png', // Thay bằng tên file ảnh thực tế của bạn
    title: "Mua Sắm Nhanh Chóng & An Toàn",
    description: "",
  ),
];
