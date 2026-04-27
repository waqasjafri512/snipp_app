import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String name;
  final Color primaryStart;
  final Color primaryMiddle;
  final Color primaryEnd;
  final Color background;
  final Color textMain;
  final LinearGradient gradient;

  AppTheme({
    required this.name,
    required this.primaryStart,
    required this.primaryMiddle,
    required this.primaryEnd,
    required this.background,
    required this.textMain,
  }) : gradient = LinearGradient(
          colors: [primaryStart, primaryMiddle, primaryEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_index';
  
  int _currentThemeIndex = 0;
  
  final List<AppTheme> themes = [
    AppTheme(
      name: 'Classic Purple',
      primaryStart: const Color(0xFF7C3AED),
      primaryMiddle: const Color(0xFFC026D3),
      primaryEnd: const Color(0xFFEC4899),
      background: const Color(0xFFF8F7FF),
      textMain: const Color(0xFF1A1033),
    ),
    AppTheme(
      name: 'Midnight Gold',
      primaryStart: const Color(0xFF1A1A1A),
      primaryMiddle: const Color(0xFF333333),
      primaryEnd: const Color(0xFFD4AF37),
      background: const Color(0xFF0F0F0F),
      textMain: Colors.white,
    ),
    AppTheme(
      name: 'Emerald Royale',
      primaryStart: const Color(0xFF064E3B),
      primaryMiddle: const Color(0xFF059669),
      primaryEnd: const Color(0xFF10B981),
      background: const Color(0xFFF0FDF4),
      textMain: const Color(0xFF064E3B),
    ),
    AppTheme(
      name: 'Ocean Deep',
      primaryStart: const Color(0xFF1E3A8A),
      primaryMiddle: const Color(0xFF2563EB),
      primaryEnd: const Color(0xFF60A5FA),
      background: const Color(0xFFEFF6FF),
      textMain: const Color(0xFF1E3A8A),
    ),
    AppTheme(
      name: 'Rose Quartz',
      primaryStart: const Color(0xFFBE185D),
      primaryMiddle: const Color(0xFFDB2777),
      primaryEnd: const Color(0xFFF472B6),
      background: const Color(0xFFFFF1F2),
      textMain: const Color(0xFF831843),
    ),
    AppTheme(
      name: 'Sunset Blaze',
      primaryStart: const Color(0xFF7C2D12),
      primaryMiddle: const Color(0xFFEA580C),
      primaryEnd: const Color(0xFFF97316),
      background: const Color(0xFFFFF7ED),
      textMain: const Color(0xFF7C2D12),
    ),
    AppTheme(
      name: 'Arctic Frost',
      primaryStart: const Color(0xFF0C4A6E),
      primaryMiddle: const Color(0xFF0284C7),
      primaryEnd: const Color(0xFF38BDF8),
      background: const Color(0xFFF0F9FF),
      textMain: const Color(0xFF0C4A6E),
    ),
    AppTheme(
      name: 'Golden Sands',
      primaryStart: const Color(0xFF78350F),
      primaryMiddle: const Color(0xFFB45309),
      primaryEnd: const Color(0xFFF59E0B),
      background: const Color(0xFFFFFBEB),
      textMain: const Color(0xFF78350F),
    ),
    AppTheme(
      name: 'Vibrant Neon',
      primaryStart: const Color(0xFF4F46E5),
      primaryMiddle: const Color(0xFF7C3AED),
      primaryEnd: const Color(0xFFD946EF),
      background: const Color(0xFFF5F3FF),
      textMain: const Color(0xFF1E1B4B),
    ),
    AppTheme(
      name: 'Royal Velvet',
      primaryStart: const Color(0xFF4C1D95),
      primaryMiddle: const Color(0xFF6D28D9),
      primaryEnd: const Color(0xFF8B5CF6),
      background: const Color(0xFFF5F3FF),
      textMain: const Color(0xFF2E1065),
    ),
  ];

  ThemeProvider() {
    _loadTheme();
  }

  int get currentThemeIndex => _currentThemeIndex;
  AppTheme get currentTheme => themes[_currentThemeIndex];

  void setTheme(int index) async {
    if (index >= 0 && index < themes.length) {
      _currentThemeIndex = index;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, index);
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeIndex = prefs.getInt(_themeKey) ?? 0;
    notifyListeners();
  }
}
