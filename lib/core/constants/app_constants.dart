import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Snipp';
  // static const String apiUrl = 'https://snipp-backend.vercel.app/api'; // Production Vercel Link
  static const String apiUrl = 'http://192.168.1.168:5000/api';
  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'current_user';
  
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String createDareRoute = '/create-dare';
  static const String chatListRoute = '/chat-list';
  static const String chatDetailRoute = '/chat-detail';
  static const String searchRoute = '/search';
  static const String notificationsRoute = '/notifications';
  
  static String getMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final baseUrl = apiUrl.replaceAll('/api', '');
    return '$baseUrl$path';
  }
}

class AppColors {
  // Brand Gradients
  static const Color primaryStart = Color(0xFF7C3AED); // Purple
  static const Color primaryMiddle = Color(0xFFC026D3); // Deep Pink
  static const Color primaryEnd = Color(0xFFEC4899);   // Pink
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryMiddle, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Surfaces
  static const Color background = Color(0xFFF8F7FF);
  static const Color cardBg = Color(0xFFFFFFFF);
  
  // Text
  static const Color textMain = Color(0xFF1A1033);
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Accents
  static const Color accent = Color(0xFFEC4899); 
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color muted = Color(0xFF6B7280);
}

