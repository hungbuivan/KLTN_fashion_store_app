// file: lib/screens/order_success_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/bottom_nav_provider.dart';
import 'order_detail_screen.dart';
// import 'order_detail_screen.dart'; // Để điều hướng đến chi tiết đơn hàng
// import 'order_history_screen.dart'; // Để điều hướng đến lịch sử đơn hàng

class OrderSuccessScreen extends StatelessWidget {
  final int orderId; // Nhận orderId của đơn hàng vừa tạo

  const OrderSuccessScreen({super.key, required this.orderId});

  static const routeName = '/order-success';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon hoặc ảnh thành công
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.15),
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  color: Colors.green.shade600,
                  size: 80,
                ),
              ),
              const SizedBox(height: 30),

              // Dòng chữ thông báo
              Text(
                'Đặt hàng thành công!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cảm ơn bạn đã mua sắm. Đơn hàng của bạn đang được xử lý.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã đơn hàng của bạn: #${orderId.toString().padLeft(6, '0')}', // Ví dụ: #000015
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),

              // Nút xem chi tiết đơn hàng
              ElevatedButton(
                onPressed: () {
                  // TODO: Điều hướng đến trang chi tiết đơn hàng
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                       builder: (ctx) => OrderDetailScreen(orderId: orderId),
                     ),
                   );

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Xem chi tiết đơn hàng'),
              ),
              const SizedBox(height: 12),

              // Nút quay lại trang chủ
              OutlinedButton(
                onPressed: () {
                  // Chuyển về tab Trang chủ và quay về màn hình Home
                  context.read<BottomNavProvider>().changeTab(0);
                  Navigator.of(context).popUntil((route) => route.settings.name == '/home' || route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Tiếp tục mua sắm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}