import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/dare_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'comment_bottom_sheet.dart';
import '../screens/chat_detail_screen.dart';

class DareCard extends StatelessWidget {
  final Map<String, dynamic> dare;
  const DareCard({super.key, required this.dare});

  @override
  Widget build(BuildContext context) {
    final bool isCompletion = dare['post_type'] == 'completion';
    final String displayUsername = isCompletion ? (dare['solver_username'] ?? 'user') : (dare['creator_username'] ?? 'user');
    final String displayName = isCompletion ? (dare['solver_username'] ?? 'User') : (dare['creator_name'] ?? dare['creator_username'] ?? 'User');

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppConstants.profileRoute, arguments: dare['creator_id']),
                  child: _buildAvatar(dare),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppConstants.profileRoute, arguments: dare['creator_id']),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.textMain,
                              ),
                            ),
                            if (dare['creator_verified'] == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 14),
                            ],
                          ],
                        ),
                        if (isCompletion)
                          Text(
                            'Completed a dare',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _buildFollowButton(context),
                const SizedBox(width: 8),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.muted, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'message') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            otherUserId: dare['creator_id'],
                            otherUserName: dare['creator_username'] ?? 'User',
                            otherUserAvatar: dare['creator_avatar'],
                          ),
                        ),
                      );
                    } else if (value == 'profile') {
                      Navigator.pushNamed(context, AppConstants.profileRoute, arguments: dare['creator_id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'message',
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Message'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, color: Colors.red, size: 18),
                          SizedBox(width: 10),
                          Text('Report', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Media Area (Full Width)
          GestureDetector(
            onDoubleTap: () => _handleLike(context),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1, // Square for standard feed
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      image: dare['media_url'] != null
                          ? DecorationImage(
                              image: NetworkImage(AppConstants.getMediaUrl(dare['media_url'])),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: dare['media_url'] == null
                        ? Text(
                            dare['emoji'] ?? '🔥',
                            style: const TextStyle(fontSize: 80),
                          )
                        : null,
                  ),
                ),
                // Difficulty / Type Tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompletion ? Icons.play_circle_outline : Icons.bolt_rounded, 
                          color: Colors.white, 
                          size: 14
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompletion ? 'RESPONSE' : (dare['difficulty']?.toUpperCase() ?? 'DARE'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Actions & Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Interaction Bar
                Row(
                  children: [
                    _buildInteractionIcon(
                      icon: dare['is_liked'] == true ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: dare['is_liked'] == true ? const Color(0xFFEF4444) : AppColors.textMain,
                      onTap: () => _handleLike(context),
                    ),
                    const SizedBox(width: 16),
                    _buildInteractionIcon(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: AppColors.textMain,
                      onTap: () => _showComments(context),
                    ),
                    const SizedBox(width: 16),
                    _buildInteractionIcon(
                      icon: Icons.send_rounded,
                      color: AppColors.textMain,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share functionality coming soon! 🚀')),
                        );
                      },
                    ),
                    const Spacer(),
                    _buildInteractionIcon(
                      icon: Icons.bookmark_border_rounded,
                      color: AppColors.textMain,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to your collection! 🔖')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Liked by
                Text(
                  '${dare['likes_count'] ?? 0} likes',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),

                // Caption
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textMain),
                    children: [
                      TextSpan(
                        text: '$displayUsername ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: dare['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (dare['description'] != null && dare['description'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dare['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textMain.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: Text(
                    'View all ${dare['comments_count'] ?? 0} comments',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (!isCompletion && dare['is_accepted'] != true)
                  GestureDetector(
                    onTap: () => Provider.of<DareProvider>(context, listen: false).acceptDare(dare['id']),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryStart.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Accept Dare 🎯',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (!isCompletion && dare['is_accepted'] == true)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'DARE ACCEPTED',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  _getTimeAgo(dare['created_at']),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: AppColors.muted.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> dare) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: _getGradient(dare['id'] ?? 0),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        (dare['creator_username'] ?? 'U')[0].toUpperCase(),
        style: GoogleFonts.bricolageGrotesque(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final targetId = dare['post_type'] == 'completion' ? dare['solver_id'] : dare['creator_id'];
    
    if (targetId == null || targetId == authProv.user?['id']) return const SizedBox.shrink();

    return Consumer<ProfileProvider>(
      builder: (context, profileProv, _) {
        final isFollowing = profileProv.isFollowing(
          targetId, 
          fallback: dare['post_type'] == 'completion' 
            ? (dare['is_following_solver'] ?? false) 
            : (dare['is_following_creator'] ?? false)
        );
        
        return GestureDetector(
          onTap: () => profileProv.toggleFollow(targetId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.transparent : AppColors.primaryStart.withOpacity(0.08),
              border: isFollowing ? Border.all(color: AppColors.muted.withOpacity(0.3)) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: GoogleFonts.plusJakartaSans(
                color: isFollowing ? AppColors.muted : Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 26),
    );
  }

  void _handleLike(BuildContext context) {
    Provider.of<DareProvider>(context, listen: false).toggleLike(dare['id']);
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(dareId: dare['id']),
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

  String _getTimeAgo(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timeStr);
      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w';
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }
}
