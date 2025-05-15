// file: lib/screens/onboarding/widgets/onboarding_page_content.dart
import 'package:flutter/material.dart';
import '../../../models/onboarding_content_model.dart'; // Import model

class OnboardingPageContent extends StatelessWidget {
  final OnboardingContentModel content;

  const OnboardingPageContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Canh giữa nội dung theo chiều dọc
        crossAxisAlignment: CrossAxisAlignment.center, // Canh giữa nội dung theo chiều ngang
        children: <Widget>[
          // Hình ảnh
          Image.asset(
            content.imagePath,
            height: screenSize.height * 0.4, // Chiều cao ảnh khoảng 40% màn hình
            fit: BoxFit.contain, // Đảm bảo ảnh hiển thị trọn vẹn
          ),
          SizedBox(height: screenSize.height * 0.05), // Khoảng cách động

          // Tiêu đề
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Màu chữ cho tiêu đề
            ),
          ),
          SizedBox(height: screenSize.height * 0.02), // Khoảng cách động

          // Mô tả
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700], // Màu chữ cho mô tả
              height: 1.5, // Giãn dòng
            ),
          ),
        ],
      ),
    );
  }
}
