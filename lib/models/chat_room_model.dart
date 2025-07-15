// file: lib/models/chat_room_model.dart

class ChatRoomModel {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatarUrl;

  // ✅ CÁC TRƯỜNG MỚI
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final int unreadCount; // Số tin nhắn chưa đọc
// ✅ Thêm trường này:
  final String? lastMessageSenderType; // "ADMIN" hoặc "USER"

  ChatRoomModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.unreadCount = 0, // Giá trị mặc định là 0
    this.lastMessageSenderType, // thêm vào constructor
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      userName: json['userName'] as String? ?? 'Không rõ',
      userAvatarUrl: json['userAvatarUrl'] as String?,

      lastMessage: json['lastMessage'] as String?,
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.parse(json['lastMessageTimestamp'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessageSenderType: json['lastMessageSenderType'], // <-- 👈 thêm ở đây
    );
  }

}
