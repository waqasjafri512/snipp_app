import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.appBarTheme.titleTextStyle?.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.bricolageGrotesque(
            color: theme.appBarTheme.titleTextStyle?.color,
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
          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            subtitle: 'Change your photo, name, and bio',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Theme Center',
            subtitle: 'Choose from 10 luxurious themes',
            onTap: () => Navigator.pushNamed(context, '/theme-center'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Security',
            subtitle: 'Password, two-factor authentication',
            onTap: () => _showSecurityDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Manage alerts and push messages',
            onTap: () => _showNotificationsDialog(context),
          ),
          
          const SizedBox(height: 30),
          _buildSectionHeader(context, 'Privacy & Safety'),
          _buildSettingsTile(
            context,
            icon: Icons.visibility_off_outlined,
            title: 'Blocked Accounts',
            subtitle: 'Users you have blocked',
            onTap: () => _showComingSoon(context, 'Blocked Accounts'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.shield_outlined,
            title: 'Privacy Center',
            subtitle: 'Control who can see your activity',
            onTap: () => _showPrivacyDialog(context),
          ),

          const SizedBox(height: 30),
          _buildSectionHeader(context, 'Support'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            onTap: () => _showComingSoon(context, 'Help Center'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'About Snipp',
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: 40),
          _buildLogoutButton(context),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Version 1.0.0 (Build 42)',
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.dark ? Colors.white54 : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
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

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Security', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Change Password');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Two-Factor Auth'),
              trailing: Switch(value: false, onChanged: (v) => _showComingSoon(context, '2FA setup')),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              value: true,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Email Alerts'),
              value: false,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('New Dare Alerts'),
              value: true,
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Center', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Private Account'),
              subtitle: const Text('Only followers can see your posts'),
              value: false,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: const Text('Show Activity Status'),
              value: true,
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text('About Snipp', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text('Snipp is the ultimate dare challenge platform. Create, complete, and share your daring moments with the world! \n\nMade with ❤️ by the Snipp Team.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: theme.brightness == Brightness.dark ? Colors.white54 : Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle, 
    required VoidCallback onTap
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
                child: Icon(icon, color: theme.appBarTheme.titleTextStyle?.color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.appBarTheme.titleTextStyle?.color,
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

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout?'),
            content: const Text('Are you sure you want to sign out of Snipp?'),
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
