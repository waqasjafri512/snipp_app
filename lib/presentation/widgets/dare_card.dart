import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/dare_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import 'comment_bottom_sheet.dart';
import '../screens/chat_detail_screen.dart';

class DareCard extends StatelessWidget {
  final Map<String, dynamic> dare;
  const DareCard({super.key, required this.dare});

  @override
  Widget build(BuildContext context) {
    final bool isCompletion = dare['post_type'] == 'completion';
    final bool isGeneral = dare['actual_post_type'] == 'general';
    final String displayName = isCompletion 
        ? (dare['solver_full_name'] ?? dare['solver_username'] ?? 'User') 
        : (dare['creator_full_name'] ?? dare['creator_name'] ?? dare['creator_username'] ?? 'User');

    final bool hasMedia = dare['media_url'] != null;

    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Container(
          color: theme.background,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header (Facebook Style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: displayName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: theme.textMain,
                                    ),
                                  ),
                                  if (dare['creator_verified'] == true) ...[
                                    const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.verified, color: Colors.blue, size: 14),
                                      ),
                                    ),
                                  ],
                                  if (isCompletion)
                                    TextSpan(
                                      text: ' completed a dare.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : Colors.grey[700],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    )
                                  else if (isGeneral)
                                    TextSpan(
                                      text: ' updated their status.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : Colors.grey[700],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _getTimeAgo(dare['created_at']),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.public, size: 12, color: isDark ? Colors.white54 : Colors.grey[600]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildFollowButton(context, theme, isDark),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.white54 : Colors.grey[600]),
                      padding: EdgeInsets.zero,
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                        } else if (value == 'hide' || value == 'report') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(value == 'hide' ? 'Post hidden' : 'Post reported')),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'hide',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off_outlined, size: 18, color: theme.textMain),
                              const SizedBox(width: 10),
                              Text('Hide Post', style: TextStyle(color: theme.textMain)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'message',
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 18, color: theme.textMain),
                              const SizedBox(width: 10),
                              Text('Message', style: TextStyle(color: theme.textMain)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 18, color: theme.textMain),
                              const SizedBox(width: 10),
                              Text('View Profile', style: TextStyle(color: theme.textMain)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, color: Colors.red, size: 18),
                              const SizedBox(width: 10),
                              Text('Report', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 2. Text Content (Before Media)
              if (hasMedia || !isGeneral) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dare['title'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textMain,
                        ),
                      ),
                      if (dare['description'] != null && dare['description'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dare['description'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: theme.textMain,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // 3. Media Content
              if (hasMedia)
                GestureDetector(
                  onDoubleTap: () => _handleLike(context),
                  child: Image.network(
                    AppConstants.getMediaUrl(dare['media_url']),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: isDark ? Colors.white10 : Colors.grey[200],
                      child: const Center(child: Icon(Icons.error_outline)),
                    ),
                  ),
                )
              else if (!hasMedia && !isGeneral)
                // Dare without media (using emoji/gradient)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: theme.gradient.withOpacity(0.1) as Gradient,
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dare['emoji'] ?? '🔥',
                    style: const TextStyle(fontSize: 80),
                  ),
                )
              else if (!hasMedia && isGeneral)
                // Facebook style text-only post
                Container(
                  constraints: const BoxConstraints(minHeight: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  decoration: BoxDecoration(
                    gradient: isDark 
                      ? LinearGradient(colors: [theme.primaryStart, theme.primaryEnd.withOpacity(0.5)])
                      : LinearGradient(
                          colors: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)], // FB-ish Blue gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dare['title'] ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),

              // "Accept Dare" CTA if it's an actionable dare
              if (!isGeneral && !isCompletion) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: dare['is_accepted'] != true
                      ? GestureDetector(
                          onTap: () => Provider.of<DareProvider>(context, listen: false).acceptDare(dare['id']),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_esports_rounded, size: 18, color: theme.textMain),
                                const SizedBox(width: 8),
                                Text(
                                  'Accept Dare',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: theme.textMain,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'DARE ACCEPTED',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF10B981),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],

              // 4. Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    if ((dare['likes_count'] ?? 0) > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.thumb_up_rounded, color: Colors.white, size: 10),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dare['likes_count']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if ((dare['comments_count'] ?? 0) > 0) ...[
                      GestureDetector(
                        onTap: () => _showComments(context),
                        child: Text(
                          '${dare['comments_count']} comments',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500]),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '12 shares', // Hardcoded for aesthetics, no share tracking yet
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.grey[300]),

              // 5. Action Buttons (Like, Comment, Share)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFBActionButton(
                        icon: dare['is_liked'] == true ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                        label: 'Like',
                        color: dare['is_liked'] == true ? Colors.blue : (isDark ? Colors.white70 : Colors.grey[700]!),
                        onTap: () => _handleLike(context),
                      ),
                    ),
                    Expanded(
                      child: _buildFBActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Comment',
                        color: isDark ? Colors.white70 : Colors.grey[700]!,
                        onTap: () => _showComments(context),
                      ),
                    ),
                    Expanded(
                      child: _buildFBActionButton(
                        icon: Icons.reply_rounded, // Best fit for Share in Material Icons
                        label: 'Share',
                        color: isDark ? Colors.white70 : Colors.grey[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share functionality coming soon! 🚀')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom separator (Facebook gray thick divider between posts)
              Container(height: 6, color: isDark ? Colors.black : const Color(0xFFC9CCD1)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFBActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> dare) {
    final String initial = (dare['creator_full_name'] ?? dare['creator_username'] ?? 'U')[0].toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
        image: (dare['creator_avatar'] != null && dare['creator_avatar'].isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(AppConstants.getMediaUrl(dare['creator_avatar'])),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: (dare['creator_avatar'] == null || dare['creator_avatar'].isEmpty)
          ? Text(
              initial,
              style: GoogleFonts.bricolageGrotesque(
                color: Colors.black54,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            )
          : null,
    );
  }

  Widget _buildFollowButton(BuildContext context, AppTheme theme, bool isDark) {
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
        
        if (isFollowing) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => profileProv.toggleFollow(targetId),
          child: Text(
            '• Follow',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
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

  String _getTimeAgo(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timeStr);
      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays > 7) return '${(diff.inDays / 7).floor()} w';
      if (diff.inDays > 0) return '${diff.inDays} d';
      if (diff.inHours > 0) return '${diff.inHours} h';
      if (diff.inMinutes > 0) return '${diff.inMinutes} m';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }
}
