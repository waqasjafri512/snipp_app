import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/dare_card.dart';
import '../../core/constants/app_constants.dart';
import 'profile_screen.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          decoration: InputDecoration(
                            hintText: '🔍  Search people, dares...',
                            fillColor: const Color(0xFFF2EFFF),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
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
                              gradient: isSel ? AppColors.primaryGradient : null,
                              color: isSel ? null : const Color(0xFFF2EFFF),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _cats[index],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : AppColors.primaryStart,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, searchProv, child) {
                  if (searchProv.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryStart));
                  }

                  if (!_isSearching) {
                    return _buildTrendingSection(searchProv);
                  }

                  if (searchProv.searchResultsUsers.isEmpty && searchProv.searchResultsDares.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No results found 🔍', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 10),
                          Text(
                            'Try searching for something else',
                            style: GoogleFonts.plusJakartaSans(color: AppColors.muted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    children: [
                      if (searchProv.searchResultsUsers.isNotEmpty) ...[
                        Text(
                          'People',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...searchProv.searchResultsUsers.map((user) => _buildUserTile(user)),
                        const SizedBox(height: 24),
                      ],
                      if (searchProv.searchResultsDares.isNotEmpty) ...[
                        Text(
                          'Dares',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...searchProv.searchResultsDares.map((dare) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DareCard(dare: dare),
                        )),
                      ],
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(SearchProvider searchProv) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Text(
          'Trending Challenges 🔥',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 16),
        ...searchProv.trendingDares.map((dare) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DareCard(dare: dare),
        )),
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    bool isFollowing = user['is_following'] == true;
    int idx = user['id'] % 5;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(userId: user['id'])),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2EFFF))),
        ),
        child: Row(
          children: [
            _buildAvatar(idx, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['full_name'] ?? user['username'],
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    '@${user['username']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            _buildFollowButton(isFollowing, () {
              Provider.of<ProfileProvider>(context, listen: false).toggleFollow(user['id']);
              setState(() => user['is_following'] = !isFollowing);
            }),
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

  Widget _buildFollowButton(bool isFollowing, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isFollowing ? null : AppColors.primaryGradient,
          color: isFollowing ? const Color(0xFFF2EFFF) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.plusJakartaSans(
            color: isFollowing ? AppColors.primaryStart : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
}
