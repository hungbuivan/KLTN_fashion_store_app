// file: lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import 'order_detail_screen.dart'; // Để điều hướng

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  static const routeName = '/notifications';

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tải thông báo khi màn hình được mở
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã làm mới thông báo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          if (provider.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Bạn chưa có thông báo nào.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshNotifications,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _NotificationCard(notification: notification);
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          );
        },
      ),
    );
  }
}

// Widget cho mỗi item thông báo
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;
    return Material(
      color: isUnread ? Colors.blue.withOpacity(0.05) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          notification.orderId != null ? Iconsax.box_tick : Iconsax.notification_1,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          notification.title,
          style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm dd/MM/yyyy').format(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          // Đánh dấu là đã đọc
          context.read<NotificationProvider>().markAsRead(notification.id);
          // Nếu có orderId, điều hướng đến chi tiết đơn hàng
          if (notification.orderId != null) {
            Navigator.of(context).pushNamed(
              OrderDetailScreen.routeName,
              arguments: {'orderId': notification.orderId},
            );
          }
        },
      ),
    );
  }
}
