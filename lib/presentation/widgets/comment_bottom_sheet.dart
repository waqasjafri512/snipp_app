import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/dare_provider.dart';
import '../../core/constants/app_constants.dart';

class CommentBottomSheet extends StatefulWidget {
  final int dareId;
  const CommentBottomSheet({super.key, required this.dareId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  int? _replyToCommentId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DareProvider>(context, listen: false).fetchComments(widget.dareId);
    });
  }

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final success = await Provider.of<DareProvider>(context, listen: false)
        .addComment(widget.dareId, content, parentId: _replyToCommentId);
    
    if (success) {
      _commentController.clear();
      setState(() {
        _replyToCommentId = null;
        _replyToUsername = null;
      });
    }
  }

  void _handleReply(int commentId, String username) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
    });
    _commentController.text = '@$username ';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Comments',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0EEFF)),
          
          Expanded(
            child: Consumer<DareProvider>(
              builder: (context, dareProv, child) {
                if (dareProv.isLoading && dareProv.comments.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryStart));
                }
                
                if (dareProv.comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Text(
                          'No comments yet.\nStart the conversation!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.muted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: dareProv.comments.length,
                  itemBuilder: (context, index) {
                    final comment = dareProv.comments[index];
                    return _buildCommentItem(comment);
                  },
                );
              },
            ),
          ),
          
          // Reply Indicator
          if (_replyToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: const Color(0xFFF2EFFF),
              child: Row(
                children: [
                  Text(
                    'Replying to ',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                  ),
                  Text(
                    '@$_replyToUsername',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryStart),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() { _replyToCommentId = null; _replyToUsername = null; }),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                  ),
                ],
              ),
            ),

          // Input Area
          SafeArea(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF0EEFF))),
              ),
              child: Row(
                children: [
                  _buildAvatar(99, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        fillColor: Color(0xFFF2EFFF),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _submitComment,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text('→', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    bool isReply = comment['parent_id'] != null;
    int idx = comment['id'] % 5;

    return Padding(
      padding: EdgeInsets.only(bottom: 16, left: isReply ? 40 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(idx, size: isReply ? 28 : 36),
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
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${comment['username']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.primaryStart,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comment['content'],
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
                      Text(
                        _getTimeAgo(comment['created_at']),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Provider.of<DareProvider>(context, listen: false).toggleCommentLike(comment['id']),
                        child: Text(
                          comment['is_liked'] == true ? '❤️ Liked' : '🤍 Like',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, 
                            color: comment['is_liked'] == true ? const Color(0xFFEF4444) : AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _handleReply(comment['id'], comment['username']),
                        child: Text(
                          'Reply',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, 
                            color: AppColors.primaryStart,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(int idx, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _getGradient(idx),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'U',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
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

  String _getTimeAgo(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final dateTime = DateTime.parse(timeStr);
      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'now';
    } catch (e) {
      return '';
    }
  }
}
