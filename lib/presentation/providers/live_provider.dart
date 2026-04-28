import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';

class LiveProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription? _socketSub;
  
  LiveProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socketSub?.cancel();
    _socketSub = SocketService().eventStream.listen((event) {
      if (event['event'] == 'viewerCount') {
        _viewerCount = event['data']['count'] ?? 0;
        notifyListeners();
      }
    });
  }

  bool _isLoading = false;
  List<dynamic> _activeStreams = [];
  String? _error;
  int _viewerCount = 0;

  bool get isLoading => _isLoading;
  List<dynamic> get activeStreams => _activeStreams;
  String? get error => _error;
  int get viewerCount => _viewerCount;

  void resetViewerCount() {
    _viewerCount = 0;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch Active Streams
  Future<void> fetchActiveStreams() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/streams/active');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _activeStreams = data['data']['streams'];
      }
    } catch (e) {
      _error = 'Failed to load streams';
    } finally {
      _setLoading(false);
    }
  }

  // Get Agora Token from Backend
  Future<Map<String, dynamic>?> getAgoraToken(String channelName) async {
    try {
      final response = await _apiService.get('/streams/token?channelName=$channelName');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Notify backend when starting/ending
  Future<bool> startStream(String channelName, String title) async {
    try {
      final response = await _apiService.post('/streams/start', {
        'channelName': channelName,
        'title': title,
      });
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<void> endStream(String channelName) async {
    try {
      await _apiService.post('/streams/end', {'channelName': channelName});
    } catch (e) {
      print('EndStream error: $e');
    }
  }

  // Helper for permissions
  Future<bool> handlePermissions() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return camera.isGranted && mic.isGranted;
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}
