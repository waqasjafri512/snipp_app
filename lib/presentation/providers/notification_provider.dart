import 'dart:convert';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  NotificationProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    SocketService().eventStream.listen((event) {
      if (event['event'] == 'newNotification') {
        final data = event['data'];
        if (data != null) {
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

          // Show top-level snackbar
          final messenger = MyApp.messengerKey.currentState;
          if (messenger != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('🔔 ${data['actor_username']} ${data['type']}ed your dare: ${data['dare_title']}'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0), // Push it to top? No, snackbars are bottom.
                backgroundColor: AppColors.primaryStart,
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () {}, // Navigate to notifications?
                ),
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
}
