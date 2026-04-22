import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
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

  File? _selectedAvatar;
  String? _avatarUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).userProfile;
    _avatarUrl = profile?['avatar'];
    _nameController = TextEditingController(text: profile?['full_name'] ?? '');
    _bioController = TextEditingController(text: profile?['bio'] ?? '');
    _locationController = TextEditingController(text: profile?['location'] ?? '');
    _websiteController = TextEditingController(text: profile?['website'] ?? '');
    _categoryController = TextEditingController(text: profile?['category'] ?? '');
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (file == null) return;

    setState(() {
      _selectedAvatar = File(file.path);
      _isUploading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.uploadFile('/profile/upload-avatar', file.path, 'avatar');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _avatarUrl = data['data']['avatarUrl'];
          _isUploading = false;
        });
        if (mounted) {
          final userId = Provider.of<AuthProvider>(context, listen: false).user?['id'];
          if (userId != null) {
            Provider.of<ProfileProvider>(context, listen: false).fetchProfile(userId);
          }
        }
      } else {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profileProv = Provider.of<ProfileProvider>(context, listen: false);
      final success = await profileProv.updateProfile({
        'full_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        'category': _categoryController.text.trim(),
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profileProv.error ?? 'Update failed')),
        );
      }
    }
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EFFF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close_rounded, color: AppColors.primaryStart, size: 22),
                    ),
                  ),
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveProfile,
                    child: Text(
                      'Save',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryStart,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                image: _selectedAvatar != null
                                    ? DecorationImage(image: FileImage(_selectedAvatar!), fit: BoxFit.cover)
                                    : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                        ? DecorationImage(image: NetworkImage(AppConstants.getMediaUrl(_avatarUrl)), fit: BoxFit.cover)
                                        : null,
                              ),
                              alignment: Alignment.center,
                              child: (_selectedAvatar == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                                  ? const Text(
                                      'U',
                                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                                    )
                                  : null,
                            ),
                            if (_isUploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primaryStart),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildModernField('Full Name', _nameController, Icons.person_outline_rounded),
                      const SizedBox(height: 20),
                      
                      _buildModernField('Bio', _bioController, Icons.info_outline_rounded, maxLines: 3),
                      const SizedBox(height: 20),
                      
                      _buildModernField('Location', _locationController, Icons.location_on_outlined),
                      const SizedBox(height: 20),

                      _buildModernField('Category', _categoryController, Icons.category_outlined),
                      const SizedBox(height: 20),
                      
                      _buildModernField('Website', _websiteController, Icons.link_rounded, keyboardType: TextInputType.url),
                      
                      const SizedBox(height: 32),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Professional Account',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  Text(
                                    'Unlock more insights and tools',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.primaryStart),
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
  }

  Widget _buildModernField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textMain,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryStart.withOpacity(0.5), size: 20),
            hintText: 'Enter your $label',
            fillColor: const Color(0xFFF2EFFF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
