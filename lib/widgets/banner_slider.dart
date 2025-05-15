import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/api_banner.dart'; // Import ApiService để gọi API

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  List<String> _banners = [];
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchBanners(); // Fetch ảnh
    _startAutoSlide(); // Slide tự động
  }

  Future<void> _fetchBanners() async {
    try {
      final banners = await BannerService.fetchBannerImages();
      setState(() {
        _banners = banners;
      });
    } catch (e) {
      // Handle error nếu cần
      print('Error fetching banners: $e');
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_banners.isEmpty) return;
      _currentIndex = (_currentIndex + 1) % _banners.length;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          return Image.network(
            _banners[index],
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
