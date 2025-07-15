// file: lib/screens/chat/chat_message_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_message_model.dart';

class ChatMessageScreen extends StatefulWidget {
  final int roomId;
  final String userName;

  const ChatMessageScreen({
    super.key,
    required this.roomId,
    required this.userName
  });

  static const routeName = '/chat-messages';

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // ✅ STATE MỚI: Lưu ID của tin nhắn đang được nhấn vào
  int? _expandedMessageId;

  late ChatProvider _chatProvider; // Khai báo ở đầu lớp _ChatMessageScreenState

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider = context.read<ChatProvider>(); // Lưu lại 1 lần duy nhất
      _chatProvider.clearChatMessages();
      _chatProvider.fetchMessageHistory(widget.roomId).then((_) {
        _chatProvider.markRoomAsRead(widget.roomId);
      });
      _chatProvider.connectAndSubscribe(widget.roomId);
    });
  }

  @override
  void dispose() {
    _chatProvider.disconnect(); // Sử dụng biến đã lưu trước đó
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  // ✅ HÀM MỚI: Xử lý khi người dùng nhấn vào một tin nhắn
  void _toggleMessageExpansion(int messageId) {
    setState(() {
      if (_expandedMessageId == messageId) {
        _expandedMessageId = null; // Nhấn lần nữa để ẩn đi
      } else {
        _expandedMessageId = messageId; // Hiển thị chi tiết cho tin nhắn này
      }
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(content, widget.roomId);
      _messageController.clear();
      // Cuộn xuống tin nhắn mới nhất
      Timer(const Duration(milliseconds: 100), () {
        if(_scrollController.hasClients){
          _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(authProvider.isAdmin ? widget.userName : "Hỗ trợ khách hàng"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.messages.isEmpty) { return const Center(child: CircularProgressIndicator()); }
                if (provider.errorMessage != null) { return Center(child: Text(provider.errorMessage!)); }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Hiển thị từ dưới lên
                  padding: const EdgeInsets.all(16.0),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final isMe = message.senderId == authProvider.user?.id;
                    final isLastMessage = index == 0; // Tin nhắn cuối cùng

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      isLastMessage: isLastMessage,
                      isExpanded: _expandedMessageId == message.id,
                      onTap: () => _toggleMessageExpansion(message.id!),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Nhập tin nhắn...', border: InputBorder.none), textCapitalization: TextCapitalization.sentences, onSubmitted: (_) => _sendMessage())),
          IconButton(icon: const Icon(Iconsax.send_1), onPressed: _sendMessage, color: Theme.of(context).primaryColor),
        ],
      ),
    );
  }
}

// ✅ WIDGET BONG BÓNG CHAT ĐÃ ĐƯỢC CẬP NHẬT
class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool isLastMessage;
  final bool isExpanded;
  final VoidCallback onTap;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isLastMessage,
    required this.isExpanded,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bong bóng chat
          GestureDetector(
            onTap: onTap,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            ),
          ),

          // Thời gian và trạng thái
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Visibility(
              // Hiện khi là tin nhắn cuối cùng HOẶC khi được nhấn vào
              visible: isExpanded || isLastMessage,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeago.format(message.timestamp, locale: 'vi'),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isSeen ? Iconsax.eye : Iconsax.tick_circle,
                        size: 14,
                        color: message.isSeen ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        message.isSeen ? "Đã xem" : "Đã gửi",
                        style: TextStyle(
                            color: message.isSeen ? Colors.blue : Colors.grey,
                            fontSize: 11,
                            fontWeight: message.isSeen ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
