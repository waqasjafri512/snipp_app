import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';

class GroupProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  GroupProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    SocketService().eventStream.listen((event) {
      if (event['event'] == 'groupMessage') {
        final message = event['data'] as Map<String, dynamic>;
        
        // If the message belongs to the current active group, add it
        if (_activeGroupId != null && message['group_id'] == _activeGroupId) {
          final exists = _messages.any((m) => m['id'] == message['id']);
          if (!exists) {
            _messages.insert(0, message);
            notifyListeners();
          }
        }
        
        // Update the groups list with the new message
        fetchGroups();
      }
    });
  }

  bool _isLoading = false;
  List<dynamic> _groups = [];
  List<dynamic> _messages = [];
  int? _activeGroupId;
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get groups => _groups;
  List<dynamic> get messages => _messages;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchGroups() async {
    try {
      final response = await _apiService.get('/groups');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _groups = data['data']['groups'];
        notifyListeners();
      }
    } catch (e) {
      print('Groups fetch error: $e');
    }
  }

  Future<void> fetchGroupMessages(int groupId) async {
    _activeGroupId = groupId;
    _setLoading(true);
    // Join the socket room
    SocketService().emit('joinGroup', groupId);

    try {
      final response = await _apiService.get('/groups/$groupId/messages');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _messages = data['data']['messages'];
      }
    } catch (e) {
      _error = 'Failed to load group messages';
    } finally {
      _setLoading(false);
    }
  }

  void sendGroupMessage(int senderId, int groupId, String content, {String type = 'text', String? mediaUrl}) {
    SocketService().emit('sendGroupMessage', {
      'senderId': senderId,
      'groupId': groupId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
    });
  }

  Future<bool> createGroup(String name, String description, {String? imagePath}) async {
    _setLoading(true);
    try {
      if (imagePath != null) {
        // We'd upload the image here if we supported group avatar uploads via multipart
        // For simplicity, we just send name/desc in a POST request.
        // But the backend expects 'avatar' field in a multipart request.
        final response = await _apiService.uploadFile('/groups', imagePath, 'avatar');
        // The upload method needs to be modified or we need a specific multipart request that also sends name/desc.
      } else {
        final response = await _apiService.post('/groups', {
          'name': name,
          'description': description
        });
        final data = jsonDecode(response.body);
        if (response.statusCode == 201 && data['success']) {
          fetchGroups();
          _setLoading(false);
          return true;
        }
      }
      _setLoading(false);
      return false;
    } catch (e) {
      print('Create group error: $e');
      _setLoading(false);
      return false;
    }
  }

  void clearActiveGroup() {
    _activeGroupId = null;
    _messages = [];
  }
}
