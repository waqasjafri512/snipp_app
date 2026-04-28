import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../data/services/socket_service.dart';
import 'call_screen.dart';

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
  
  late StreamSubscription _socketSub;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _socketSub = SocketService().eventStream.listen(_onSocketEvent);
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // 1. Try socket check (local/non-vercel)
    SocketService().emit('checkUserStatus', widget.otherUserId);
    
    // 2. REST fallback
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProv.apiService.get('/messages/user-status/${widget.otherUserId}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      if (mounted) {
        setState(() {
          if (data['lastSeen'] != null) {
            _lastSeen = DateTime.parse(data['lastSeen']).toLocal();
          }
          // The ChatProvider will be updated by Consumers
        });
      }
    }
  }

  void _onSocketEvent(Map<String, dynamic> event) {
    if (event['event'] == 'userStatus') {
      final data = event['data'];
      if (data['userId'] == widget.otherUserId) {
        if (mounted) {
          setState(() {
            if (data['lastSeen'] != null) {
              _lastSeen = DateTime.parse(data['lastSeen']).toLocal();
            }
          });
        }
      }
    }
  }

  String _formatLastSeen(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'yesterday';
    return '${difference.inDays}d ago';
  }

  void _loadHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchChatHistory(widget.otherUserId);
    });
  }

  void _pickMedia() async {
    final picker = ImagePicker();
    final XFile? media = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Photo Library'),
              onTap: () async => Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () async => Navigator.pop(context, await picker.pickImage(source: ImageSource.camera)),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded),
              title: const Text('Video'),
              onTap: () async => Navigator.pop(context, await picker.pickVideo(source: ImageSource.gallery)),
            ),
          ],
        ),
      ),
    );

    if (media != null && mounted) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final chatProv = Provider.of<ChatProvider>(context, listen: false);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading media...')));
      final success = await chatProv.sendMediaMessage(authProv.user!['id'], widget.otherUserId, media.path);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload media')));
      }
    }
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

  Future<void> _initiateCall(String type) async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProv.user!['id'];
    
    // Generate a unique channel name for the call
    final channelName = 'call_${currentUserId}_${widget.otherUserId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // 1. Try socket signal (for low latency if available)
    SocketService().emit('callUser', {
      'senderId': currentUserId,
      'receiverId': widget.otherUserId,
      'type': type,
      'channelName': channelName,
    });

    // 2. REST Fallback (Sends Push Notification via Backend)
    try {
      await authProv.apiService.post('/messages/call', {
        'receiverId': widget.otherUserId,
        'type': type,
        'channelName': channelName,
      });
    } catch (e) {
      print('REST Call initiation error: $e');
    }

    // Navigate to Call Screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            remoteUserId: widget.otherUserId,
            remoteUserName: widget.otherUserName,
            remoteUserAvatar: widget.otherUserAvatar,
            type: type,
            channelName: channelName,
            isIncoming: false,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).clearActiveChat();
    });
    _socketSub.cancel();
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
            title: Consumer<ChatProvider>(
              builder: (context, chatProv, _) {
                final isOnline = chatProv.isUserOnline(widget.otherUserId);
                return Row(
                  children: [
                    _buildAvatar(
                      widget.otherUserId % 5,
                      theme,
                      isDark,
                      size: 40,
                      isOnline: isOnline,
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
                          isOnline 
                            ? '● Active now' 
                            : (_lastSeen != null ? 'Last seen ${_formatLastSeen(_lastSeen!)}' : 'Offline'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOnline ? const Color(0xFF10B981) : (isDark ? Colors.white54 : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              GestureDetector(
                onTap: () => _initiateCall('audio'),
                child: _buildPremiumHeaderIcon(Icons.call_outlined, theme, isDark),
              ),
              GestureDetector(
                onTap: () => _initiateCall('video'),
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
                        final isRead = msg['is_read'] == true;
                        
                        return _buildMessageBubble(
                          msg['content'], 
                          isMe, 
                          _formatTime(msg['created_at']), 
                          isRead,
                          theme, 
                          isDark,
                          type: msg['type'],
                          mediaUrl: msg['media_url'],
                        );
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
                      onTap: _pickMedia,
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

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final dateTime = DateTime.parse(timeStr).toLocal();
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute $ampm';
    } catch (e) {
      return '';
    }
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, bool isRead, AppTheme theme, bool isDark, {String? type, String? mediaUrl}) {
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
                  if (type == 'image' && mediaUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 200,
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                        ),
                      ),
                    )
                  else if (type == 'video')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
                        ),
                      ),
                    ),
                  if (text != '[Media Message]')
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: isMe ? Colors.white.withOpacity(0.7) : (isDark ? Colors.white54 : AppColors.muted),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 13,
                          color: isRead 
                            ? (isDark ? Colors.cyanAccent : Colors.blueAccent) 
                            : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
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
