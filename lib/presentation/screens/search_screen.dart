import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/dare_card.dart';
import '../../core/constants/app_constants.dart';
import 'profile_screen.dart';
import '../widgets/verification_badge.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  int _selectedCat = 0;
  final List<String> _cats = ["All", "Users", "Dares", "Live"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchProv = Provider.of<SearchProvider>(context, listen: false);
      searchProv.fetchTrending();
      searchProv.fetchTrendingCreators();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    setState(() {
      _isSearching = val.isNotEmpty;
    });
    Provider.of<SearchProvider>(context, listen: false).search(val);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final currentTheme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Scaffold(
          backgroundColor: currentTheme.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header with Search Bar
                _buildSearchHeader(currentTheme, isDark),

                Expanded(
                  child: Consumer<SearchProvider>(
                    builder: (context, searchProv, child) {
                      if (searchProv.isLoading) {
                        return Center(child: CircularProgressIndicator(color: currentTheme.primaryStart));
                      }

                      if (!_isSearching) {
                        return _buildDiscoveryView(searchProv, currentTheme, isDark);
                      }

                      return _buildSearchResults(searchProv, currentTheme, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchHeader(AppTheme theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: theme.background,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.08))),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600, 
                fontSize: 15,
                color: theme.textMain,
              ),
              decoration: InputDecoration(
                hintText: 'Search people, dares...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white54 : AppColors.muted, 
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: theme.primaryStart),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              itemBuilder: (context, index) {
                bool isSel = _selectedCat == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCat = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSel ? theme.gradient : null,
                      color: isSel ? null : (isDark ? Colors.white10 : const Color(0xFFF2EFFF)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _cats[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSel ? Colors.white : theme.primaryStart,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryView(SearchProvider searchProv, AppTheme theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        // Trending Creators
        if (searchProv.trendingUsers.isNotEmpty) ...[
          _buildSectionTitle('Trending Creators ✨', theme),
          const SizedBox(height: 16),
          _buildTrendingCreators(searchProv.trendingUsers, theme, isDark),
          const SizedBox(height: 32),
        ],
        
        // Popular Categories
        _buildSectionTitle('Explore Categories 🔍', theme),
        const SizedBox(height: 16),
        _buildCategoryGrid(theme, isDark),

        const SizedBox(height: 32),
        
        // Popular Dares
        _buildSectionTitle('Active Dares 🔥', theme),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: searchProv.trendingDares.map((dare) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DareCard(dare: dare),
            )).toList(),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionTitle(String title, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: theme.textMain,
        ),
      ),
    );
  }

  Widget _buildTrendingCreators(List<dynamic> users, AppTheme theme, bool isDark) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: user['id']))),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: theme.gradient,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.background,
                        shape: BoxShape.circle,
                        image: user['avatar_url'] != null 
                          ? DecorationImage(image: NetworkImage(AppConstants.getMediaUrl(user['avatar_url'])), fit: BoxFit.cover)
                          : null,
                      ),
                      child: user['avatar_url'] == null 
                        ? Center(
                            child: Text(
                              (user['full_name'] ?? user['username'])[0].toUpperCase(),
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: theme.primaryStart,
                              ),
                            ),
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user['full_name'] ?? user['username'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, 
                              fontWeight: FontWeight.w700,
                              color: theme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (user['is_verified'] == true)
                          const VerificationBadge(size: 10, padding: EdgeInsets.only(left: 2)),
                      ],
                    ),
                  Text(
                    '${user['followers_count'] ?? 0} followers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, 
                      color: isDark ? Colors.white54 : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(AppTheme theme, bool isDark) {
    final List<Map<String, dynamic>> categories = [
      {'name': 'Fitness', 'icon': '💪', 'color': isDark ? const Color(0xFF064E3B).withOpacity(0.3) : const Color(0xFFF0FDF4)},
      {'name': 'Funny', 'icon': '😂', 'color': isDark ? const Color(0xFF7C2D12).withOpacity(0.3) : const Color(0xFFFFF7ED)},
      {'name': 'Creative', 'icon': '🎨', 'color': isDark ? const Color(0xFF4C1D95).withOpacity(0.3) : const Color(0xFFF5F3FF)},
      {'name': 'Food', 'icon': '🍕', 'color': isDark ? const Color(0xFF991B1B).withOpacity(0.3) : const Color(0xFFFEF2F2)},
      {'name': 'Travel', 'icon': '✈️', 'color': isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFEFF6FF)},
      {'name': 'Gaming', 'icon': '🎮', 'color': isDark ? const Color(0xFF9D174D).withOpacity(0.3) : const Color(0xFFFFF1F2)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            decoration: BoxDecoration(
              color: cat['color'],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cat['icon'], style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  cat['name'],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: theme.textMain,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(SearchProvider searchProv, AppTheme theme, bool isDark) {
    if (searchProv.searchResultsUsers.isEmpty && searchProv.searchResultsDares.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18, 
                fontWeight: FontWeight.w800,
                color: theme.textMain,
              ),
            ),
            Text(
              'Try a different keyword',
              style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white54 : AppColors.muted),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (searchProv.searchResultsUsers.isNotEmpty) ...[
          Text(
            'People',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, 
              fontSize: 13, 
              color: isDark ? Colors.white54 : AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          ...searchProv.searchResultsUsers.map((user) => _buildUserTile(user, theme, isDark)),
          const SizedBox(height: 24),
        ],
        if (searchProv.searchResultsDares.isNotEmpty) ...[
          Text(
            'Dares',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, 
              fontSize: 13, 
              color: isDark ? Colors.white54 : AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          ...searchProv.searchResultsDares.map((dare) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DareCard(dare: dare),
          )),
        ],
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, AppTheme theme, bool isDark) {
    bool isFollowing = user['is_following'] == true;
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppConstants.profileRoute, arguments: user['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                  ? Text(
                      (user['username'] ?? 'U')[0].toUpperCase(), 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textMain,
                      ),
                    )
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
                        user['full_name'] ?? user['username'],
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, 
                          fontSize: 15,
                          color: theme.textMain,
                        ),
                      ),
                      if (user['is_verified'] == true)
                        const VerificationBadge(size: 14),
                    ],
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
            _buildFollowButton(isFollowing, theme, isDark, () {
              Provider.of<ProfileProvider>(context, listen: false).toggleFollow(user['id']);
              setState(() => user['is_following'] = !isFollowing);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(bool isFollowing, AppTheme theme, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isFollowing ? null : theme.gradient,
          color: isFollowing ? (isDark ? Colors.transparent : Colors.white) : null,
          borderRadius: BorderRadius.circular(12),
          border: isFollowing ? Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)) : null,
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.plusJakartaSans(
            color: isFollowing ? theme.textMain : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
