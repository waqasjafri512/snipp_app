import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/dare_provider.dart';
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

        return Scaffold(
          backgroundColor: theme.background,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 64, 22, 30),
                  decoration: BoxDecoration(
                    gradient: theme.gradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _postType == 'dare' ? 'Create Dare ⚡' : 'New Post 📝',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _postType == 'dare' 
                          ? 'Challenge your followers to something epic'
                          : 'Share what\'s on your mind with the world',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Post Type Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTypeButton('dare', '🎯 Dare', theme, isDark),
                              ),
                              Expanded(
                                child: _buildTypeButton('general', '📝 General Post', theme, isDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Media Picker
                        GestureDetector(
                          onTap: _pickMedia,
                          child: Container(
                            height: 156,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.primaryStart.withOpacity(0.32),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _selectedMedia != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.file(_selectedMedia!, fit: BoxFit.contain, width: double.infinity),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () => setState(() { _selectedMedia = null; _mediaUrl = null; _mediaType = null; }),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : _isMediaUploading
                                    ? Center(child: CircularProgressIndicator(color: theme.primaryStart))
                                    : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: isDark ? null : [
                                            BoxShadow(
                                              color: theme.primaryStart.withOpacity(0.16),
                                              blurRadius: 18,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text('📸', style: TextStyle(fontSize: 28)),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Add Photo or Video',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: theme.primaryStart,
                                        ),
                                      ),
                                      Text(
                                        '(Optional)',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isDark ? Colors.white54 : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _postType == 'dare' ? 'Dare Title *' : 'Headline *',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.textMain,
                              ),
                            ),
                            Text(
                              '${_titleController.text.length}/60',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _titleController,
                          maxLength: 60,
                          onChanged: (v) => setState(() {}),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.textMain,
                          ),
                          decoration: InputDecoration(
                            hintText: _postType == 'dare' ? 'Make it catchy...' : 'What\'s happening?',
                            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                            counterText: '',
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 18),

                        // Description
                        Text(
                          _postType == 'dare' ? 'Description' : 'Content',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.textMain,
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: theme.textMain,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText: _postType == 'dare' 
                              ? 'Describe the dare, rules, and what completion looks like...'
                              : 'Share your thoughts, stories, or news...',
                            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Category
                        Text(
                          'Category',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.textMain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_categories.length, (index) {
                            bool isSelected = _selCatIdx == index;
                            return GestureDetector(
                              onTap: () => setState(() => _selCatIdx = index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? theme.gradient : null,
                                  color: isSelected ? null : (isDark ? Colors.white10 : const Color(0xFFEDE9FE)),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: isSelected && !isDark ? [
                                    BoxShadow(
                                      color: theme.primaryStart.withOpacity(0.3),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ] : null,
                                ),
                                child: Text(
                                  _categories[index],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : theme.primaryStart,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),

                        // Settings Card (Only for Dares)
                        if (_postType == 'dare')
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isDark ? null : [
                                BoxShadow(
                                  color: theme.primaryStart.withOpacity(0.07),
                                  blurRadius: 20,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: isDark ? Border.all(color: Colors.white10) : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '⚙️ Dare Settings',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: theme.textMain,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? theme.primaryStart.withOpacity(0.2) : const Color(0xFFF2EFFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.sensors_rounded, size: 12, color: theme.primaryStart),
                                          const SizedBox(width: 4),
                                          Text(
                                            'LIVE ENABLED',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: theme.primaryStart,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildSettingRow('⏱ Time Limit', '48 hours', theme, isDark),
                                _buildSettingRow('👥 Max Participants', 'Unlimited', theme, isDark),
                                _buildSettingRow('🏆 Reward Points', '50 pts', theme, isDark, isLast: true),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: GradientButton(
                                text: _postType == 'dare' ? '🚀 Post Dare' : '📣 Publish Post',
                                onPressed: (_isMediaUploading || _isSubmitting) ? null : _handleSubmit,
                                isLoading: _isSubmitting,
                                borderRadius: 20,
                                height: 60,
                              ),
                            ),
                            if (_postType == 'dare') ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  if (_titleController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title first')));
                                    return;
                                  }
                                  Navigator.pushNamed(
                                    context, 
                                    '/broadcaster', 
                                    arguments: {
                                      'channelName': 'dare_${DateTime.now().millisecondsSinceEpoch}',
                                      'title': _titleController.text,
                                    }
                                  );
                                },
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF006E),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF006E).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 28),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeButton(String type, String label, AppTheme theme, bool isDark) {
    bool isSel = _postType == type;
    return GestureDetector(
      onTap: () => setState(() => _postType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? (isDark ? Colors.white10 : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSel && !isDark ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? theme.primaryStart : (isDark ? Colors.white54 : AppColors.muted),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, AppTheme theme, bool isDark, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white54 : AppColors.muted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.primaryStart,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Media', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, {'source': ImageSource.camera, 'isVideo': false}),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record a Video'),
              onTap: () => Navigator.pop(context, {'source': ImageSource.camera, 'isVideo': true}),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose Photo from Gallery'),
              onTap: () => Navigator.pop(context, {'source': ImageSource.gallery, 'isVideo': false}),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose Video from Gallery'),
              onTap: () => Navigator.pop(context, {'source': ImageSource.gallery, 'isVideo': true}),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final isVideo = result['isVideo'] as bool;
    final source = result['source'] as ImageSource;

    final XFile? file = isVideo 
      ? await picker.pickVideo(source: source)
      : await picker.pickImage(source: source, imageQuality: 80);
      
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Try again.')));
        }
      }
    } catch (e) {
      setState(() => _isMediaUploading = false);
    }
  }
}
