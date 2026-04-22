import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../core/constants/app_constants.dart';
import 'edit_profile_screen.dart';
import 'dare_detail_screen.dart';
import 'chat_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text('Settings and privacy', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text('Your activity', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text('Log out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await Provider.of<AuthProvider>(context, listen: false).logout();
                  if (mounted) Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final isOwnProfile = widget.userId == null || widget.userId == authProv.user?['id'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Consumer<ProfileProvider>(
          builder: (context, profileProv, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwnProfile) const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.black),
              if (isOwnProfile) const SizedBox(width: 4),
              Text(
                profileProv.userProfile?['full_name'] ?? profileProv.userProfile?['username'] ?? 'Profile',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black, size: 26),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black, size: 28),
            onPressed: () => _showSettings(context),
          ),
        ],
        leading: isOwnProfile ? null : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProv, child) {
          if (profileProv.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryStart));
          }

          final profile = profileProv.userProfile;
          if (profile == null) return const Center(child: Text('Profile not found'));

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildAvatar(profile, size: 82),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('posts', profile['dares_count']?.toString() ?? '0'),
                                _buildStatItem('followers', profile['followers_count']?.toString() ?? '0'),
                                _buildStatItem('following', profile['following_count']?.toString() ?? '0'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            profile['full_name'] ?? 'Snipp User',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          if (profile['is_friend'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Friends',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ] else if (profile['follows_me'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Follows you',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (profile['category'] != null)
                        Text(
                          profile['category'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (profile['bio'] != null && profile['bio'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            profile['bio'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.black.withOpacity(0.9),
                            ),
                          ),
                        ),
                      if (profile['website'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            profile['website'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF00376B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProfileButton(
                              isOwnProfile ? 'Edit profile' : ((profile['is_following'] ?? false) ? 'Following' : 'Follow'),
                              () {
                                if (isOwnProfile) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                                } else {
                                  profileProv.toggleFollow(profile['id']);
                                }
                              },
                              isPrimary: !isOwnProfile && !(profile['is_following'] ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildProfileButton(
                              isOwnProfile ? 'Share profile' : 'Message',
                              () {
                                if (isOwnProfile) {
                                  // Share functionality could go here
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(
                                        otherUserId: profile['id'],
                                        otherUserName: profile['username'],
                                        otherUserAvatar: profile['avatar_url'],
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.black,
                    indicatorWeight: 1,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                      Tab(icon: Icon(Icons.play_circle_outline_rounded, size: 26)),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDaresGrid(profileProv.userDares),
                    _buildDaresGrid(profileProv.participatedDares),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileButton(String label, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isPrimary ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildDaresGrid(List<dynamic> dares) {
    if (dares.isEmpty) {
      return Center(
        child: Text(
          'No content yet',
          style: GoogleFonts.plusJakartaSans(color: AppColors.muted),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: dares.length,
      itemBuilder: (context, index) {
        final dare = dares[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DareDetailScreen(dare: dare)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              image: dare['media_url'] != null
                  ? DecorationImage(
                      image: NetworkImage(AppConstants.getMediaUrl(dare['media_url'])),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: dare['media_url'] == null
                ? Center(
                    child: Text(
                      dare['emoji'] ?? '🔥',
                      style: const TextStyle(fontSize: 24),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Map<String, dynamic> profile, {double size = 40}) {
    String? avatar = profile['avatar_url'];
    int id = profile['id'] ?? 0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
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
                color: AppColors.primaryStart,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.38,
              ),
            )
          : null,
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
