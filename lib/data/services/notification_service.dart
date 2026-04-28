import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/call_provider.dart';
import '../../main.dart';
import '../repositories/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  Future<void> initialize() async {
    // 1. Request Permission (iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    }

    // 2. Setup Local Notifications (for Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click when app is in foreground
        print('Notification clicked: ${details.payload}');
      },
    );

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      // If it's a call, handle it via CallProvider
      if (message.data['type'] == 'call') {
        final context = MyApp.navigatorKey.currentContext;
        if (context != null) {
          Provider.of<CallProvider>(context, listen: false).handleIncomingCall(_mapFcmCallData(message.data));
          return; // Don't show standard notification for calls in foreground
        }
      }

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // 4. Handle Background/Terminated Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      
      if (message.data['type'] == 'call') {
        final context = MyApp.navigatorKey.currentContext;
        if (context != null) {
          Provider.of<CallProvider>(context, listen: false).handleIncomingCall(_mapFcmCallData(message.data));
        }
      }
    });

    // 5. Handle Terminated State Notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null && initialMessage.data['type'] == 'call') {
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = MyApp.navigatorKey.currentContext;
        if (context != null) {
          Provider.of<CallProvider>(context, listen: false).handleIncomingCall(_mapFcmCallData(initialMessage.data));
        }
      });
    }

    // 6. Listen for Token Refresh
    _fcm.onTokenRefresh.listen((newToken) {
      print('FCM Token Refreshed: $newToken');
      updateToken(newToken);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'snipp_channel',
      'Snipp Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<void> updateToken([String? token]) async {
    try {
      token ??= await _fcm.getToken();
      if (token != null) {
        print('Updating FCM Token on server...');
        final response = await _apiService.post('/auth/fcm-token', {'token': token});
        print('FCM Token update response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Background message handler must be a top-level function
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  /// Maps FCM push notification data fields to the format CallProvider expects.
  /// FCM sends: from, fromName, fromAvatar, callType, type='call'
  /// CallProvider expects: from, fromName, fromAvatar, type='audio'/'video'
  Map<String, dynamic> _mapFcmCallData(Map<String, dynamic> data) {
    return {
      'from': data['from'] ?? data['senderId'],
      'fromName': data['fromName'] ?? data['senderName'] ?? 'Unknown',
      'fromAvatar': data['fromAvatar'] ?? data['senderAvatar'],
      'type': data['callType'] ?? 'audio',
      'channelName': data['channelName'] ?? '',
    };
  }
}
