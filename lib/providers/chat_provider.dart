// file: lib/providers/chat_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import 'auth_provider.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

class ChatProvider with ChangeNotifier {
  final AuthProvider authProvider;
  final String _wsUrl = 'ws://10.0.2.2:8080/ws';
  final String _restApiUrl = 'http://10.0.2.2:8080/api/chat';

  StompClient? _stompClient;

  // State
  List<ChatRoomModel> _chatRooms = [];
  List<ChatRoomModel> get chatRooms => _chatRooms;

  List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ChatProvider(this.authProvider);
  // ✅ THÊM GETTER MỚI
  /// Tính tổng số phòng chat có tin nhắn chưa đọc.
  int get totalUnreadRoomsCount {
    if (_chatRooms.isEmpty) {
      return 0;
    }
    // Dùng fold để cộng dồn
    return _chatRooms.fold(0, (sum, room) => sum + (room.unreadCount > 0 ? 1 : 0));
  }


  // --- WebSocket & STOMP Logic ---

  void connectAndSubscribe(int roomId) {
    if (_stompClient?.isActive ?? false) {
      print("CHAT_PROVIDER_DEBUG: STOMP client đã được kết nối từ trước.");
      return;
    }

    _stompClient = StompClient(
      // ✅ SỬA LỖI Ở ĐÂY: Dùng StompConfig.SockJS
      config: StompConfig(
        url: _wsUrl,
        onConnect: (StompFrame frame) {
          print("CHAT_PROVIDER_DEBUG: Đã kết nối đến STOMP server!");

          _stompClient?.subscribe(
            destination: '/topic/room/$roomId',
            callback: (frame) {
              print("CHAT_PROVIDER_DEBUG: Đã nhận được tin nhắn mới từ topic!");
              try {
                if (frame.body != null) {
                  final result = json.decode(frame.body!);
                  print("CHAT_PROVIDER_DEBUG: Body tin nhắn: ${frame.body}");
                  final newMessage = ChatMessageModel.fromJson(result);

                  _messages.insert(0, newMessage);
                  notifyListeners();
                }
              } catch (e) {
                print("CHAT_PROVIDER_DEBUG: Lỗi parse tin nhắn: $e");
              }
            },
          );
          // ✅ 2. ĐĂNG KÝ NHẬN SỰ KIỆN "ĐÃ XEM"
          _stompClient?.subscribe(
            destination: '/topic/room/$roomId/seen',
            callback: (frame) {
              print("Nhận được sự kiện SEEN_UPDATE");
              // Khi nhận được sự kiện này, cập nhật trạng thái của tất cả tin nhắn đã gửi
              bool changed = false;
              _messages = _messages.map((msg) {
                // Chỉ cập nhật tin nhắn của mình và chưa được xem
                if (msg.senderId == authProvider.user?.id && !msg.isSeen) {
                  changed = true;
                  return msg.copyWith(isSeen: true);
                }
                return msg;
              }).toList();

              if (changed) notifyListeners();
            },
          );
          print("CHAT_PROVIDER_DEBUG: Đã đăng ký vào topic '/topic/room/$roomId'");
        },
        onWebSocketError: (dynamic error) => print("CHAT_PROVIDER_DEBUG: Lỗi WebSocket: $error"),
        onStompError: (StompFrame frame) => print("CHAT_PROVIDER_DEBUG: Lỗi STOMP: body='${frame.body}', headers='${frame.headers}'"),
        onDisconnect: (frame) => print("CHAT_PROVIDER_DEBUG: Đã ngắt kết nối."),
      ),
    );

    print("CHAT_PROVIDER_DEBUG: Đang kích hoạt STOMP client...");
    _stompClient!.activate();
  }

  void sendMessage(String content, int roomId) {
    if (authProvider.user == null) return;
    if (_stompClient == null || !_stompClient!.isActive) {
      print("CHAT_PROVIDER_DEBUG: LỖI - Không thể gửi tin nhắn, STOMP client chưa kết nối.");
      return;
    }

    final senderId = authProvider.user!.id;
    final senderType = authProvider.isAdmin ? 'ADMIN' : 'USER';

    final messageBody = json.encode({
      'roomId': roomId,
      'senderId': senderId,
      'senderType': senderType,
      'content': content
    });

    print("CHAT_PROVIDER_DEBUG: Đang gửi tin nhắn đến /app/chat.sendMessage với body: $messageBody");
    _stompClient?.send(
      destination: '/app/chat.sendMessage',
      body: messageBody,
    );
  }

  void disconnect() {
    print("CHAT_PROVIDER_DEBUG: Ngắt kết nối STOMP client...");
    _stompClient?.deactivate();
    _stompClient = null;
  }

  void clearChatMessages() {
    _messages = [];
  }

  // --- REST API Logic ---

  Future<void> fetchMessageHistory(int roomId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_restApiUrl/rooms/$roomId/messages'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _messages = data.map((json) => ChatMessageModel.fromJson(json)).toList().reversed.toList();
      } else {
        _errorMessage = "Lỗi tải lịch sử tin nhắn.";
      }
    } catch(e) {
      _errorMessage = "Lỗi kết nối: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchChatRoomsForAdmin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_restApiUrl/rooms'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        print('DEBUG: Chat rooms JSON data: $data'); // 🔍 Log ở đây
        print("DEBUG: Chat rooms JSON data: ${response.body}");

        _chatRooms = data.map((json) => ChatRoomModel.fromJson(json)).toList();
      }
      else {
        _errorMessage = "Lỗi tải danh sách chat.";
      }
    } catch(e) {
      _errorMessage = "Lỗi kết nối: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<ChatRoomModel?> createOrGetChatRoomForUser() async {
    if (authProvider.user == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
          Uri.parse('$_restApiUrl/rooms'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'userId': authProvider.user!.id})
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ChatRoomModel.fromJson(data);
      }
    } catch (e) {
      _errorMessage = "Lỗi: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ✅ HÀM MỚI: Đánh dấu phòng chat là đã đọc
  Future<void> markRoomAsRead(int roomId) async {
    if (authProvider.isGuest || authProvider.user == null) return;

    final readerType = authProvider.isAdmin ? 'ADMIN' : 'USER';
    final url = Uri.parse('$_restApiUrl/rooms/$roomId/mark-as-read?readerType=$readerType');

    try {
      await http.post(url);
      print("Đã gửi yêu cầu mark as read cho phòng $roomId, người đọc: $readerType");
      // Sau khi đánh dấu đã đọc, tải lại danh sách phòng chat để cập nhật unreadCount
      if (authProvider.isAdmin) {
        await fetchChatRoomsForAdmin();
      }
    } catch (e) {
      print("Lỗi khi đánh dấu đã đọc: $e");
    }
  }

  // ✅ HÀM MỚI: Gọi API để đánh dấu đã đọc
  Future<void> markMessagesAsSeen(int roomId) async {
    // Không cần đánh dấu đã đọc nếu là khách
    if (authProvider.isGuest || authProvider.user == null) return;

    final readerId = authProvider.user!.id;
    final url = Uri.parse('$_restApiUrl/rooms/$roomId/mark-as-seen?readerId=$readerId');
    try {
      await http.post(url);
      print("Đã gửi yêu cầu mark as seen cho phòng $roomId, người đọc: $readerId");
    } catch (e) {
      print("Lỗi khi gửi yêu cầu mark as seen: $e");
    }
  }

}
