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

  ChatRoomModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.unreadCount = 0, // Giá trị mặc định là 0
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    // Backend trả về thông tin user lồng bên trong
    final userJson = json['user'] as Map<String, dynamic>?;

    return ChatRoomModel(
      id: json['id'] as int? ?? 0,
      userId: userJson?['id'] as int? ?? 0,
      userName: userJson?['fullName'] as String? ?? 'Không rõ',
      userAvatarUrl: userJson?['avatarUrl'] as String?,

      // ✅ PARSE DỮ LIỆU MỚI TỪ JSON
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.parse(json['lastMessageTimestamp'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
