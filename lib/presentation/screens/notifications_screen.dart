import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_provider.dart';
import '../../core/constants/app_constants.dart';
import 'profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _currentPage++;
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(page: _currentPage);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity 🔔',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Provider.of<NotificationProvider>(context, listen: false).markAllAsRead(),
                    child: Text(
                      'Mark all as read',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryStart,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryStart,
                onRefresh: () async {
                  _currentPage = 1;
                  await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(page: 1);
                },
                child: Consumer<NotificationProvider>(
                  builder: (context, notifProv, child) {
                    if (notifProv.isLoading && notifProv.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryStart));
                    }

                    if (notifProv.notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔔', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 10),
                            Text(
                              'No activity yet',
                              style: GoogleFonts.plusJakartaSans(color: AppColors.muted),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: notifProv.notifications.length + (notifProv.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == notifProv.notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primaryStart)),
                          );
                        }
                        return _buildNotificationItem(context, notifProv.notifications[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> notif) {
    bool isUnread = notif['is_read'] == false;
    int idx = notif['actor_id'] % 5;
    
    return GestureDetector(
      onTap: () {
        if (isUnread) {
          Provider.of<NotificationProvider>(context, listen: false).markAsRead(notif['id']);
        }
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: notif['actor_id']),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStart.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: isUnread ? Border.all(color: AppColors.primaryStart.withOpacity(0.1), width: 1) : null,
        ),
        child: Row(
          children: [
            _buildAvatar(idx, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMain, height: 1.4),
                      children: [
                        TextSpan(
                          text: notif['actor_username'] ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: _getNotificationMessageText(notif),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getTimeAgo(notif['created_at']?.toString()),
                    style: GoogleFonts.plusJakartaSans(
                      color: isUnread ? AppColors.primaryStart : AppColors.muted,
                      fontSize: 11,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(int idx, {double size = 40}) {
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
          fontSize: size * 0.38,
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

  String _getNotificationMessageText(Map<String, dynamic> notif) {
    final dare = notif['dare_title'] ?? 'Dare';
    switch (notif['type']) {
      case 'like':
        return 'liked your challenge "$dare"';
      case 'comment':
        return 'commented on your challenge "$dare"';
      case 'follow':
        return 'started following you';
      case 'dare_accepted':
        return 'accepted your challenge "$dare"';
      case 'complete':
        return 'completed your challenge "$dare"';
      default:
        return 'interacted with your content';
    }
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
