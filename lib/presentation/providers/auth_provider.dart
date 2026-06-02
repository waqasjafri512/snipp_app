import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';
import '../../data/services/notification_service.dart';
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

  // ✅ FIX: expose apiService for external use (Chat screen fix)
  ApiService get apiService => _apiService;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Helper: sync Firebase user with backend
  Future<bool> _syncWithBackend(
    User firebaseUser, {
    String? username,
    String? fullName,
  }) async {
    final token = await firebaseUser.getIdToken();
    if (token == null) return false;

    try {
      final response = await _apiService.post(
        '/auth/sync',
        {
          'username': username ?? firebaseUser.displayName ?? '',
          'full_name': fullName ?? firebaseUser.displayName ?? '',
          'avatar_url': firebaseUser.photoURL,
        },
        customHeaders: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await _apiService.saveToken(data['data']['token']);

        _user = data['data']['user'];

        SocketService().connect(_user!['id']);
        NotificationProvider.setUserId(_user!['id']);
        NotificationService().updateToken();

        notifyListeners();
        return true;
      }

      _setError(data['message'] ?? 'Failed to sync with backend');
      return false;
    } catch (e) {
      _setError('Connection error. Please check your server.');
      return false;
    }
  }

  // REGISTER
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        if (!firebaseUser.emailVerified) {
          await firebaseUser.sendEmailVerification();
        }

        final success = await _syncWithBackend(
          firebaseUser,
          username: username,
          fullName: fullName,
        );

        _setLoading(false);
        return success;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Registration failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Unexpected error occurred.');
      _setLoading(false);
      return false;
    }
  }

  // LOGIN
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final success = await _syncWithBackend(firebaseUser);

        _setLoading(false);
        return success;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Unexpected error occurred.');
      _setLoading(false);
      return false;
    }
  }

  // AUTO LOGIN
  Future<bool> tryAutoLogin() async {
    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        await firebaseUser.reload();

        final success = await _syncWithBackend(_auth.currentUser!);

        if (success) {
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}

    final token = await _apiService.getToken();
    if (token == null) return false;

    try {
      final response = await _apiService.get('/auth/me');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _user = data['data']['user'];

        if (_auth.currentUser != null) {
          _user!['is_verified'] = _auth.currentUser!.emailVerified;
        }

        SocketService().connect(_user!['id']);
        NotificationProvider.setUserId(_user!['id']);

        notifyListeners();
        return true;
      } else {
        await _apiService.deleteToken();
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}

    await _apiService.deleteToken();
    SocketService().disconnect();
    NotificationProvider.setUserId(null);

    _user = null;
    notifyListeners();
  }

  // FORGOT PASSWORD
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _setLoading(true);

    try {
      await _auth.sendPasswordResetEmail(email: email);

      _setLoading(false);
      return {
        'success': true,
        'message': 'Password reset link sent.'
      };
    } catch (e) {
      _setLoading(false);
      return {
        'success': false,
        'message': 'Failed to send reset email.'
      };
    }
  }

  // RESEND VERIFICATION EMAIL
  Future<Map<String, dynamic>> resendVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in.'};
      }

      await user.sendEmailVerification();
      return {'success': true, 'message': 'Verification email sent!'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send verification email.'};
    }
  }

  // CHANGE PASSWORD
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      await _apiService.post('/auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      _setLoading(false);

      return {
        'success': true,
        'message': 'Password updated successfully!'
      };
    } catch (e) {
      _setLoading(false);

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}