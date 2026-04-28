import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/staggered_animation.dart';
import 'chat_detail_screen.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      if (authProv.user != null) {
        final chatProv = Provider.of<ChatProvider>(context, listen: false);
        final groupProv = Provider.of<GroupProvider>(context, listen: false);
        chatProv.initSocket(authProv.user!['id']);
        await chatProv.fetchConversations();
        
        // REST fallback for presence on Vercel
        final userIds = chatProv.conversations
            .map((c) => c['other_user_id'] as int?)
            .whereType<int>()
            .toList();
        if (userIds.isNotEmpty) {
          chatProv.fetchOnlineStatuses(userIds);
        }
        
        groupProv.fetchGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  decoration: BoxDecoration(
                    color: theme.background,
                    boxShadow: isDark ? null : [
                      BoxShadow(
                        color: theme.primaryStart.withOpacity(0.07),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isDark ? Border(bottom: BorderSide(color: Colors.white10)) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages 💬',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: theme.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: TextStyle(color: theme.textMain),
                        decoration: InputDecoration(
                          hintText: 'Search messages...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white24 : AppColors.muted, fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white24 : AppColors.muted, size: 22),
                          fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2EFFF),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                                  color: isDark ? Colors.white54 : AppColors.muted,
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
                                          _buildAvatarWithStatus(
                                            conv['other_user_id'] ?? index, 
                                            theme, 
                                            isDark, 
                                            isOnline: chatProv.isUserOnline(conv['other_user_id']), 
                                            size: 52, 
                                            initial: displayName[0].toUpperCase()
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 56,
                                            child: Text(
                                              displayName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                color: isDark ? Colors.white70 : AppColors.muted,
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
                            Center(child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: theme.primaryStart),
                            ))
                          else if (chatProv.conversations.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: theme.primaryStart.withOpacity(0.5)),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No messages yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: theme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start a conversation or create a new group to chat with your friends.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: isDark ? Colors.white54 : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: chatProv.conversations.asMap().entries.map((entry) {
                                  return StaggeredListAnimation(
                                    index: entry.key,
                                    child: _buildChatItem(entry.value, theme, isDark, chatProv),
                                  );
                                }).toList(),
                              ),
                            ),

                          // Groups Section
                          Consumer<GroupProvider>(
                            builder: (context, groupProv, child) {
                              if (groupProv.groups.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                                    child: Text(
                                      'GROUPS',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white54 : AppColors.muted,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Column(
                                      children: groupProv.groups.asMap().entries.map((entry) {
                                        return StaggeredListAnimation(
                                          index: entry.key + chatProv.conversations.length,
                                          child: _buildGroupItem(entry.value, theme, isDark),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              );
                            },
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
              );
            },
            backgroundColor: theme.primaryStart,
            icon: const Icon(Icons.group_add_rounded, color: Colors.white),
            label: Text('New Group', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildAvatarWithStatus(int idx, AppTheme theme, bool isDark, {bool isOnline = false, double size = 40, String initial = ''}) {
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
                border: Border.all(color: theme.background, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatItem(Map<String, dynamic> conv, AppTheme theme, bool isDark, ChatProvider chatProv) {
    bool isUnread = (conv['unread_count'] ?? 0) > 0;
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
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF2EFFF))),
        ),
        child: Row(
          children: [
            _buildAvatarWithStatus(idx, theme, isDark, isOnline: chatProv.isUserOnline(conv['other_user_id']), size: 52, initial: displayName[0].toUpperCase()),
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
                          color: theme.textMain,
                        ),
                      ),
                      Text(
                        _getTimeAgo(conv['last_message_time']),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isUnread ? theme.primaryStart : (isDark ? Colors.white54 : AppColors.muted),
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
                      color: isDark ? Colors.white54 : AppColors.muted,
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
                  gradient: theme.gradient,
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

  Widget _buildGroupItem(Map<String, dynamic> group, AppTheme theme, bool isDark) {
    int idx = group['id'] % 5;
    final displayName = group['name'] ?? 'Group';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(
              groupId: group['id'],
              groupName: displayName,
              groupAvatar: group['avatar_url'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF2EFFF))),
        ),
        child: Row(
          children: [
            _buildAvatarWithStatus(idx, theme, isDark, isOnline: false, size: 52, initial: displayName[0].toUpperCase()),
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
                          color: theme.textMain,
                        ),
                      ),
                      Text(
                        _getTimeAgo(group['last_message_time']),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : AppColors.muted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    group['last_message'] ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
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
