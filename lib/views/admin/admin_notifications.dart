// file: lib/screens/admin/pages/admin_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../providers/notification_provider.dart';
import '../../../models/notification_model.dart';
import '../../screens/admin/pages/admin_order_detail_screen.dart';


class AdminNotificationsScreen extends StatefulWidget {
  final Future<void> Function()? onRefresh; // 👈 thêm dòng này
  const AdminNotificationsScreen({super.key, this.onRefresh});
  static const routeName = '/admin-notifications';



  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tải lại thông báo khi màn hình được mở để đảm bảo dữ liệu mới nhất
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: const Text('Thông báo Admin'),
      // ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.notifications.isEmpty) {
            return const Center(child: Text('Bạn chưa có thông báo nào.'));
          }
          return RefreshIndicator(
            onRefresh: widget.onRefresh ?? provider.fetchNotifications,
            child: ListView.separated(
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
        title: Text(notification.title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
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
            context.read<NotificationProvider>().markAsRead(notification.id);
            if (notification.orderId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminOrderDetailScreen(orderId: notification.orderId!),
                ),
              );
            }
          }

      ),
    );
  }
}
