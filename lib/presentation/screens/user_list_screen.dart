import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import 'profile_screen.dart';

class UserListScreen extends StatefulWidget {
  final int userId;
  final String title;
  final bool isFollowers;

  const UserListScreen({
    super.key,
    required this.userId,
    required this.title,
    this.isFollowers = true,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final profileProv = Provider.of<ProfileProvider>(context, listen: false);
    if (widget.isFollowers) {
      profileProv.fetchFollowers(widget.userId);
    } else {
      profileProv.fetchFollowing(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.background,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textMain, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.title,
              style: GoogleFonts.bricolageGrotesque(
                color: theme.textMain,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF0EEFF)),
            ),
          ),
          body: Consumer<ProfileProvider>(
            builder: (context, profileProv, _) {
              final users = widget.isFollowers ? profileProv.followersList : profileProv.followingList;

              if (profileProv.isLoading && users.isEmpty) {
                return Center(child: CircularProgressIndicator(color: theme.primaryStart));
              }

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: isDark ? Colors.white24 : AppColors.muted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white54 : AppColors.muted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserTile(user, theme, isDark);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUserTile(dynamic user, AppTheme theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user['id']),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
              backgroundImage: user['avatar_url'] != null
                  ? NetworkImage(AppConstants.getMediaUrl(user['avatar_url']))
                  : null,
              child: user['avatar_url'] == null
                  ? Icon(Icons.person, color: isDark ? Colors.white24 : Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user['username'] ?? 'User',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: theme.textMain,
                        ),
                      ),
                      if (user['is_verified'] == true) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded, color: theme.primaryStart, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    user['full_name'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 20, color: isDark ? Colors.white24 : AppColors.muted.withOpacity(0.5)),
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              onSelected: (value) {
                if (value == 'view') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: user['id'])));
                } else if (value == 'unfollow') {
                  Provider.of<ProfileProvider>(context, listen: false).toggleFollow(user['id']);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 18, color: theme.textMain),
                      const SizedBox(width: 10),
                      Text('View Profile', style: GoogleFonts.plusJakartaSans(color: theme.textMain)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'unfollow',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_outlined, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Text('Unfollow', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
