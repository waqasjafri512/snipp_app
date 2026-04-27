import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchBlockedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final theme = themeProv.currentTheme;
    final isDark = themeProv.currentThemeIndex == 1;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Blocked Accounts',
          style: GoogleFonts.bricolageGrotesque(
            color: theme.textMain,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProv, child) {
          if (profileProv.isLoading && profileProv.blockedUsers.isEmpty) {
            return Center(child: CircularProgressIndicator(color: theme.primaryStart));
          }

          if (profileProv.blockedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.block_flipped, size: 40, color: isDark ? Colors.white24 : Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No blocked accounts',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.textMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'When you block someone, they won\'t be able to see your profile or message you.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white54 : AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: profileProv.blockedUsers.length,
            itemBuilder: (context, index) {
              final user = profileProv.blockedUsers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: user['avatar_url'] != null ? NetworkImage(AppConstants.getMediaUrl(user['avatar_url'])) : null,
                      child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['full_name'] ?? user['username'],
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: theme.textMain,
                            ),
                          ),
                          Text(
                            '@${user['username']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _confirmUnblock(context, user),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primaryStart,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Unblock', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmUnblock(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${user['username']}?'),
        content: Text('They will be able to find your profile, see your dares, and message you again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<ProfileProvider>(context, listen: false).unblockUser(user['id']);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('@${user['username']} has been unblocked')));
              }
            },
            child: const Text('Unblock', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
