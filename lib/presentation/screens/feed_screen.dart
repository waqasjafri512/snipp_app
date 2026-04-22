import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/dare_provider.dart';
import '../providers/live_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/story_provider.dart';
import '../providers/notification_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/dare_card.dart';
import '../../core/constants/app_constants.dart';
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
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                                        color: AppColors.muted,
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
                                    color: AppColors.textMain,
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
                                onTap: () => Navigator.pushNamed(context, AppConstants.searchRoute),
                              ),
                              const SizedBox(width: 8),
                              Consumer<NotificationProvider>(
                                builder: (context, notifProv, _) => _buildHeaderIconButton(
                                  Icons.notifications_none_rounded,
                                  hasNotification: notifProv.unreadCount > 0,
                                  onTap: () => Navigator.pushNamed(context, AppConstants.notificationsRoute),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderIconButton(
                                Icons.chat_bubble_outline_rounded,
                                onTap: () {
                                  // Navigate to chat tab or screen
                                  // Since HomeScreen handles tabs, we can either navigate to a separate screen 
                                  // or use a callback to change the index. 
                                  // For simplicity and immediate access, navigating to ChatListScreen directly is good.
                                  Navigator.pushNamed(context, AppConstants.chatListRoute);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildStoriesList(),
                    ],
                  ),
                ),
              ),

              // Category Chips
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedChip == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedChip = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.primaryGradient : null,
                            color: isSelected ? null : const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.primaryStart.withOpacity(0.3),
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
                              color: isSelected ? Colors.white : AppColors.primaryStart,
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
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryStart)),
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
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryStart)),
                                ) 
                              : const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: DareCard(dare: dareProv.feedDares[index]),
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
  }

  Widget _buildHeaderIconButton(IconData icon, {bool hasNotification = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EFFF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.textMain),
            if (hasNotification)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryEnd,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList() {
    return Consumer2<LiveProvider, StoryProvider>(
      builder: (context, liveProv, storyProv, _) {
        final List<Map<String, dynamic>> items = [
          {'username': 'You', 'isMe': true},
          ...liveProv.activeStreams.map((s) => {...s, 'isLive': true}),
          ...storyProv.stories.map((s) => {...s, 'isStory': true}),
        ];

        return Container(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    if (item['isMe'] == true) {
                      _pickStoryMedia();
                    } else if (item['isLive'] == true) {
                      // Watch Stream
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
                    } else if (item['isStory'] == true) {
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
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: item['isLive'] == true ? AppColors.primaryGradient : null,
                          color: item['isLive'] == true ? null : Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: _getGradient(index),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item['username'][0].toUpperCase(),
                              style: GoogleFonts.bricolageGrotesque(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        index == 0 ? '+ Add' : (item['full_name'] ?? item['username']),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
