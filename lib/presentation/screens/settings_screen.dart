import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import 'edit_profile_screen.dart';
import 'blocked_users_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      if (authProv.user != null) {
        Provider.of<ProfileProvider>(context, listen: false).fetchProfile(authProv.user!['id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, ProfileProvider>(
      builder: (context, themeProv, profileProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;
        final profile = profileProv.userProfile;

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
              'Settings',
              style: GoogleFonts.bricolageGrotesque(
                color: theme.textMain,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 10),
              _buildSectionHeader(theme, isDark, 'Account'),
              _buildSettingsTile(
                theme, isDark,
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                subtitle: 'Change your photo, name, and bio',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
              ),
              _buildSettingsTile(
                theme, isDark,
                icon: Icons.palette_outlined,
                title: 'Theme Center',
                subtitle: 'Choose from luxurious themes',
                onTap: () => Navigator.pushNamed(context, '/theme-center'),
              ),
              _buildSettingsTile(
                theme, isDark,
                icon: Icons.lock_outline_rounded,
                title: 'Security',
                subtitle: 'Password, account protection',
                onTap: () => _showSecurityDialog(context, theme, isDark),
              ),
              _buildSettingsTile(
                theme, isDark,
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Manage alerts and push messages',
                onTap: () => _showNotificationsDialog(context, theme, isDark, profileProv),
              ),
              
              const SizedBox(height: 30),
              _buildSectionHeader(theme, isDark, 'Privacy & Safety'),
              _buildSettingsTile(
                theme, isDark,
                icon: Icons.visibility_off_outlined,
                title: 'Blocked Accounts',
                subtitle: 'Users you have blocked',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersScreen())),
              ),
              _buildSettingsTile(
                theme, isDark,
                icon: Icons.shield_outlined,
                title: 'Privacy Center',
                subtitle: 'Control who can see your activity',
                onTap: () => _showPrivacyDialog(context, theme, isDark, profileProv),
              ),

              const SizedBox(height: 30),
              _buildSectionHeader(theme, isDark, 'Support'),
              _buildSettingsTile(
                theme, isDark,
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                onTap: () => _showComingSoon(context, 'Help Center'),
              ),
              _buildSettingsTile(
                theme, isDark,
                icon: Icons.info_outline_rounded,
                title: 'About Snipp',
                onTap: () => _showAboutDialog(context, theme, isDark),
              ),

              const SizedBox(height: 40),
              _buildLogoutButton(context, theme, isDark),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Version 1.0.0 (Build 42)',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon! 🚀'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, AppTheme theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Security', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, color: theme.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.key, color: theme.primaryStart),
              title: Text('Change Password', style: TextStyle(color: theme.textMain)),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context, theme, isDark);
              },
            ),
            ListTile(
              leading: Icon(Icons.security, color: theme.primaryStart),
              title: Text('Two-Factor Auth', style: TextStyle(color: theme.textMain)),
              trailing: Switch(
                value: false, 
                activeColor: theme.primaryStart,
                onChanged: (v) => _showComingSoon(context, '2FA setup')
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Close', style: TextStyle(color: theme.primaryStart))
          )
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppTheme theme, bool isDark) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change Password', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, color: theme.textMain)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(currentController, 'Current Password', true, theme, isDark),
              const SizedBox(height: 12),
              _buildDialogTextField(newController, 'New Password', true, theme, isDark),
              const SizedBox(height: 12),
              _buildDialogTextField(confirmController, 'Confirm New Password', true, theme, isDark),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey))
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (newController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                  return;
                }
                setDialogState(() => isLoading = true);
                final result = await Provider.of<AuthProvider>(context, listen: false).changePassword(
                  currentController.text, 
                  newController.text
                );
                setDialogState(() => isLoading = false);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryStart,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, bool obscure, AppTheme theme, bool isDark) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: theme.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context, AppTheme theme, bool isDark, ProfileProvider profileProv) {
    final profile = profileProv.userProfile;
    if (profile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Notifications', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, color: theme.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSwitchTile('Push Notifications', profile['push_notifications'] ?? true, theme, (v) {
              profileProv.updateProfileSettings('push_notifications', v);
            }),
            _buildSwitchTile('Email Alerts', profile['email_notifications'] ?? false, theme, (v) {
              profileProv.updateProfileSettings('email_notifications', v);
            }),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Done', style: TextStyle(color: theme.primaryStart)))],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, AppTheme theme, bool isDark, ProfileProvider profileProv) {
    final profile = profileProv.userProfile;
    if (profile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Privacy Center', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, color: theme.textMain)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSwitchTile('Private Account', profile['is_private'] ?? false, theme, (v) {
              profileProv.updateProfileSettings('is_private', v);
            }),
            _buildSwitchTile('Show Activity', profile['show_activity'] ?? true, theme, (v) {
              profileProv.updateProfileSettings('show_activity', v);
            }),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Done', style: TextStyle(color: theme.primaryStart)))],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, AppTheme theme, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: theme.textMain, fontSize: 14, fontWeight: FontWeight.w600)),
      value: value,
      activeColor: theme.primaryStart,
      onChanged: onChanged,
    );
  }

  void _showAboutDialog(BuildContext context, AppTheme theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text('About Snipp', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, color: theme.textMain)),
          ],
        ),
        content: Text(
          'Snipp is the ultimate dare challenge platform. Create, complete, and share your daring moments with the world! \n\nMade with ❤️ by the Snipp Team.',
          style: TextStyle(color: theme.textMain.withOpacity(0.8)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: theme.primaryStart)))],
      ),
    );
  }

  Widget _buildSectionHeader(AppTheme theme, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: isDark ? Colors.white54 : Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(AppTheme theme, bool isDark, {
    required IconData icon, 
    required String title, 
    String? subtitle, 
    required VoidCallback onTap
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: theme.primaryStart, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.textMain,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppTheme theme, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.background,
            title: Text('Logout?', style: TextStyle(color: theme.textMain)),
            content: Text('Are you sure you want to sign out of Snipp?', style: TextStyle(color: theme.textMain.withOpacity(0.7))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true), 
                child: const Text('Logout', style: TextStyle(color: Colors.red))
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          await Provider.of<AuthProvider>(context, listen: false).logout();
          Navigator.pushNamedAndRemoveUntil(context, AppConstants.loginRoute, (route) => false);
        }
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.red.withOpacity(0.2) : const Color(0xFFFEE2E2)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

