import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/cache_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription? _socketSub;
  int? _currentUserId;
  Set<int> _onlineUserIds = {};
  Timer? _heartbeatTimer;
  
  ChatProvider() {
    _initSocketListeners();
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_currentUserId != null) {
        try {
          await _apiService.post('/messages/heartbeat', {});
        } catch (e) {
          print('Heartbeat error: $e');
        }
      }
    });
  }

  Future<void> fetchOnlineStatuses(List<int> userIds) async {
    if (userIds.isEmpty) return;
    try {
      final response = await _apiService.post('/messages/users-status', {'userIds': userIds});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> statuses = data['data']['statuses'];
        for (var status in statuses) {
          if (status['online'] == true) {
            _onlineUserIds.add(status['userId']);
          } else {
            _onlineUserIds.remove(status['userId']);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Fetch online statuses error: $e');
    }
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
      } else if (event['event'] == 'userStatus') {
        final data = event['data'] as Map<String, dynamic>;
        final userId = data['userId'];
        final status = data['status'];
        if (status == 'online') {
          _onlineUserIds.add(userId);
        } else {
          _onlineUserIds.remove(userId);
        }
        notifyListeners();
      } else if (event['event'] == 'onlineUsers') {
        final List<dynamic> users = event['data'];
        _onlineUserIds = users.map((id) => int.parse(id.toString())).toSet();
        notifyListeners();
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
  Set<int> get onlineUserIds => _onlineUserIds;

  bool isUserOnline(int userId) => _onlineUserIds.contains(userId);

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
      _conversations[idx]['last_message_time'] = message['created_at'];
      if (senderId != _currentUserId && _activeChatUserId != otherId) {
        _conversations[idx]['unread_count'] = (_conversations[idx]['unread_count'] ?? 0) + 1;
      }
      // Move to top of list
      final conv = _conversations.removeAt(idx);
      _conversations.insert(0, conv);
      CacheService().cacheConversations(_conversations);
      notifyListeners();
    } else {
      // Truly new conversation — fetch from server
      fetchConversations();
    }
  }

  // Fetch all conversations
  Future<void> fetchConversations() async {
    // Fill from local Hive cache instantly
    final cached = CacheService().getCachedConversations();
    if (cached.isNotEmpty && _conversations.isEmpty) {
      _conversations = List<dynamic>.from(cached);
      notifyListeners();
    }
    
    try {
      final response = await _apiService.get('/messages/conversations');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _conversations = data['data']['conversations'];
        CacheService().cacheConversations(_conversations);
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

  // Send Message via REST API (reliable on Vercel) with optimistic UI
  void sendMessage(int senderId, int receiverId, String content, {String type = 'text', String? mediaUrl}) {
    _currentUserId ??= senderId;
    // 1. Optimistic: insert a local placeholder message immediately
    final optimisticId = -DateTime.now().millisecondsSinceEpoch; // negative to avoid collision with real IDs
    final optimisticMessage = {
      'id': optimisticId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      '_sending': true, // local flag
    };
    _messages.insert(0, optimisticMessage);
    _updateConversationsLocally(optimisticMessage);
    notifyListeners();

    // 2. Send via REST API
    _apiService.post('/messages/send', {
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
    }).then((response) {
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        // Replace optimistic message with real server message
        final serverMessage = data['data']['message'];
        final idx = _messages.indexWhere((m) => m['id'] == optimisticId);
        if (idx != -1) {
          _messages[idx] = serverMessage;
          notifyListeners();
        }
      } else {
        // Mark as failed
        final idx = _messages.indexWhere((m) => m['id'] == optimisticId);
        if (idx != -1) {
          _messages[idx]['_sending'] = false;
          _messages[idx]['_failed'] = true;
          notifyListeners();
        }
      }
    }).catchError((e) {
      print('Send message REST error: $e');
      final idx = _messages.indexWhere((m) => m['id'] == optimisticId);
      if (idx != -1) {
        _messages[idx]['_sending'] = false;
        _messages[idx]['_failed'] = true;
        notifyListeners();
      }
    });

    // 3. Also try socket (works when running local backend, no-op on Vercel)
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
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
