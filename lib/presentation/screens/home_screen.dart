import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../providers/notification_provider.dart';
import '../providers/search_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import 'profile_screen.dart';
import 'feed_screen.dart';
import 'chat_list_screen.dart';
import 'search_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const SizedBox.shrink(), // Placeholder for center button
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, AppConstants.createDareRoute);
      return;
    }
    
    if (index == 1) {
      Provider.of<SearchProvider>(context, listen: false).fetchTrending();
    }
    
    if (index == 3) {
      Provider.of<ChatProvider>(context, listen: false).fetchConversations();
    }

    if (index == 4) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      if (authProv.user != null) {
        final profileProv = Provider.of<ProfileProvider>(context, listen: false);
        final currentUserId = authProv.user!['id'];
        if (profileProv.userProfile == null || profileProv.userProfile!['id'] != currentUserId) {
          profileProv.fetchProfile(currentUserId);
          profileProv.fetchUserDares(currentUserId);
          profileProv.fetchParticipatedDares(currentUserId);
        }
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Scaffold(
          backgroundColor: theme.background,
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? theme.background.withOpacity(0.9) : Colors.white.withOpacity(0.97),
              border: Border(
                top: BorderSide(color: isDark ? Colors.white10 : const Color(0x147C3AED), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: SafeArea(
                  child: SizedBox(
                    height: 68,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNavItem(0, 'Home', Icons.home_rounded, Icons.home_outlined, theme, isDark),
                        _buildNavItem(1, 'Discover', Icons.explore_rounded, Icons.explore_outlined, theme, isDark),
                        _buildNavItem(2, 'Create', Icons.add_box_rounded, Icons.add_box_outlined, theme, isDark),
                        _buildNavItem(3, 'Chat', Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, theme, isDark),
                        _buildNavItem(4, 'Profile', Icons.person_rounded, Icons.person_outline_rounded, theme, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, String label, IconData selectedIcon, IconData unselectedIcon, AppTheme theme, bool isDark) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 24,
              color: isSelected ? theme.primaryStart : (isDark ? Colors.white54 : Colors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? theme.primaryStart : (isDark ? Colors.white38 : Colors.black.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
