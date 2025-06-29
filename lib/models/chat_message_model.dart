// file: lib/models/chat_message_model.dart

enum SenderType { USER, ADMIN, UNKNOWN }

class ChatMessageModel {
  final int? id;
  final int roomId;
  final int senderId;
  final SenderType senderType;
  final String content;
  final DateTime timestamp;
  final bool isSeen; // ✅ THÊM TRƯỜNG MỚI

  ChatMessageModel({
    this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.timestamp,
    this.isSeen = false, // ✅ Thêm vào constructor
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as int?,
      roomId: json['roomId'] as int? ?? 0,
      senderId: json['senderId'] as int? ?? 0,
      senderType: _senderTypeFromString(json['senderType'] as String?),
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isSeen: json['seen'] as bool? ?? false, // ✅ Parse từ JSON
    );
  }

  // Hàm tạo một bản sao của tin nhắn với trạng thái isSeen đã được cập nhật
  ChatMessageModel copyWith({bool? isSeen}) {
    return ChatMessageModel(
      id: this.id,
      roomId: this.roomId,
      senderId: this.senderId,
      senderType: this.senderType,
      content: this.content,
      timestamp: this.timestamp,
      isSeen: isSeen ?? this.isSeen,
    );
  }

  static SenderType _senderTypeFromString(String? type) {
    if (type == 'ADMIN') return SenderType.ADMIN;
    if (type == 'USER') return SenderType.USER;
    return SenderType.UNKNOWN;
  }
}
