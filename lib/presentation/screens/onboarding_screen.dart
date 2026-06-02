import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Interests Selection
  final List<Map<String, String>> _categories = [
    {'emoji': '🍿', 'label': 'Pop Culture'},
    {'emoji': '🎮', 'label': 'Gaming'},
    {'emoji': '⚽', 'label': 'Sports'},
    {'emoji': '🍔', 'label': 'Foodie'},
    {'emoji': '✈️', 'label': 'Travel'},
    {'emoji': '🎨', 'label': 'Art'},
    {'emoji': '🎵', 'label': 'Music'},
    {'emoji': '🕺', 'label': 'Dance'},
    {'emoji': '🧠', 'label': 'Trivia'},
    {'emoji': '🎭', 'label': 'Comedy'},
    {'emoji': '📷', 'label': 'Photography'},
    {'emoji': '💻', 'label': 'Tech'},
  ];
  final Set<String> _selectedCategories = {};

  // Avatar Selection
  File? _avatarFile;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (file != null) {
      setState(() {
        _avatarFile = File(file.path);
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final profileProv = Provider.of<ProfileProvider>(context, listen: false);

    // 1. Upload Avatar if selected
    if (_avatarFile != null) {
      await profileProv.uploadAvatar(_avatarFile!.path);
    }

    // 2. Save Selected Interests to bio or settings (we can append to bio or send to updateProfile)
    final bioString = 'Interests: ${_selectedCategories.join(', ')}';
    await profileProv.updateProfile({'bio': bioString});

    // 3. Mark user locally as onboarded and redirect to Home
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Scaffold(
          backgroundColor: theme.background,
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomeStep(theme),
                  _buildInterestsStep(theme, isDark),
                  _buildAvatarStep(theme, isDark),
                ],
              ),
              
              // Custom indicator / Next Button
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot Indicators
                    Row(
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            gradient: _currentPage == index ? theme.gradient : null,
                            color: _currentPage == index ? null : (isDark ? Colors.white24 : Colors.grey[300]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    
                    // Next / Start Button
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: theme.gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryStart.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _currentPage == 2 ? 'Get Started' : 'Next →',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Welcome Step (Slide 1)
  Widget _buildWelcomeStep(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: theme.gradient,
              shape: BoxShape.circle,
            ),
            child: const Text('⚡', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 30),
          Text(
            'Welcome to\nSnipp!',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: theme.textMain,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A social playground where challenges become dares and videos become reactions. Play along, earn points, and climb the leaderboard! 🚀',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: theme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Interests Selection Step (Slide 2)
  Widget _buildInterestsStep(dynamic theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you like?',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: theme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your interests to customize your Snipp social feed. Choose at least 3.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _categories.map((cat) {
                  final label = cat['label']!;
                  final isSelected = _selectedCategories.contains(label);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategories.remove(label);
                        } else {
                          _selectedCategories.add(label);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected ? theme.gradient : null,
                        color: isSelected ? null : (isDark ? Colors.white10 : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.transparent 
                              : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat['emoji']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isSelected ? Colors.white : theme.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Upload Avatar Step (Slide 3)
  Widget _buildAvatarStep(dynamic theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add a profile picture',
            textAlign: TextAlign.center,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: theme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile with a high-quality picture so friends recognize you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.primaryStart,
                      width: 3,
                    ),
                    image: _avatarFile != null
                        ? DecorationImage(
                            image: FileImage(_avatarFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _avatarFile == null
                      ? Icon(
                          Icons.camera_alt_outlined,
                          size: 40,
                          color: theme.primaryStart,
                        )
                      : null,
                ),
                if (_avatarFile != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_avatarFile != null)
            TextButton(
              onPressed: _pickAvatar,
              child: Text(
                'Change Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryStart,
                ),
              ),
            ),
          const SizedBox(height: 100), // padding from bottom indicators
        ],
      ),
    );
  }
}
