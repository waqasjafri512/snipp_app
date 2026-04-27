import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/app_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  void connect(int userId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(AppConstants.apiUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket unified connected: ${_socket!.id}');
      _socket!.emit('join', userId);
    });

    // Universal message handler
    _socket!.on('message', (data) => _eventController.add({'event': 'message', 'data': data}));
    _socket!.on('messagesRead', (data) => _eventController.add({'event': 'messagesRead', 'data': data}));
    
    // Dare events
    _socket!.on('newDare', (data) => _eventController.add({'event': 'newDare', 'data': data}));
    _socket!.on('dareUpdated', (data) => _eventController.add({'event': 'dareUpdated', 'data': data}));
    _socket!.on('dareDeleted', (data) => _eventController.add({'event': 'dareDeleted', 'data': data}));
    
    // Notification events
    _socket!.on('newNotification', (data) => _eventController.add({'event': 'newNotification', 'data': data}));
    
    // Live Stream events
    _socket!.on('streamMessage', (data) => _eventController.add({'event': 'streamMessage', 'data': data}));
    _socket!.on('streamReaction', (data) => _eventController.add({'event': 'streamReaction', 'data': data}));
    _socket!.on('viewerCount', (data) => _eventController.add({'event': 'viewerCount', 'data': data}));

    // Presence events
    _socket!.on('userStatus', (data) => _eventController.add({'event': 'userStatus', 'data': data}));

    _socket!.onDisconnect((_) => print('Socket unified disconnected'));
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
