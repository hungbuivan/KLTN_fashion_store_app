// file: lib/models/notification_model.dart

class NotificationModel {
  final int id;
  final int? orderId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.orderId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int?,
      title: json['title'] as String? ?? 'Không có tiêu đề',
      message: json['message'] as String? ?? 'Không có nội dung.',
      isRead: json['read'] as bool? ?? false, // API trả về key là "read"
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
