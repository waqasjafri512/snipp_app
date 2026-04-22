import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      if (authProv.user != null) {
        final chatProv = Provider.of<ChatProvider>(context, listen: false);
        chatProv.initSocket(authProv.user!['id']);
        chatProv.fetchConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withOpacity(0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages 💬',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.muted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
                      fillColor: const Color(0xFFF2EFFF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProv, child) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Active Conversations
                      if (chatProv.conversations.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                          child: Text(
                            'RECENT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: chatProv.conversations.length,
                            itemBuilder: (context, index) {
                              final conv = chatProv.conversations[index];
                              final displayName = conv['full_name'] ?? conv['username'] ?? 'User';
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(
                                        otherUserId: conv['other_user_id'],
                                        otherUserName: displayName,
                                        otherUserAvatar: conv['avatar_url'],
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Column(
                                    children: [
                                      _buildAvatarWithStatus(conv['other_user_id'] ?? index, isOnline: true, size: 52, initial: displayName[0].toUpperCase()),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 56,
                                        child: Text(
                                          displayName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Conversations List
                      if (chatProv.isLoading && chatProv.conversations.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppColors.primaryStart),
                        ))
                      else if (chatProv.conversations.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No messages yet'),
                        ))
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: chatProv.conversations.map((conv) => _buildChatItem(conv)).toList(),
                          ),
                        ),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithStatus(int idx, {bool isOnline = false, double size = 40, String initial = ''}) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: _getGradient(idx),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial.isNotEmpty ? initial : 'U',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.38,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatItem(Map<String, dynamic> conv) {
    bool isUnread = conv['is_read'] == false;
    int idx = conv['other_user_id'] % 5;

    final displayName = conv['full_name'] ?? conv['username'] ?? 'User';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              otherUserId: conv['other_user_id'],
              otherUserName: displayName,
              otherUserAvatar: conv['avatar_url'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2EFFF))),
        ),
        child: Row(
          children: [
            _buildAvatarWithStatus(idx, isOnline: true, size: 52, initial: displayName[0].toUpperCase()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        _getTimeAgo(conv['last_message_time']),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isUnread ? AppColors.primaryStart : AppColors.muted,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conv['last_message'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${conv['unread_count'] ?? 1}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ],
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
