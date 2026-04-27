import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';
import '../../core/constants/app_constants.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  ChatProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    SocketService().eventStream.listen((event) {
      if (event['event'] == 'message') {
        final message = event['data'] as Map<String, dynamic>;
        
        // If the message is with the current active chat user, add it to messages
        if (_activeChatUserId != null && 
            (message['sender_id'] == _activeChatUserId || message['receiver_id'] == _activeChatUserId)) {
          final exists = _messages.any((m) => m['id'] == message['id']);
          if (!exists) {
            _messages.insert(0, message);
            notifyListeners();
          }
        }
        
        // Update conversations list
        _updateConversationsLocally(message);
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
    SocketService().connect(currentUserId);
  }

  void _updateConversationsLocally(Map<String, dynamic> message) {
    // Logic to update the conversations list in memory for instant feedback
    fetchConversations(); // Simpler for now, can be optimized
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
      }
    } catch (e) {
      _error = 'Failed to load messages';
    } finally {
      _setLoading(false);
    }
  }

  // Send Message
  void sendMessage(int senderId, int receiverId, String content) {
    SocketService().emit('sendMessage', {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
    });
  }

  void clearActiveChat() {
    _activeChatUserId = null;
    _messages = [];
  }

  @override
  void dispose() {
    // SocketService is managed elsewhere (AuthProvider)
    super.dispose();
  }
}
