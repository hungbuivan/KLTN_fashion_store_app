// file: lib/views/admin/chat_list_screen.dart (hoặc admin_messages.dart)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../providers/chat_provider.dart';
import '../../models/chat_room_model.dart';
import '../../screens/chat_message_screen.dart';

class ChatListScreen extends StatefulWidget {
  final VoidCallback onRefresh;
  const ChatListScreen({super.key, required this.onRefresh});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {

  @override
  void initState() {
    super.initState();
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
    // Thay thế AdminMessages bằng ChatListScreen trong AdminHomePage
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
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
                  // ✅ SỬA LỖI Ở ĐÂY
                  // Chỉ cung cấp backgroundImage và onBackgroundImageError khi có URL hợp lệ
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  onBackgroundImageError: hasAvatar ? (_, __) {} : null,
                  child: !hasAvatar
                      ? Text(room.userName.substring(0, 1).toUpperCase())
                      : null,
                ),
                title: Text(room.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  room.lastMessage ?? 'Bắt đầu cuộc trò chuyện...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: room.lastMessageTimestamp != null
                    ? Text(
                  DateFormat('HH:mm').format(room.lastMessageTimestamp!),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )
                    : null,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    ChatMessageScreen.routeName,
                    arguments: {
                      'roomId': room.id,
                      'userName': room.userName,
                    },
                  );
                },
              );
            },
            separatorBuilder: (ctx, index) => const Divider(height: 1, indent: 70, endIndent: 16),
          ),
        );
      },
    );
  }
}
