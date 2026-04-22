import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';

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
    _user = null;
    notifyListeners();
  }
}
