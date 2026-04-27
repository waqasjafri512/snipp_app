import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';
import '../providers/notification_provider.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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

  // Helper method to sync Firebase user to backend
  Future<bool> _syncWithBackend(User firebaseUser, {String? username, String? fullName}) async {
    final token = await firebaseUser.getIdToken();
    if (token == null) return false;

    try {
      final response = await _apiService.post('/auth/sync', {
        'username': username ?? firebaseUser.displayName ?? '',
        'full_name': fullName ?? firebaseUser.displayName ?? '',
        'avatar_url': firebaseUser.photoURL,
      }, customHeaders: {
        'Authorization': 'Bearer $token',
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        // We save the custom JWT token from backend for legacy APIs
        await _apiService.saveToken(data['data']['token']);
        _user = data['data']['user'];
        SocketService().connect(_user!['id']);
        NotificationProvider().setUserId(_user!['id']);
        return true;
      }
      _error = data['message'] ?? 'Failed to sync with backend';
      return false;
    } catch (e) {
      _error = 'Connection error. Please check your server.';
      return false;
    }
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
      // 1. Register with Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Send Verification Email via Firebase
        if (!firebaseUser.emailVerified) {
          await firebaseUser.sendEmailVerification();
        }

        // 2. Sync with Backend
        final success = await _syncWithBackend(firebaseUser, username: username, fullName: fullName);
        _setLoading(false);
        return success;
      }
      
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Registration failed';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Firebase is not initialized or an unexpected error occurred.';
      _setLoading(false);
      return false;
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      // 1. Login with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // 2. Sync with Backend
        final success = await _syncWithBackend(firebaseUser);
        _setLoading(false);
        return success;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Login failed';
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Firebase is not initialized or an unexpected error occurred.';
      _setLoading(false);
      return false;
    }
  }

  // Auto-login (Check token on startup)
  Future<bool> tryAutoLogin() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
         // Optional: Reload to get latest emailVerified status
         await firebaseUser.reload();
         final success = await _syncWithBackend(_auth.currentUser!);
         if (success) {
           notifyListeners();
           return true;
         }
      }
    } catch (e) {
      // Firebase might not be ready or no user
    }
    
    // Fallback for custom token check if Firebase is not yet fully migrated locally
    final token = await _apiService.getToken();
    if (token == null) return false;

    try {
      final response = await _apiService.get('/auth/me');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        _user = data['data']['user'];
        // Update verification status from Firebase if logged in
        try {
          if (_user != null && _auth.currentUser != null) {
             _user!['is_verified'] = _auth.currentUser!.emailVerified;
          }
        } catch (e) {}
        
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
    try {
      await _auth.signOut();
    } catch (e) {}
    
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
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return {'success': true, 'message': 'Password reset link sent to your email.'};
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return {'success': false, 'message': e.message ?? 'Failed to send reset link.'};
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    // With Firebase, reset password happens via the email link in browser.
    // The in-app reset form isn't needed anymore unless using custom dynamic links.
    return {'success': false, 'message': 'Please use the link sent to your email to reset your password.'};
  }

  Future<Map<String, dynamic>> resendVerification() async {
    _setLoading(true);
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null && !firebaseUser.emailVerified) {
        await firebaseUser.sendEmailVerification();
        _setLoading(false);
        return {'success': true, 'message': 'Verification email sent via Firebase!'};
      }
      _setLoading(false);
      return {'success': false, 'message': 'User already verified or not logged in.'};
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'message': 'Failed to send verification.'};
    }
  }
}
