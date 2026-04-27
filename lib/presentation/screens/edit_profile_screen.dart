import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../data/repositories/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/gradient_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _categoryController;
  late TextEditingController _worksAtController;
  late TextEditingController _studiedAtController;
  late TextEditingController _fromLocationController;

  File? _selectedAvatar;
  File? _selectedCover;
  String? _avatarUrl;
  String? _coverUrl;
  bool _isAvatarUploading = false;
  bool _isCoverUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).userProfile;
    _avatarUrl = profile?['avatar_url'];
    _coverUrl = profile?['cover_url'];
    _nameController = TextEditingController(text: profile?['full_name'] ?? '');
    _bioController = TextEditingController(text: profile?['bio'] ?? '');
    _locationController = TextEditingController(text: profile?['location'] ?? '');
    _websiteController = TextEditingController(text: profile?['website'] ?? '');
    _categoryController = TextEditingController(text: profile?['category'] ?? '');
    _worksAtController = TextEditingController(text: profile?['works_at'] ?? '');
    _studiedAtController = TextEditingController(text: profile?['studied_at'] ?? '');
    _fromLocationController = TextEditingController(text: profile?['from_location'] ?? '');
  }

  Future<void> _pickImage({required bool isAvatar}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (file == null) return;

    setState(() {
      if (isAvatar) {
        _selectedAvatar = File(file.path);
        _isAvatarUploading = true;
      } else {
        _selectedCover = File(file.path);
        _isCoverUploading = true;
      }
    });

    try {
      final apiService = ApiService();
      final endpoint = isAvatar ? '/profile/upload-avatar' : '/profile/upload-cover';
      final fieldName = isAvatar ? 'avatar' : 'cover';
      
      final response = await apiService.uploadFile(endpoint, file.path, fieldName);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          if (isAvatar) {
            _avatarUrl = data['data']['avatarUrl'];
            _isAvatarUploading = false;
          } else {
            _coverUrl = data['data']['coverUrl'];
            _isCoverUploading = false;
          }
        });
        if (mounted) {
          final userId = Provider.of<AuthProvider>(context, listen: false).user?['id'];
          if (userId != null) {
            Provider.of<ProfileProvider>(context, listen: false).fetchProfile(userId);
          }
        }
      } else {
        setState(() {
          _isAvatarUploading = false;
          _isCoverUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAvatarUploading = false;
        _isCoverUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _categoryController.dispose();
    _worksAtController.dispose();
    _studiedAtController.dispose();
    _fromLocationController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final profileProv = Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProv.updateProfile({
        'full_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        'category': _categoryController.text.trim(),
        'works_at': _worksAtController.text.trim(),
        'studied_at': _studiedAtController.text.trim(),
        'from_location': _fromLocationController.text.trim(),
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profileProv.error ?? 'Update failed')),
        );
      }
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
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  decoration: BoxDecoration(color: theme.background),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close_rounded, color: theme.textMain, size: 26),
                      ),
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.textMain,
                        ),
                      ),
                      _isSaving 
                        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: theme.primaryStart, strokeWidth: 2))
                        : GestureDetector(
                            onTap: _saveProfile,
                            child: Icon(Icons.check_rounded, color: theme.primaryStart, size: 28),
                          ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cover and Avatar Picker
                          Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // Cover Picker
                              GestureDetector(
                                onTap: () => _pickImage(isAvatar: false),
                                child: Container(
                                  height: 180,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.grey[200],
                                    image: _selectedCover != null
                                        ? DecorationImage(image: FileImage(_selectedCover!), fit: BoxFit.cover)
                                        : (_coverUrl != null && _coverUrl!.isNotEmpty)
                                            ? DecorationImage(image: NetworkImage(AppConstants.getMediaUrl(_coverUrl)), fit: BoxFit.cover)
                                            : null,
                                  ),
                                  child: Stack(
                                    children: [
                                      if (_coverUrl == null && _selectedCover == null)
                                        Center(child: Icon(Icons.camera_alt_rounded, color: isDark ? Colors.white24 : Colors.grey, size: 40)),
                                      if (_isCoverUploading)
                                        Center(child: CircularProgressIndicator(color: theme.primaryStart)),
                                      Positioned(
                                        bottom: 10,
                                        right: 16,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Avatar Picker overlapping cover
                              Positioned(
                                bottom: -50,
                                child: GestureDetector(
                                  onTap: () => _pickImage(isAvatar: true),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: theme.background,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: theme.background, width: 4),
                                          image: _selectedAvatar != null
                                              ? DecorationImage(image: FileImage(_selectedAvatar!), fit: BoxFit.cover)
                                              : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                                  ? DecorationImage(image: NetworkImage(AppConstants.getMediaUrl(_avatarUrl)), fit: BoxFit.cover)
                                                  : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: (_selectedAvatar == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                                            ? Text(
                                                'U',
                                                style: TextStyle(color: theme.primaryStart, fontSize: 40, fontWeight: FontWeight.w800),
                                              )
                                            : null,
                                      ),
                                      if (_isAvatarUploading)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(gradient: theme.gradient, shape: BoxShape.circle),
                                          child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60),
                          
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildModernField('Full Name', _nameController, Icons.person_rounded, theme, isDark),
                                const SizedBox(height: 16),
                                _buildModernField('Bio', _bioController, Icons.info_rounded, theme, isDark, maxLines: 3),
                                const SizedBox(height: 16),
                                _buildModernField('Location (Current)', _locationController, Icons.location_on_rounded, theme, isDark),
                                const SizedBox(height: 16),
                                _buildModernField('From (Hometown)', _fromLocationController, Icons.home_rounded, theme, isDark),
                                const SizedBox(height: 16),
                                _buildModernField('Works at', _worksAtController, Icons.work_rounded, theme, isDark),
                                const SizedBox(height: 16),
                                _buildModernField('Studied at', _studiedAtController, Icons.school_rounded, theme, isDark),
                                const SizedBox(height: 16),
                                _buildModernField('Category', _categoryController, Icons.category_rounded, theme, isDark),
                                const SizedBox(height: 16),
                                _buildModernField('Website', _websiteController, Icons.link_rounded, theme, isDark, keyboardType: TextInputType.url),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildModernField(String label, TextEditingController controller, IconData icon, AppTheme theme, bool isDark, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: theme.textMain,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textMain),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: theme.primaryStart.withOpacity(0.7), size: 20),
            hintText: 'Enter your $label',
            hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryStart),
            ),
          ),
        ),
      ],
    );
  }
}
