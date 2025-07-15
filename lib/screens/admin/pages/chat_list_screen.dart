// file: lib/screens/admin/pages/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago; // ✅ Import package timeago

import '../../../providers/chat_provider.dart';
import '../../chat_message_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Cài đặt ngôn ngữ Tiếng Việt cho timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshChatRooms();
    });
  }

  Future<void> _refreshChatRooms() async {
    await Provider.of<ChatProvider>(context, listen: false).fetchChatRoomsForAdmin();
  }

  String _fixAvatarUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/avatars/$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn từ Khách hàng'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.chatRooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.chatRooms.isEmpty) {
            return const Center(child: Text('Chưa có cuộc trò chuyện nào.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshChatRooms,
            child: ListView.separated(
              itemCount: provider.chatRooms.length,
              itemBuilder: (ctx, index) {
                final room = provider.chatRooms[index];
                final avatarUrl = _fixAvatarUrl(room.userAvatarUrl);
                final hasAvatar = avatarUrl.isNotEmpty;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: !hasAvatar
                        ? Text(room.userName.substring(0, 1).toUpperCase())
                        : null,
                  ),
                  title: Text(room.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    room.lastMessage != null
                        ? (room.lastMessageSenderType == 'ADMIN'
                        ? 'Bạn: ${room.lastMessage}'
                        : room.lastMessage!)
                        : 'Bắt đầu cuộc trò chuyện...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // ✅ HIỂN THỊ THỜI GIAN
                      if (room.lastMessageTimestamp != null)
                        Text(
                          timeago.format(room.lastMessageTimestamp!, locale: 'vi'),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      // ✅ HIỂN THỊ HUY HIỆU CHƯA ĐỌC
                      if (room.unreadCount > 0)
                        Badge(
                          label: Text(room.unreadCount.toString()),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).pushNamed(
                      ChatMessageScreen.routeName,
                      arguments: {
                        'roomId': room.id,
                        'userName': room.userName,
                      },
                    );
                    // Tải lại danh sách sau khi quay về từ màn hình chat
                    _refreshChatRooms();
                  },
                );
              },
              separatorBuilder: (ctx, index) => const Divider(height: 1, indent: 70, endIndent: 16),
            ),
          );
        },
      ),
    );
  }
}
