import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';
import '../providers/notification_provider.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Register
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success']) {
        await _apiService.saveToken(data['data']['token']);
        _user = data['data']['user'];
        SocketService().connect(_user!['id']);
        NotificationProvider().setUserId(_user!['id']);
        _setLoading(false);
        return true;
      } else {
        _error = data['message'] ?? 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check your server.';
      _setLoading(false);
      return false;
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        await _apiService.saveToken(data['data']['token']);
        _user = data['data']['user'];
        SocketService().connect(_user!['id']);
        NotificationProvider().setUserId(_user!['id']);
        _setLoading(false);
        return true;
      } else {
        _error = data['message'] ?? 'Login failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check your server.';
      _setLoading(false);
      return false;
    }
  }

  // Auto-login (Check token on startup)
  Future<bool> tryAutoLogin() async {
    final token = await _apiService.getToken();
    if (token == null) return false;

    try {
      final response = await _apiService.get('/auth/me');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        _user = data['data']['user'];
        SocketService().connect(_user!['id']);
        NotificationProvider().setUserId(_user!['id']);
        notifyListeners();
        return true;
      } else {
        await _apiService.deleteToken();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.deleteToken();
    SocketService().disconnect();
    NotificationProvider().setUserId(null);
    _user = null;
    notifyListeners();
  }

  // Password Recovery
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/forgot-password', {'email': email});
      final data = jsonDecode(response.body);
      _setLoading(false);
      return {'success': data['success'], 'message': data['message']};
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/reset-password', {
        'token': token,
        'newPassword': newPassword
      });
      final data = jsonDecode(response.body);
      _setLoading(false);
      return {'success': data['success'], 'message': data['message']};
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> resendVerification() async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/resend-verification', {});
      final data = jsonDecode(response.body);
      _setLoading(false);
      return {'success': data['success'], 'message': data['message']};
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Connection error'};
    }
  }
}
