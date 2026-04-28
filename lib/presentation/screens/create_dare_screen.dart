import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/dare_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../../data/repositories/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/gradient_button.dart';

class CreateDareScreen extends StatefulWidget {
  final Map<String, dynamic>? existingDare;
  const CreateDareScreen({super.key, this.existingDare});

  @override
  State<CreateDareScreen> createState() => _CreateDareScreenState();
}

class _CreateDareScreenState extends State<CreateDareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int? _selectedCategoryId;
  File? _selectedMedia;
  String? _mediaUrl;
  String? _mediaType;
  bool _isMediaUploading = false;
  bool _isSubmitting = false;
  String _postType = 'dare'; // 'dare' or 'general'

  final List<String> _categories = ["🔥 Trending", "💪 Fitness", "😂 Funny", "🎨 Creative", "🌊 Outdoors", "🍕 Food"];
  int _selCatIdx = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingDare != null) {
      _titleController.text = widget.existingDare!['title'] ?? '';
      _descriptionController.text = widget.existingDare!['description'] ?? '';
      _postType = widget.existingDare!['post_type'] ?? 'dare';
      _mediaUrl = widget.existingDare!['media_url'];
      _mediaType = widget.existingDare!['media_type'];
      
      // Try to match category
      final cat = widget.existingDare!['category'];
      if (cat != null) {
        final idx = _categories.indexWhere((c) => c.contains(cat) || cat.contains(c));
        if (idx != -1) _selCatIdx = idx;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_isMediaUploading || _isSubmitting) return; 
    
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      final dareProv = Provider.of<DareProvider>(context, listen: false);
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      
      final dareData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categories[_selCatIdx],
        'media_url': _mediaUrl,
        'media_type': _mediaType,
        'post_type': _postType,
        'emoji': _getEmojiForCategory(_categories[_selCatIdx]),
      };

      try {
        final bool success;
        if (widget.existingDare != null) {
          success = await dareProv.updateDare(widget.existingDare!['id'], dareData);
        } else {
          success = await dareProv.createDare(dareData, authProv.user);
        }

        if (success && mounted) {
          final profileProv = Provider.of<ProfileProvider>(context, listen: false);
          if (authProv.user != null) {
            profileProv.fetchUserDares(authProv.user!['id']);
            profileProv.fetchProfile(authProv.user!['id']);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.existingDare != null ? 'Post updated! 💫' : 'Posted successfully! 🚀')),
          );
          Navigator.pop(context);
        } else if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(dareProv.error ?? 'Failed to process post')),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  String _getEmojiForCategory(String cat) {
    if (cat.contains('🔥')) return '🧊';
    if (cat.contains('💪')) return '🏃';
    if (cat.contains('😂')) return '💃';
    if (cat.contains('🎨')) return '🎨';
    if (cat.contains('🌊')) return '🏄';
    if (cat.contains('🍕')) return '🌶️';
    return '⚡';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        final user = authProv.user;

        bool canPost = (_descriptionController.text.trim().isNotEmpty || _selectedMedia != null) && !_isSubmitting && !_isMediaUploading;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0.5,
            leading: IconButton(
              icon: Icon(Icons.close, color: theme.textMain),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Create post',
              style: GoogleFonts.plusJakartaSans(
                color: theme.textMain,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextButton(
                  onPressed: canPost ? _handleSubmit : null,
                  style: TextButton.styleFrom(
                    backgroundColor: canPost ? theme.primaryStart : (isDark ? Colors.white10 : Colors.grey[200]),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'POST',
                    style: GoogleFonts.plusJakartaSans(
                      color: canPost ? Colors.white : (isDark ? Colors.white24 : Colors.grey[500]),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // User Identity Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: (user?['avatar_url'] != null)
                                    ? NetworkImage(AppConstants.getMediaUrl(user!['avatar_url']))
                                    : null,
                                child: (user?['avatar_url'] == null)
                                    ? Text(user?['username']?[0].toUpperCase() ?? 'U', style: const TextStyle(color: Colors.black54))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?['full_name'] ?? user?['username'] ?? 'User',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: theme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildSmallBadge(Icons.public, 'Public', isDark, theme),
                                      const SizedBox(width: 6),
                                      _buildSmallBadge(Icons.add, 'Album', isDark, theme),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Post Type Switch (Dare vs General)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _buildTypeChip('dare', '🎯 Dare', isDark, theme),
                              const SizedBox(width: 8),
                              _buildTypeChip('general', '📝 General', isDark, theme),
                            ],
                          ),
                        ),

                        // Title Input Area (Only for Dares)
                        if (_postType == 'dare')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: TextFormField(
                              controller: _titleController,
                              validator: (v) => v!.isEmpty ? 'Title is required' : null,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textMain,
                              ),
                              decoration: InputDecoration(
                                hintText: "Dare Title",
                                hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400]),
                                border: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
                              ),
                            ),
                          ),

                        // Text Input Area
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: TextFormField(
                            controller: _descriptionController,
                            maxLines: null,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: (_postType == 'general' && _descriptionController.text.length < 50) ? 22 : 16,
                              fontWeight: FontWeight.w400,
                              color: theme.textMain,
                            ),
                            decoration: InputDecoration(
                              hintText: _postType == 'dare' ? "What are the rules?" : "What's on your mind?",
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white24 : Colors.grey[400],
                                fontSize: 18,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        // Media Preview
                        if (_selectedMedia != null || _mediaUrl != null || _isMediaUploading)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _isMediaUploading 
                                    ? Container(
                                        height: 250,
                                        width: double.infinity,
                                        color: isDark ? Colors.white10 : Colors.grey[100],
                                        child: Center(child: CircularProgressIndicator(color: theme.primaryStart)),
                                      )
                                    : _selectedMedia != null 
                                      ? Image.file(_selectedMedia!, width: double.infinity, fit: BoxFit.cover)
                                      : Image.network(AppConstants.getMediaUrl(_mediaUrl!), width: double.infinity, fit: BoxFit.cover),
                                ),
                                if (!_isMediaUploading)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () => setState(() { _selectedMedia = null; _mediaUrl = null; }),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),

                // Bottom "Add to your post" bar
                _buildBottomActionPanel(isDark, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeChip(String type, String label, bool isDark, AppTheme theme) {
    bool isSel = _postType == type;
    return GestureDetector(
      onTap: () => setState(() => _postType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? theme.primaryStart.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? theme.primaryStart : (isDark ? Colors.white10 : Colors.grey[300]!)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
            color: isSel ? theme.primaryStart : (isDark ? Colors.white54 : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionPanel(bool isDark, AppTheme theme) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.background,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text('Add to your post', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: theme.textMain)),
                const Spacer(),
                _buildActionIcon(Icons.photo_library, Colors.green, () => _pickMedia(ImageSource.gallery)),
                _buildActionIcon(Icons.camera_alt, Colors.redAccent, () => _pickMedia(ImageSource.camera)),
                _buildActionIcon(Icons.emoji_emotions, Colors.orange, () => _showCategoryPicker(isDark, theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  void _showCategoryPicker(bool isDark, AppTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Category', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: theme.textMain)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.asMap().entries.map((entry) {
                final index = entry.key;
                final cat = entry.value;
                final isSelected = _selCatIdx == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selCatIdx = index);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.primaryStart : (isDark ? Colors.white10 : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : theme.textMain)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source, imageQuality: 80);
      
    if (file == null) return;

    setState(() {
      _selectedMedia = File(file.path);
      _isMediaUploading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.uploadFile('/dares/upload-media', file.path, 'media');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _mediaUrl = data['data']['mediaUrl'];
          _mediaType = data['data']['mediaType'];
          _isMediaUploading = false;
        });
      } else {
        setState(() => _isMediaUploading = false);
      }
    } catch (e) {
      setState(() => _isMediaUploading = false);
    }
  }

  Widget _buildSmallBadge(IconData icon, String label, bool isDark, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.white54 : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.grey[600])),
        ],
      ),
    );
  }
}
