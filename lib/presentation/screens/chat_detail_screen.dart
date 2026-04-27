import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';

class ChatDetailScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchChatHistory(widget.otherUserId);
    });
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final chatProv = Provider.of<ChatProvider>(context, listen: false);

    chatProv.sendMessage(authProv.user!['id'], widget.otherUserId, text);
    _messageController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).clearActiveChat();
    });
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user!['id'];

    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: theme.primaryStart, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                _buildAvatar(
                  widget.otherUserId % 5,
                  theme,
                  isDark,
                  size: 40,
                  isOnline: true,
                  avatarUrl: widget.otherUserAvatar,
                  initial: widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: theme.textMain,
                      ),
                    ),
                    Text(
                      '● Active now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting Audio Call...'))),
                child: _buildPremiumHeaderIcon(Icons.call_outlined, theme, isDark),
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting Video Call...'))),
                child: _buildPremiumHeaderIcon(Icons.videocam_outlined, theme, isDark),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF0EEFF)),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProv, child) {
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: chatProv.messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == chatProv.messages.length) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Today',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }
                        final msg = chatProv.messages[index];
                        final isMe = msg['sender_id'] == currentUserId;
                        return _buildMessageBubble(msg['content'], isMe, "2:15 PM", theme, isDark);
                      },
                    );
                  },
                ),
              ),
              
              // Message Input
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: theme.background,
                    border: Border(top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF0EEFF))),
                  ),
                  child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File upload feature coming soon! 📎'))),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF0EEFF)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.add_rounded, color: theme.primaryStart, size: 26),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: (v) => setState(() {}),
                        style: TextStyle(color: theme.textMain),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: isDark ? Colors.white24 : AppColors.muted),
                          fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF4F4F6),
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    if (_messageController.text.isNotEmpty)
                      GestureDetector(
                        onTap: _handleSend,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: theme.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryStart.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF0EEFF)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.mic_none_rounded, color: isDark ? Colors.white54 : AppColors.muted, size: 24),
                      ),
                  ],
                ),
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumHeaderIcon(IconData icon, AppTheme theme, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF0EEFF)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: theme.textMain),
    );
  }

  Widget _buildAvatar(int idx, AppTheme theme, bool isDark, {double size = 40, bool isOnline = false, String? avatarUrl, String initial = 'U'}) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: (avatarUrl == null || avatarUrl.isEmpty) ? _getGradient(idx) : null,
            color: (avatarUrl == null || avatarUrl.isEmpty) ? null : (isDark ? Colors.white10 : Colors.grey[200]),
            shape: BoxShape.circle,
            image: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(AppConstants.getMediaUrl(avatarUrl)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.38,
                  ),
                )
              : null,
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

  Widget _buildMessageBubble(String text, bool isMe, String time, AppTheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(
              widget.otherUserId % 5,
              theme,
              isDark,
              size: 28,
              avatarUrl: widget.otherUserAvatar,
              initial: widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? theme.gradient : null,
                color: isMe ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      color: isMe ? Colors.white : theme.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: isMe ? Colors.white.withOpacity(0.7) : (isDark ? Colors.white54 : AppColors.muted),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 32),
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
