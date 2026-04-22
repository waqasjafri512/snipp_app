import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/story_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';

class StoryViewerScreen extends StatefulWidget {
  final Map<String, dynamic> userStories;

  const StoryViewerScreen({super.key, required this.userStories});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentIndex = 0;

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
                // Previous
                if (_currentIndex > 0) {
                  setState(() => _currentIndex--);
                }
              } else {
                // Next
                if (_currentIndex < stories.length - 1) {
                  setState(() => _currentIndex++);
                } else {
                  Navigator.pop(context);
                }
              }
            },
            child: Center(
              child: Image.network(
                AppConstants.getMediaUrl(currentStory['media_url']),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
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
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index <= _currentIndex ? Colors.white : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
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
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int storyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story?'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<StoryProvider>(context, listen: false).deleteStory(storyId);
              if (success && mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close viewer
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
