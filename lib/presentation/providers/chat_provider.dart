import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';
import '../../core/constants/app_constants.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription? _socketSub;
  int? _currentUserId;
  
  ChatProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socketSub?.cancel();
    _socketSub = SocketService().eventStream.listen((event) {
      if (event['event'] == 'message') {
        final message = event['data'] as Map<String, dynamic>;
        
        // If the message is with the current active chat user, add it to messages
        if (_activeChatUserId != null && 
            (message['sender_id'] == _activeChatUserId || message['receiver_id'] == _activeChatUserId)) {
          final exists = _messages.any((m) => m['id'] == message['id']);
          if (!exists) {
            _messages.insert(0, message);
            // If we are active in this chat, mark as read immediately
            if (message['sender_id'] == _activeChatUserId) {
              markAsRead(_activeChatUserId!);
            }
            notifyListeners();
          }
        }
        
        // Update conversations list
        _updateConversationsLocally(message);
      } else if (event['event'] == 'messagesRead') {
        final data = event['data'] as Map<String, dynamic>;
        // If the other user (active chat) read our messages
        if (_activeChatUserId == data['readBy']) {
          for (var i = 0; i < _messages.length; i++) {
            if (_messages[i]['receiver_id'] == data['readBy']) {
              _messages[i]['is_read'] = true;
            }
          }
          notifyListeners();
        }
      }
    });
  }

  bool _isLoading = false;
  List<dynamic> _conversations = [];
  List<dynamic> _messages = [];
  int? _activeChatUserId;
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get conversations => _conversations;
  List<dynamic> get messages => _messages;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Unified SocketService handles initialization
  void initSocket(int currentUserId) {
    _currentUserId = currentUserId;
    SocketService().connect(currentUserId);
  }

  void _updateConversationsLocally(Map<String, dynamic> message) {
    final senderId = message['sender_id'];
    final receiverId = message['receiver_id'];
    final otherId = senderId == _currentUserId ? receiverId : senderId;
    
    final idx = _conversations.indexWhere((c) => c['other_user_id'] == otherId);
    if (idx != -1) {
      // Update existing conversation in-memory
      _conversations[idx]['last_message'] = message['content'];
      _conversations[idx]['last_message_at'] = message['created_at'];
      if (senderId != _currentUserId && _activeChatUserId != otherId) {
        _conversations[idx]['unread_count'] = (_conversations[idx]['unread_count'] ?? 0) + 1;
      }
      // Move to top of list
      final conv = _conversations.removeAt(idx);
      _conversations.insert(0, conv);
      notifyListeners();
    } else {
      // Truly new conversation — fetch from server
      fetchConversations();
    }
  }

  // Fetch all conversations
  Future<void> fetchConversations() async {
    try {
      final response = await _apiService.get('/messages/conversations');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _conversations = data['data']['conversations'];
        notifyListeners();
      }
    } catch (e) {
      print('Conversations error: $e');
    }
  }

  // Fetch chat history with a user
  Future<void> fetchChatHistory(int otherUserId) async {
    _activeChatUserId = otherUserId;
    _setLoading(true);
    try {
      final response = await _apiService.get('/messages/history/$otherUserId');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _messages = data['data']['history'];
        // Since we loaded the history, mark them as read locally too
        _updateConversationReadStatus(otherUserId);
      }
    } catch (e) {
      _error = 'Failed to load messages';
    } finally {
      _setLoading(false);
    }
  }

  void _updateConversationReadStatus(int otherUserId) {
    final index = _conversations.indexWhere((c) => c['other_user_id'] == otherUserId);
    if (index != -1) {
      _conversations[index]['unread_count'] = 0;
      notifyListeners();
    }
  }

  // Mark messages as read
  Future<void> markAsRead(int otherUserId) async {
    try {
      await _apiService.post('/messages/mark-read/$otherUserId', {});
      _updateConversationReadStatus(otherUserId);
    } catch (e) {
      print('MarkRead error: $e');
    }
  }

  // Total unread messages across all conversations
  int get totalUnreadCount {
    int count = 0;
    for (var conv in _conversations) {
      count += (conv['unread_count'] as int? ?? 0);
    }
    return count;
  }

  // Send Message
  void sendMessage(int senderId, int receiverId, String content, {String type = 'text', String? mediaUrl}) {
    SocketService().emit('sendMessage', {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
    });
  }

  // Upload and Send Media
  Future<bool> sendMediaMessage(int senderId, int receiverId, String filePath) async {
    try {
      final response = await _apiService.uploadFile('/messages/upload', filePath, 'media');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        final mediaUrl = data['data']['mediaUrl'];
        final type = data['data']['type']; // 'image' or 'video'
        
        sendMessage(senderId, receiverId, '[Media Message]', type: type, mediaUrl: mediaUrl);
        return true;
      }
      return false;
    } catch (e) {
      print('Media upload error: $e');
      return false;
    }
  }

  void clearActiveChat() {
    _activeChatUserId = null;
    _messages = [];
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}
