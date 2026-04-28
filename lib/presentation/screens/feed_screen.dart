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
import 'package:cached_network_image/cached_network_image.dart';
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


  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  void _loadFeed() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<DareProvider>(context, listen: false).fetchFeed(page: 1);
      Provider.of<LiveProvider>(context, listen: false).fetchActiveStreams();
      await Provider.of<StoryProvider>(context, listen: false).fetchStories();
      if (mounted) _precacheStories();
    });
  }

  void _precacheStories() {
    final stories = Provider.of<StoryProvider>(context, listen: false).stories;
    for (var userStory in stories) {
      final storyList = userStory['stories'] as List?;
      if (storyList != null) {
        for (var story in storyList) {
          if (story['media_url'] != null) {
            precacheImage(
              CachedNetworkImageProvider(AppConstants.getMediaUrl(story['media_url'])),
              context,
            );
          }
        }
      }
    }
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
                                  const SizedBox(width: 10),
                                  Consumer<NotificationProvider>(
                                    builder: (context, notifProv, _) => _buildHeaderIconButton(
                                      Icons.notifications_none_rounded,
                                      currentTheme,
                                      themeProv.currentThemeIndex == 1,
                                      hasNotification: notifProv.unreadCount > 0,
                                      notifCount: notifProv.unreadCount,
                                      onTap: () => Navigator.pushNamed(context, AppConstants.notificationsRoute),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildHeaderIconButton(
                                    Icons.live_tv_rounded,
                                    currentTheme,
                                    themeProv.currentThemeIndex == 1,
                                    onTap: () => _startLiveStream(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildStoriesList(currentTheme, themeProv.currentThemeIndex == 1),
                          const SizedBox(height: 10),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: currentTheme.textMain.withOpacity(0.05),
                          ),
                        ],
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

  Widget _buildHeaderIconButton(IconData icon, AppTheme theme, bool isDark, {bool hasNotification = false, int notifCount = 0, VoidCallback? onTap}) {
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
                top: 10,
                right: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444), // Solid red for dot
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

  Widget _buildStoriesList(dynamic theme, bool isDark) {
    return Consumer3<StoryProvider, AuthProvider, LiveProvider>(
      builder: (context, storyProv, authProv, liveProv, _) {
        final List<Map<String, dynamic>> items = [
          {
            'username': 'Add Story', 
            'isMe': true, 
            'avatar_url': authProv.user?['avatar_url']
          },
          ...liveProv.activeStreams.map((s) => {...s, 'isLive': true}),
          ...storyProv.stories.map((s) => {...s, 'isStory': true}),
        ];

        return Container(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final bool isLive = item['isLive'] == true;
              final bool isStory = item['isStory'] == true;
              final bool isMe = item['isMe'] == true;

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Card Background
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: item['avatar_url'] != null 
                          ? CachedNetworkImage(
                              imageUrl: AppConstants.getMediaUrl(item['avatar_url']),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: isDark ? Colors.white10 : Colors.grey[200]),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            )
                          : Container(color: isDark ? Colors.white10 : Colors.grey[200]),
                      ),
                      // Overlay Gradient
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // User Avatar (Top Left)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: (isLive || isStory) ? theme.gradient : null,
                            color: (isLive || isStory) ? null : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: item['avatar_url'] != null 
                              ? NetworkImage(AppConstants.getMediaUrl(item['avatar_url']))
                              : null,
                            child: item['avatar_url'] == null 
                              ? Text(item['username']?[0] ?? '?', style: const TextStyle(fontSize: 10))
                              : null,
                          ),
                        ),
                      ),
                      // "Add" Icon for Me
                      if (isMe)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add, color: theme.primaryStart, size: 24),
                          ),
                        ),
                      // Live Badge
                      if (isLive)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // Name Label
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Text(
                          isMe ? 'Add Story' : (item['username'] ?? 'User'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
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

  void _startLiveStream() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final channelName = 'stream_${authProv.user?['id']}';
    
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        String streamTitle = "${authProv.user?['username']}'s Live Stream";
        return AlertDialog(
          title: const Text('Go Live'),
          content: TextField(
            onChanged: (v) => streamTitle = v,
            decoration: const InputDecoration(hintText: 'Stream Title'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, streamTitle), child: const Text('Go Live')),
          ],
        );
      },
    );

    if (title != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BroadcasterScreen(
            channelName: channelName,
            title: title,
          ),
        ),
      );
    }
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
