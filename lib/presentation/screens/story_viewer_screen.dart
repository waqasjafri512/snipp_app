import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/story_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';

class StoryViewerScreen extends StatefulWidget {
  final Map<String, dynamic> userStories;

  const StoryViewerScreen({super.key, required this.userStories});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _startStory();
  }

  void _startStory() {
    _progressController.stop();
    _progressController.reset();

    // Mark as viewed
    final stories = widget.userStories['stories'] as List;
    final currentStory = stories[_currentIndex];
    Provider.of<StoryProvider>(context, listen: false).viewStory(currentStory['id']);

    _progressController.forward().whenComplete(() {
      if (mounted) _nextStory();
    });
  }

  void _nextStory() {
    final stories = widget.userStories['stories'] as List;
    if (_currentIndex < stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startStory();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.userStories['stories'] as List;
    final currentStory = stories[_currentIndex];
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final isMe = currentStory['user_id'] == authProv.user?['id'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Content
          GestureDetector(
            onTapDown: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < width / 3) {
                _previousStory();
              } else {
                _nextStory();
              }
            },
            onLongPressDown: (_) => _progressController.stop(),
            onLongPressUp: () => _progressController.forward(),
            onLongPressCancel: () => _progressController.forward(),
            child: Center(
              child: CachedNetworkImage(
                imageUrl: AppConstants.getMediaUrl(currentStory['media_url']),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white24),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),

          // Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Progress indicators
                  Row(
                    children: List.generate(
                      stories.length,
                      (index) => Expanded(
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            double fillAmount = 0.0;
                            if (index < _currentIndex) {
                              fillAmount = 1.0;
                            } else if (index == _currentIndex) {
                              fillAmount = _progressController.value;
                            }

                            return Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: fillAmount,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: widget.userStories['avatar_url'] != null
                            ? NetworkImage(AppConstants.getMediaUrl(widget.userStories['avatar_url']))
                            : null,
                        child: widget.userStories['avatar_url'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.userStories['username'] ?? 'User',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (isMe)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          onPressed: () => _confirmDelete(context, currentStory['id']),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: isMe 
                  ? _buildOwnerBottomBar(currentStory)
                  : _buildViewerBottomBar(currentStory),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerBottomBar(Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () => _showViewers(story['id']),
      child: Center(
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '${story['views_count'] ?? 0} Viewers',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewerBottomBar(Map<String, dynamic> story) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Send message...',
              style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildReactionButton('🔥', story['id']),
        const SizedBox(width: 8),
        _buildReactionButton('❤️', story['id']),
        const SizedBox(width: 8),
        _buildReactionButton('😂', story['id']),
      ],
    );
  }

  Widget _buildReactionButton(String emoji, int storyId) {
    return GestureDetector(
      onTap: () async {
        final success = await Provider.of<StoryProvider>(context, listen: false).reactToStory(storyId, emoji);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reacted with $emoji'), duration: const Duration(milliseconds: 500), behavior: SnackBarBehavior.floating)
          );
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  void _showViewers(int storyId) async {
    _progressController.stop();
    
    final interactions = await Provider.of<StoryProvider>(context, listen: false).getStoryInteractions(storyId);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Story Viewers', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: interactions == null || (interactions['viewers'] as List).isEmpty
                ? Center(child: Text('No views yet', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: (interactions['viewers'] as List).length,
                    itemBuilder: (context, index) {
                      final viewer = interactions['viewers'][index];
                      final reaction = (interactions['reactions'] as List).firstWhere(
                        (r) => r['user_id'] == viewer['id'],
                        orElse: () => null,
                      );
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: viewer['avatar_url'] != null ? NetworkImage(AppConstants.getMediaUrl(viewer['avatar_url'])) : null,
                          child: viewer['avatar_url'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(viewer['full_name'] ?? viewer['username'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        trailing: reaction != null ? Text(reaction['emoji'], style: const TextStyle(fontSize: 20)) : null,
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _progressController.forward());
  }

  void _confirmDelete(BuildContext context, int storyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Delete Story?', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this story?', style: GoogleFonts.plusJakartaSans(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<StoryProvider>(context, listen: false).deleteStory(storyId);
              if (success && mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close viewer
              }
            },
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

