import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';

class NotificationProvider with ChangeNotifier {
  StreamSubscription? _socketSub;
  
  // Static userId so AuthProvider can set it without Provider context
  static int? _currentUserId;
  static void setUserId(int? userId) {
    _currentUserId = userId;
  }

  NotificationProvider() {
    _initSocketListeners();
  }

  final ApiService _apiService = ApiService();

  void _initSocketListeners() {
    _socketSub?.cancel();
    _socketSub = SocketService().eventStream.listen((event) {
      if (event['event'] == 'newNotification') {
        final data = event['data'];
        if (data != null) {
          // Filter out self-notifications if actor_id matches current user
          if (_currentUserId != null && data['actor_id'] == _currentUserId) {
            return;
          }

          _notifications.insert(0, {
            'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch,
            'type': (data['type'] ?? 'info').toString(),
            'actor_id': data['actor_id'],
            'actor_username': (data['actor_username'] ?? 'Someone').toString(),
            'actor_avatar': data['actor_avatar'],
            'dare_id': data['dare_id'],
            'dare_title': (data['dare_title'] ?? 'Dare').toString(),
            'message': (data['message'] ?? '').toString(),
            'is_read': false,
            'created_at': (data['created_at'] ?? DateTime.now().toIso8601String()).toString(),
          });
          _calculateUnread();
          notifyListeners();

          // Show top-level snackbar with proper message
          final messenger = MyApp.messengerKey.currentState;
          if (messenger != null) {
            final type = data['type']?.toString() ?? '';
            final actor = data['actor_username'] ?? 'Someone';
            final dareTitle = data['dare_title'] ?? '';
            String message;
            switch (type) {
              case 'like':
                message = '❤️ $actor liked your dare "$dareTitle"';
                break;
              case 'comment':
                message = '💬 $actor commented on "$dareTitle"';
                break;
              case 'follow':
                message = '👋 $actor started following you';
                break;
              case 'accept':
                message = '🎯 $actor accepted your dare "$dareTitle"';
                break;
              case 'complete':
                message = '🏆 $actor completed your dare "$dareTitle"';
                break;
              default:
                message = '🔔 $actor interacted with your content';
            }
            messenger.showSnackBar(
              SnackBar(
                content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primaryStart,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              ),
            );
          }
        }
      }
    });
  }
  
  bool _isLoading = false;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch Notifications
  Future<void> fetchNotifications({int page = 1}) async {
    if (page == 1) _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.get('/notifications?page=$page');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (page == 1) {
          _notifications = data['data']['notifications'];
        } else {
          _notifications.addAll(data['data']['notifications']);
        }
        _calculateUnread();
      } else {
        _error = data['message'] ?? 'Failed to fetch notifications';
      }
    } catch (e) {
      _error = 'Connection error';
    } finally {
      if (page == 1) _setLoading(false);
      notifyListeners();
    }
  }

  void _calculateUnread() {
    _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
  }

  // Mark single as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _apiService.post('/notifications/mark-read/$notificationId', {});
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
        _calculateUnread();
        notifyListeners();
      }
    } catch (e) {
      print('Mark read error: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _apiService.post('/notifications/mark-all-read', {});
      for (var n in _notifications) {
        n['is_read'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Mark all read error: $e');
    }
  }

  // FCM Token Management
  Future<void> saveFcmToken(String token) async {
    try {
      await _apiService.post('/profile/fcm-token', {'token': token});
    } catch (e) {
      print('Save FCM token error: $e');
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}
