import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../providers/dare_provider.dart';
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
  bool _isUploading = false;

  final List<String> _categories = ["🔥 Trending", "💪 Fitness", "😂 Funny", "🎨 Creative", "🌊 Outdoors", "🍕 Food"];
  int _selCatIdx = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingDare != null) {
      _titleController.text = widget.existingDare!['title'] ?? '';
      _descriptionController.text = widget.existingDare!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final dareProv = Provider.of<DareProvider>(context, listen: false);
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      
      final dareData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categories[_selCatIdx],
        'media_url': _mediaUrl,
        'media_type': _mediaType,
        'emoji': _getEmojiForCategory(_categories[_selCatIdx]),
      };

      final bool success;
      if (widget.existingDare != null) {
        success = await dareProv.updateDare(widget.existingDare!['id'], dareData);
      } else {
        success = await dareProv.createDare(dareData, authProv.user);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingDare != null ? 'Dare updated! 💫' : 'Dare posted! Let the games begin 🔥')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dareProv.error ?? 'Failed to process dare')),
        );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 64, 22, 30),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Dare ⚡',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Challenge your followers to something epic',
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
                    // Media Picker
                    GestureDetector(
                      onTap: _pickMedia,
                      child: Container(
                        height: 156,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryStart.withOpacity(0.32),
                            width: 2,
                            style: BorderStyle.solid, // Custom dashed border would need a painter
                          ),
                        ),
                        child: _selectedMedia != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(_selectedMedia!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryStart.withOpacity(0.16),
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
                                      color: AppColors.primaryStart,
                                    ),
                                  ),
                                  Text(
                                    'Tap to upload from gallery',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.muted,
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
                          'Dare Title *',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        Text(
                          '${_titleController.text.length}/60',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.muted,
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
                        color: AppColors.textMain,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Make it catchy...',
                        counterText: '',
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 18),

                    // Description
                    Text(
                      'Description',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textMain,
                        height: 1.6,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Describe the dare, rules, and what completion looks like...',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Category
                    Text(
                      'Category',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
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
                              gradient: isSelected ? AppColors.primaryGradient : null,
                              color: isSelected ? null : const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: AppColors.primaryStart.withOpacity(0.3),
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
                                color: isSelected ? Colors.white : AppColors.primaryStart,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Settings Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryStart.withOpacity(0.07),
                            blurRadius: 20,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                                  color: AppColors.textMain,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2EFFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sensors_rounded, size: 12, color: AppColors.primaryStart),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LIVE ENABLED',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryStart,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSettingRow('⏱ Time Limit', '48 hours'),
                          _buildSettingRow('👥 Max Participants', 'Unlimited'),
                          _buildSettingRow('🏆 Reward Points', '50 pts', isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            text: '🚀 Post Dare',
                            onPressed: _handleSubmit,
                            borderRadius: 20,
                            height: 60,
                          ),
                        ),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryStart,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() {
      _selectedMedia = File(file.path);
      _isUploading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.uploadFile('/dares/upload-media', file.path, 'media');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _mediaUrl = data['data']['mediaUrl'];
          _mediaType = data['data']['mediaType'];
          _isUploading = false;
        });
      } else {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Try again.')));
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }
}
