// file: lib/views/home/app_header.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/constant.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../screens/notification_screen.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final User? user = authProvider.user;

    String displayName = "Guest";
    if (user != null) {
      if (user.fullName.isNotEmpty) {
        displayName = user.fullName;
      } else if (user.username.isNotEmpty) {
        displayName = user.username;
      } else if (user.email.isNotEmpty) {
        displayName = "User";
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            child: ClipOval(
              child: user?.avt_url != null && user!.avt_url.isNotEmpty
                  ? Image.network(
                user.avt_url,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    "${imagePath}user.png",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  );
                },
              )
                  : Image.asset(
                "${imagePath}user.png",
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Iconsax.user_octagon,
                      size: 30, color: Colors.grey);
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Chữ chào
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Xin chào, $displayName!",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  "Ngày tốt để mua sắm!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // ✅ Nhóm các icon vào một Row phụ
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ICON THÔNG BÁO
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return Badge(
                    label: Text(notificationProvider.unreadCount.toString()),
                    isLabelVisible: notificationProvider.unreadCount > 0,
                    child: IconButton(
                      icon: const Icon(Iconsax.notification, size: 28),
                      onPressed: () {
                        Navigator.of(context).pushNamed(NotificationScreen.routeName);
                      },
                      tooltip: "Thông báo",
                      color: Colors.grey[700],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),

              // ICON GIỎ HÀNG
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  final itemCount = cartProvider.cart?.totalItems ?? 0;
                  return Badge(
                    label: Text(itemCount.toString()),
                    isLabelVisible: itemCount > 0,
                    child: IconButton(
                      icon: const Icon(Iconsax.shopping_cart, size: 28),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/cart');
                      },
                      tooltip: "Giỏ hàng",
                      color: Colors.grey[700],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
