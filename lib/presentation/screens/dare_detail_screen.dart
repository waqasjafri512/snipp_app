import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../widgets/gradient_button.dart';
import '../providers/auth_provider.dart';
import '../providers/dare_provider.dart';
import '../../data/repositories/api_service.dart';

class DareDetailScreen extends StatefulWidget {
  final Map<String, dynamic> dare;

  const DareDetailScreen({super.key, required this.dare});

  @override
  State<DareDetailScreen> createState() => _DareDetailScreenState();
}

class _DareDetailScreenState extends State<DareDetailScreen> {
  late Map<String, dynamic> dare;

  @override
  void initState() {
    super.initState();
    dare = widget.dare;
    _fetchComments();
  }

  void _fetchComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DareProvider>(context, listen: false).fetchComments(dare['id']);
    });
  }

  final _commentController = TextEditingController();

  void _handleSendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final success = await Provider.of<DareProvider>(context, listen: false).addComment(dare['id'], text);
    if (success) {
      _commentController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    }
  }

  Future<void> _uploadProof(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    try {
      final apiService = ApiService();
      final response = await apiService.uploadFile('/dares/upload-media', file.path, 'media');
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        final proofUrl = data['data']['mediaUrl'];
        final success = await Provider.of<DareProvider>(context, listen: false).completeDare(dare['id'], proofUrl);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Congratulations! Dare completed 🏆 Points added to your profile.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload proof.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Area
            Stack(
              children: [
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: _getGradient(dare['id'] ?? 0),
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
                          dare['emoji'] ?? '⚡',
                          style: const TextStyle(fontSize: 90),
                        )
                      : null,
                ),
                // Back Button
                Positioned(
                  top: 54,
                  left: 14,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                // Bottom Gradient Overlay to transition to BG
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Row(
                    children: [
                      _buildAvatar(dare),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dare['creator_name'] ?? dare['creator_username'] ?? 'User',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textMain,
                              ),
                            ),
                            Text(
                              '${dare['creator_followers_count'] ?? 0} followers · ${_getTimeAgo(dare['created_at'])}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildOutlineButton('Follow'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title & Description
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      dare['category'] ?? '🔥 Trending',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dare['title'] ?? 'Untitled Dare',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dare['description'] ?? "No description provided.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryStart.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildStatItem(Icons.favorite_rounded, (dare['likes_count'] ?? 0).toString(), 'Likes', iconColor: const Color(0xFFEF4444)),
                        _buildStatItem(Icons.chat_bubble_rounded, (dare['comments_count'] ?? 0).toString(), 'Comments', iconColor: const Color(0xFF0EA5E9)),
                        _buildStatItem(Icons.check_circle_rounded, (dare['accepts_count'] ?? 0).toString(), 'Accepts', iconColor: const Color(0xFF10B981)),
                        _buildStatItem(Icons.share_rounded, (dare['shares_count'] ?? 0).toString(), 'Shares', isLast: true, iconColor: const Color(0xFF7C3AED)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Accept Button
                  Consumer<DareProvider>(
                    builder: (context, dareProv, _) {
                      bool isAccepted = dare['is_accepted'] == true || dareProv.userParticipatedDares.any((d) => d['id'] == dare['id']);
                      
                      return GradientButton(
                        text: isAccepted ? '🎯 Already Accepted' : '🎯 Accept This Dare',
                        onPressed: isAccepted ? null : () async {
                          final success = await dareProv.acceptDare(dare['id']);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dare Accepted! Going Live... 🔥')),
                            );
                            
                            // Navigate to Live directly
                            Navigator.pushNamed(
                              context, 
                              '/broadcaster', 
                              arguments: {
                                'channelName': 'dare_perf_${dare['id']}_${DateTime.now().millisecondsSinceEpoch}',
                                'title': 'Performing: ${dare['title']}',
                                'dareId': dare['id'],
                              }
                            );
                          }
                        },
                        borderRadius: 20,
                        height: 64,
                        opacity: isAccepted ? 0.7 : 1.0,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Upload Proof Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryStart.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Already completed it?',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primaryStart,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload your video proof and claim credit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFullWidthOutlineButton(
                          'Upload Completion Video',
                          onTap: () => _uploadProof(context),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context, 
                              '/broadcaster', 
                              arguments: {
                                'channelName': 'dare_perf_${dare['id']}_${DateTime.now().millisecondsSinceEpoch}',
                                'title': 'Performing: ${dare['title']}',
                              }
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFF006E), Color(0xFFFB5607)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF006E).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sensors_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Perform Dare Live',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Comments Header
                  Text(
                    'Comments (${dare['comments_count'] ?? 0})',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Comments List
                  Consumer<DareProvider>(
                    builder: (context, dareProv, _) {
                      if (dareProv.comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No comments yet. Be the first to say something!',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.muted),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: dareProv.comments.map((comment) {
                          return _buildCommentItem(
                            comment['username'] ?? 'user',
                            comment['content'] ?? '',
                            _getTimeAgo(comment['created_at']),
                            comment['likes_count'] ?? 0,
                            comment['id'] % 5,
                            avatarUrl: comment['avatar_url'],
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // Add Comment
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildAvatarSmall(4),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _handleSendComment,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> dare) {
    return Container(
      width: 46,
      height: 46,
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
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildAvatarSmall(int idx, {String? avatarUrl, String? username}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: (avatarUrl == null) ? _getGradient(idx) : null,
        shape: BoxShape.circle,
        image: avatarUrl != null ? DecorationImage(
          image: NetworkImage(AppConstants.getMediaUrl(avatarUrl)),
          fit: BoxFit.cover,
        ) : null,
      ),
      alignment: Alignment.center,
      child: avatarUrl == null ? Text(
        (username ?? 'U')[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
      ) : null,
    );
  }

  String _getTimeAgo(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'now';
    try {
      final dateTime = DateTime.parse(timeStr);
      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w';
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'now';
    } catch (e) {
      return 'now';
    }
  }

  Widget _buildOutlineButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryStart.withOpacity(0.28), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.primaryStart,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFullWidthOutlineButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryStart.withOpacity(0.28), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryStart,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, {bool isLast = false, Color? iconColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(right: BorderSide(color: Color(0xFFF0EEFF), width: 1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primaryStart, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textMain,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(String user, String text, String time, int likes, int idx, {Map<String, dynamic>? reply, String? avatarUrl}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarSmall(idx, avatarUrl: avatarUrl, username: user),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$user',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.primaryStart,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textMain,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                      const SizedBox(width: 14),
                      Icon(Icons.favorite_rounded, size: 12, color: const Color(0xFFEF4444).withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text('$likes', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 14),
                      Text('Reply', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.primaryStart, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (reply != null) ...[
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      _buildAvatarSmall(reply['idx']),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${reply['user']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.primaryStart,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reply['text'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
