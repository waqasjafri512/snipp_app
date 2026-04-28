import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/app_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  int? _currentUserId;

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  bool get isConnected => _socket != null && _socket!.connected;

  void connect(int userId) {
    if (_socket != null && _socket!.connected) return;
    _currentUserId = userId;

    _socket = IO.io(AppConstants.apiUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 15,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 10000,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');
      _socket!.emit('join', userId);
    });

    // Universal message handler
    _socket!.on('message', (data) => _emitSafe('message', data));
    _socket!.on('messagesRead', (data) => _emitSafe('messagesRead', data));
    
    // Dare events
    _socket!.on('newDare', (data) => _emitSafe('newDare', data));
    _socket!.on('dareUpdated', (data) => _emitSafe('dareUpdated', data));
    _socket!.on('dareDeleted', (data) => _emitSafe('dareDeleted', data));
    
    // Comment events
    _socket!.on('newComment', (data) => _emitSafe('newComment', data));
    
    // Notification events
    _socket!.on('newNotification', (data) => _emitSafe('newNotification', data));
    
    // Live Stream events
    _socket!.on('streamMessage', (data) => _emitSafe('streamMessage', data));
    _socket!.on('streamReaction', (data) => _emitSafe('streamReaction', data));
    _socket!.on('viewerCount', (data) => _emitSafe('viewerCount', data));

    // Presence events
    _socket!.on('userStatus', (data) => _emitSafe('userStatus', data));
    
    // Group events
    _socket!.on('groupMessage', (data) => _emitSafe('groupMessage', data));

    // Call events
    _socket!.on('incomingCall', (data) => _emitSafe('incomingCall', data));
    _socket!.on('callAccepted', (data) => _emitSafe('callAccepted', data));
    _socket!.on('callRejected', (data) => _emitSafe('callRejected', data));
    _socket!.on('callEnded', (data) => _emitSafe('callEnded', data));

    _socket!.onDisconnect((_) => print('Socket disconnected'));
    _socket!.onReconnect((_) {
      print('Socket reconnected, re-joining room...');
      _socket!.emit('join', userId);
    });
  }

  void _emitSafe(String event, dynamic data) {
    if (!_eventController.isClosed) {
      _eventController.add({'event': event, 'data': data});
    }
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
    // Close old controller and create fresh one for next session
    if (!_eventController.isClosed) {
      _eventController.close();
    }
    _eventController = StreamController<Map<String, dynamic>>.broadcast();
  }
}
