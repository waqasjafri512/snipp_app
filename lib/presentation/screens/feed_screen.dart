import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/dare_provider.dart';
import '../providers/live_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/story_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../widgets/staggered_animation.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/dare_card.dart';
import 'dare_detail_screen.dart';
import 'story_viewer_screen.dart';
import 'viewer_screen.dart';
import 'broadcaster_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  int _selectedChip = 0;

  final List<String> _categories = ["🔥 Trending", "💪 Fitness", "😂 Funny", "🎨 Creative", "🌊 Outdoors", "🍕 Food"];

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  void _loadFeed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DareProvider>(context, listen: false).fetchFeed(page: 1);
      Provider.of<LiveProvider>(context, listen: false).fetchActiveStreams();
      Provider.of<StoryProvider>(context, listen: false).fetchStories();
    });
  }

  Future<void> _pickStoryMedia() async {
    final picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Story', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 80);
    
    if (file != null && mounted) {
      final success = await Provider.of<StoryProvider>(context, listen: false).uploadStory(file.path);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story uploaded! 📸')),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _currentPage++;
      Provider.of<DareProvider>(context, listen: false).fetchFeed(page: _currentPage);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final currentTheme = themeProv.currentTheme;
        
        return Scaffold(
          backgroundColor: currentTheme.background,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                _currentPage = 1;
                await Provider.of<DareProvider>(context, listen: false).fetchFeed(page: 1);
                await Provider.of<StoryProvider>(context, listen: false).fetchStories();
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Sticky Header
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Consumer<AuthProvider>(
                                      builder: (context, authProv, _) {
                                        final name = authProv.user?['full_name']?.split(' ')[0] ?? 'User';
                                        return Text(
                                          'Hey $name! 👋',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: themeProv.currentThemeIndex == 1 ? Colors.white70 : AppColors.muted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                    Text(
                                      'Explore Dares',
                                      style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: currentTheme.textMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  _buildHeaderIconButton(
                                    Icons.search_rounded,
                                    currentTheme,
                                    themeProv.currentThemeIndex == 1,
                                    onTap: () => Navigator.pushNamed(context, AppConstants.searchRoute),
                                  ),
                                  const SizedBox(width: 8),
                                  Consumer<NotificationProvider>(
                                    builder: (context, notifProv, _) => _buildHeaderIconButton(
                                      Icons.notifications_none_rounded,
                                      currentTheme,
                                      themeProv.currentThemeIndex == 1,
                                      hasNotification: notifProv.unreadCount > 0,
                                      onTap: () => Navigator.pushNamed(context, AppConstants.notificationsRoute),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeaderIconButton(
                                    Icons.chat_bubble_outline_rounded,
                                    currentTheme,
                                    themeProv.currentThemeIndex == 1,
                                    onTap: () {
                                      Navigator.pushNamed(context, AppConstants.chatListRoute);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildStoriesList(currentTheme, themeProv.currentThemeIndex == 1),
                        ],
                      ),
                    ),
                  ),

                  // Category Chips
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          bool isSelected = _selectedChip == index;
                          final isDark = themeProv.currentThemeIndex == 1;
                          
                          return GestureDetector(
                            onTap: () => setState(() => _selectedChip = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: isSelected ? currentTheme.gradient : null,
                                color: isSelected ? null : (isDark ? Colors.white10 : const Color(0xFFEDE9FE)),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: currentTheme.primaryStart.withOpacity(0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ] : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _categories[index],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : currentTheme.primaryStart,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Feed
                  Consumer<DareProvider>(
                    builder: (context, dareProv, child) {
                      if (dareProv.isLoading && dareProv.feedDares.isEmpty) {
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => const DareCardShimmer(),
                              childCount: 3,
                            ),
                          ),
                        );
                      }

                      if (dareProv.feedDares.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('No dares yet. Create one!'),
                                TextButton(onPressed: _loadFeed, child: const Text('Refresh')),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == dareProv.feedDares.length) {
                                return dareProv.isLoading 
                                  ? const DareCardShimmer()
                                  : const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: StaggeredListAnimation(
                                  index: index,
                                  child: DareCard(dare: dareProv.feedDares[index]),
                                ),
                              );
                            },
                            childCount: dareProv.feedDares.length + 1,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderIconButton(IconData icon, AppTheme theme, bool isDark, {bool hasNotification = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF2EFFF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: theme.textMain),
            if (hasNotification)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primaryEnd,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.background, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList(AppTheme theme, bool isDark) {
    return Consumer3<LiveProvider, StoryProvider, AuthProvider>(
      builder: (context, liveProv, storyProv, authProv, _) {
        final List<Map<String, dynamic>> items = [
          {
            'username': 'Your Story', 
            'isMe': true, 
            'avatar_url': authProv.user?['avatar_url']
          },
          ...liveProv.activeStreams.map((s) => {...s, 'isLive': true}),
          ...storyProv.stories.map((s) => {...s, 'isStory': true}),
        ];

        return Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final bool isLive = item['isLive'] == true;
              final bool isStory = item['isStory'] == true;
              final bool isMe = item['isMe'] == true;

              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    if (isMe) {
                      _pickStoryMedia();
                    } else if (isLive) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewerScreen(
                            broadcasterId: item['user_id'] ?? item['creator_id'] ?? 0,
                            channelName: item['channel_name'] ?? '',
                            broadcasterName: item['username'] ?? 'Live User',
                          ),
                        ),
                      );
                    } else if (isStory) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoryViewerScreen(userStories: item),
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              gradient: (isLive || isStory) ? theme.gradient : null,
                              color: (isLive || isStory) ? null : (isDark ? Colors.white12 : Colors.grey.withOpacity(0.15)),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.background,
                                shape: BoxShape.circle,
                              ),
                              child: _buildStoryAvatar(item, index, theme),
                            ),
                          ),
                          if (isMe)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: theme.background,
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: theme.gradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          if (isLive)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFFF006E), Color(0xFFFB5607)]),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          isMe ? 'Your Story' : (item['username'] ?? 'User'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: theme.textMain,
                            fontWeight: isMe || isLive || isStory ? FontWeight.w700 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStoryAvatar(Map<String, dynamic> item, int index, AppTheme theme) {
    final avatar = item['avatar_url'];
    if (avatar != null && avatar.isNotEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(AppConstants.getMediaUrl(avatar)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: _getGradient(index),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        (item['username'] ?? 'U')[0].toUpperCase(),
        style: GoogleFonts.bricolageGrotesque(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }

  LinearGradient _getGradient(int id) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
      const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF7C3AED)]),
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0EA5E9)]),
      const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF59E0B)]),
    ];
    return gradients[id % gradients.length];
  }
}
