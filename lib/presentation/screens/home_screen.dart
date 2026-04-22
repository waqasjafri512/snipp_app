import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../providers/notification_provider.dart';
import '../providers/search_provider.dart';
import '../providers/chat_provider.dart';
import 'profile_screen.dart';
import 'feed_screen.dart';
import 'chat_list_screen.dart';
import 'search_screen.dart';

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

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          border: const Border(
            top: BorderSide(color: Color(0x147C3AED), width: 1),
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
                height: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNavItem(0, 'Home', Icons.home_rounded, Icons.home_outlined),
                    _buildNavItem(1, 'Discover', Icons.search_rounded, Icons.search_outlined),
                    _buildNavItem(2, 'Create', Icons.add_box_rounded, Icons.add_box_outlined),
                    _buildNavItem(3, 'Chat', Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded),
                    _buildNavItem(4, 'Profile', Icons.person_rounded, Icons.person_outline_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData selectedIcon, IconData unselectedIcon) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          child: Icon(
            isSelected ? selectedIcon : unselectedIcon,
            size: 26,
            color: isSelected ? Colors.black : Colors.black.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
