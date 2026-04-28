import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../data/repositories/api_service.dart';
import '../widgets/dare_card.dart';
import 'edit_profile_screen.dart';
import 'chat_detail_screen.dart';
import 'user_list_screen.dart';
import 'settings_screen.dart';
import '../widgets/verification_badge.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  final bool isTab;
  const ProfileScreen({super.key, this.userId, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  void _loadProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final targetUserId = widget.userId ?? authProv.user?['id'];
      if (targetUserId != null) {
        final profileProv = Provider.of<ProfileProvider>(context, listen: false);
        profileProv.fetchProfile(targetUserId);
        profileProv.fetchUserDares(targetUserId);
        profileProv.fetchParticipatedDares(targetUserId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _showMoreOptions(BuildContext context, Map<String, dynamic> profile, bool isOwnProfile) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).currentThemeIndex == 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            if (!isOwnProfile) ...[
              ListTile(
                leading: const Icon(Icons.block_flipped, color: Colors.redAccent),
                title: Text('Block @${profile['username']}', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmBlock(context, profile);
                },
              ),
              ListTile(
                leading: Icon(Icons.report_gmailerrorred_rounded, color: theme.textMain),
                title: Text('Report Account', style: GoogleFonts.plusJakartaSans(color: theme.textMain)),
                onTap: () => Navigator.pop(context),
              ),
            ],
            ListTile(
              leading: Icon(Icons.share_outlined, color: theme.textMain),
              title: Text('Share Profile', style: GoogleFonts.plusJakartaSans(color: theme.textMain)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmBlock(BuildContext context, Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${profile['username']}?'),
        content: Text('They won\'t be able to find your profile, see your dares, or message you. Snipp won\'t let them know you blocked them.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await Provider.of<ProfileProvider>(context, listen: false).blockUser(profile['id']);
              if (success && mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to feed/previous screen
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('@${profile['username']} has been blocked')));
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _showImageOptions(bool isAvatar, String? imageUrl) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).currentThemeIndex == 1;
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final bool isOwnProfile = widget.userId == null || widget.userId == authProv.user?['id'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(
              isAvatar ? 'Profile Picture' : 'Cover Photo',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: theme.textMain),
            ),
            const SizedBox(height: 20),
            if (imageUrl != null && imageUrl.isNotEmpty)
              ListTile(
                leading: Icon(Icons.fullscreen_rounded, color: theme.textMain),
                title: Text('View Full Image', style: GoogleFonts.plusJakartaSans(color: theme.textMain)),
                onTap: () {
                  Navigator.pop(context);
                  _viewFullImage(imageUrl);
                },
              ),
            if (isOwnProfile)
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: theme.textMain),
                title: Text(imageUrl != null && imageUrl.isNotEmpty ? 'Upload New Photo' : 'Upload Photo', style: GoogleFonts.plusJakartaSans(color: theme.textMain)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isAvatar);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _viewFullImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(AppConstants.getMediaUrl(url), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picker = ImagePicker();
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAvatar ? 'Update Profile Picture' : 'Update Cover Photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    try {
      final apiService = ApiService();
      final endpoint = isAvatar ? '/profile/upload-avatar' : '/profile/upload-cover';
      final fieldName = isAvatar ? 'avatar' : 'cover';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading...')));
      }

      final response = await apiService.uploadFile(endpoint, file.path, fieldName);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!')));
          final userId = Provider.of<AuthProvider>(context, listen: false).user?['id'];
          if (userId != null) {
            Provider.of<ProfileProvider>(context, listen: false).fetchProfile(userId);
          }
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final isOwnProfile = widget.userId == null || widget.userId == authProv.user?['id'];

    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final currentTheme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Consumer<ProfileProvider>(
          builder: (context, profileProv, child) {
            if (profileProv.isLoading) {
              return Container(
                color: currentTheme.background,
                child: Center(child: CircularProgressIndicator(color: currentTheme.primaryStart)),
              );
            }

            final profile = profileProv.userProfile;
            if (profile == null) {
              return Container(
                color: currentTheme.background,
                child: Center(child: Text('Profile not found', style: TextStyle(color: currentTheme.textMain))),
              );
            }

            return Container(
              color: currentTheme.background,
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                  // 1. SliverAppBar (Replaces fixed AppBar)
                  SliverAppBar(
                    backgroundColor: currentTheme.background,
                    elevation: 0,
                    pinned: true,
                    leading: (!widget.isTab && Navigator.canPop(context))
                        ? IconButton(
                            icon: Icon(Icons.arrow_back_rounded, color: currentTheme.textMain),
                            onPressed: () => Navigator.pop(context),
                          )
                        : null,
                    title: Text(
                      profile['username'] ?? 'Profile',
                      style: GoogleFonts.plusJakartaSans(
                        color: currentTheme.textMain, 
                        fontWeight: FontWeight.w700, 
                        fontSize: 16
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.search_rounded, color: currentTheme.textMain),
                        onPressed: () {},
                      ),
                      if (isOwnProfile)
                        IconButton(
                          icon: Icon(Icons.menu_rounded, color: currentTheme.textMain),
                          onPressed: () => _showSettings(context),
                        ),
                    ],
                  ),
                  // 1. Cover and Profile Picture Section
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 260, // 200 cover + 60 avatar overflow
                          child: Stack(
                            children: [
                              // Cover Photo
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 200,
                                child: GestureDetector(
                                  onTap: () => _showImageOptions(false, profile['cover_url']),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : Colors.grey[200],
                                      image: profile['cover_url'] != null && profile['cover_url'].toString().isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(AppConstants.getMediaUrl(profile['cover_url'])),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: profile['cover_url'] == null
                                        ? Container(
                                            decoration: BoxDecoration(
                                              gradient: isDark 
                                                ? LinearGradient(colors: [Colors.black, currentTheme.primaryStart.withOpacity(0.3)])
                                                : const LinearGradient(
                                                    colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              // Profile Picture overlapping cover
                              Positioned(
                                bottom: 0,
                                left: 16,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _showImageOptions(true, profile['avatar_url']),
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: currentTheme.background,
                                          shape: BoxShape.circle,
                                        ),
                                        child: _buildAvatar(profile, currentTheme, isDark, size: 140),
                                      ),
                                      if (isOwnProfile)
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: currentTheme.background, shape: BoxShape.circle),
                                            child: Icon(Icons.camera_alt_rounded, size: 20, color: currentTheme.textMain),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Cover Edit Button (if own profile)
                              if (isOwnProfile)
                                Positioned(
                                  top: 150,
                                  right: 16,
                                  child: _buildCircleIconButton(Icons.camera_alt_rounded, currentTheme, isDark, () => _showImageOptions(false, profile['cover_url'])),
                                ),
                            ],
                          ),
                        ),
                        // Removed the 64px SizedBox since the Stack now includes the 60px height
                        const SizedBox(height: 10),
                        // 2. Name and Info Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    profile['full_name'] ?? 'Snipp User',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: currentTheme.textMain,
                                    ),
                                  ),
                                  if (profile['is_verified'] == true)
                                    const VerificationBadge(size: 20, padding: EdgeInsets.only(left: 8)),
                                ],
                              ),
                              if (profile['username'] != null)
                                Text(
                                  '@${profile['username']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    color: isDark ? Colors.white54 : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (profile['bio'] != null && profile['bio'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    profile['bio'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      height: 1.4,
                                      color: currentTheme.textMain,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              // 3. Action Buttons (Facebook Style)
                              Row(
                                children: [
                                  if (isOwnProfile) ...[
                                    Expanded(
                                      child: _buildFBButton(
                                        'Add to Story', 
                                        Icons.add_circle_rounded, 
                                        currentTheme.primaryStart, 
                                        Colors.white, 
                                        () {}
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildFBButton(
                                        'Edit Profile', 
                                        Icons.edit_rounded, 
                                        isDark ? Colors.white12 : Colors.grey[200]!, 
                                        currentTheme.textMain, 
                                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()))
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                      child: _buildFBButton(
                                        (profile['is_following'] ?? false) ? 'Following' : 'Follow', 
                                        (profile['is_following'] ?? false) ? Icons.check_rounded : Icons.person_add_rounded, 
                                        (profile['is_following'] ?? false) ? (isDark ? Colors.white12 : Colors.grey[200]!) : currentTheme.primaryStart, 
                                        (profile['is_following'] ?? false) ? currentTheme.textMain : Colors.white, 
                                        () => profileProv.toggleFollow(profile['id'])
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildFBButton(
                                        'Message', 
                                        Icons.chat_bubble_rounded, 
                                        isDark ? Colors.white12 : Colors.grey[200]!, 
                                        currentTheme.textMain, 
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatDetailScreen(
                                              otherUserId: profile['id'],
                                              otherUserName: profile['username'],
                                              otherUserAvatar: profile['avatar_url'],
                                            ),
                                          ),
                                        ),
                                      )
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  _buildFBIconButton(
                                    Icons.more_horiz_rounded, 
                                    isDark ? Colors.white12 : Colors.grey[200]!, 
                                    currentTheme.textMain, 
                                    () => _showMoreOptions(context, profile, isOwnProfile)
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
                              const SizedBox(height: 12),
                              // 4. Details Section
                              if (profile['works_at'] != null && profile['works_at'].isNotEmpty)
                                _buildDetailItem(Icons.work_rounded, 'Works at ${profile['works_at']}', currentTheme, isDark),
                              if (profile['studied_at'] != null && profile['studied_at'].isNotEmpty)
                                _buildDetailItem(Icons.school_rounded, 'Studied at ${profile['studied_at']}', currentTheme, isDark),
                              if (profile['location'] != null && profile['location'].isNotEmpty)
                                _buildDetailItem(Icons.home_rounded, 'Lives in ${profile['location']}', currentTheme, isDark),
                              if (profile['from_location'] != null && profile['from_location'].isNotEmpty)
                                _buildDetailItem(Icons.location_on_rounded, 'From ${profile['from_location']}', currentTheme, isDark),
                              
                              // Stats Row (Followers / Following)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (context) => UserListScreen(
                                            userId: profile['id'], 
                                            title: 'Followers',
                                            isFollowers: true,
                                          )
                                        )
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '${profile['followers_count'] ?? 0} ',
                                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: currentTheme.textMain, fontSize: 15),
                                            ),
                                            TextSpan(
                                              text: 'Followers',
                                              style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context, 
                                        MaterialPageRoute(
                                          builder: (context) => UserListScreen(
                                            userId: profile['id'], 
                                            title: 'Following',
                                            isFollowers: false,
                                          )
                                        )
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '${profile['following_count'] ?? 0} ',
                                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: currentTheme.textMain, fontSize: 15),
                                            ),
                                            TextSpan(
                                              text: 'Following',
                                              style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (profile['is_friend'] == true) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: currentTheme.primaryStart.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: currentTheme.primaryStart.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.handshake_rounded, size: 14, color: currentTheme.primaryStart),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Friend',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: currentTheme.primaryStart,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFBButton(
                                'Edit Public Details', 
                                null, 
                                currentTheme.primaryStart.withOpacity(0.1), 
                                isDark ? currentTheme.primaryEnd : currentTheme.primaryStart, 
                                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()))
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 5. Tabs
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: currentTheme.primaryStart,
                        labelColor: currentTheme.primaryStart,
                        unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[600],
                        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Dares'),
                          Tab(text: 'Photos'),
                        ],
                      ),
                      currentTheme.background,
                      isDark,
                    ),
                  ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDaresList(profileProv.userDares, currentTheme, isDark),
                    _buildDaresList(profileProv.participatedDares, currentTheme, isDark),
                    _buildPhotosGrid(profileProv.userDares, currentTheme, isDark),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCircleIconButton(IconData icon, AppTheme theme, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: theme.textMain),
      ),
    );
  }

  Widget _buildFBButton(String label, IconData? icon, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFBIconButton(IconData icon, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: textColor),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, AppTheme theme, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: theme.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaresList(List<dynamic> dares, AppTheme theme, bool isDark) {
    if (dares.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Icons.post_add_rounded, size: 40, color: theme.primaryStart.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text('No posts yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textMain)),
            const SizedBox(height: 8),
            Text('When you post dares or moments,\nthey will show up here.', textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: dares.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: DareCard(dare: dares[index]),
        );
      },
    );
  }

  Widget _buildPhotosGrid(List<dynamic> dares, AppTheme theme, bool isDark) {
    final photos = dares.where((d) => d['media_url'] != null).toList();
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Icons.photo_library_rounded, size: 40, color: theme.primaryStart.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text('No photos yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textMain)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Image.network(AppConstants.getMediaUrl(photos[index]['media_url']), fit: BoxFit.cover);
      },
    );
  }

  Widget _buildAvatar(Map<String, dynamic> profile, AppTheme theme, bool isDark, {double size = 40}) {
    String? avatar = profile['avatar_url'];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        shape: BoxShape.circle,
        border: Border.all(color: theme.background, width: 4),
        image: (avatar != null && avatar.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(AppConstants.getMediaUrl(avatar)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: (avatar == null || avatar.isEmpty)
          ? Text(
              (profile['username'] ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                color: theme.primaryStart,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.35,
              ),
            )
          : null,
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.bgColor, this.isDark);

  final TabBar _tabBar;
  final Color bgColor;
  final bool isDark;

  @override
  double get minExtent => _tabBar.preferredSize.height + 2;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 2;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      child: Column(
        children: [
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
          _tabBar,
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey[200]),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.bgColor != bgColor || oldDelegate.isDark != isDark;
  }
}
