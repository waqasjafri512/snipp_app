import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/group_provider.dart';
import '../providers/theme_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  XFile? _imageFile;
  bool _isLoading = false;

  void _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
  }

  void _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a group name')));
      return;
    }

    setState(() => _isLoading = true);

    final groupProv = Provider.of<GroupProvider>(context, listen: false);
    final success = await groupProv.createGroup(name, _descController.text.trim(), imagePath: _imageFile?.path);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group created successfully!')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create group')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final theme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, color: theme.primaryStart),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'New Group',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                color: theme.textMain,
              ),
            ),
            actions: [
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: theme.primaryStart, strokeWidth: 2))),
                )
              else
                TextButton(
                  onPressed: _createGroup,
                  child: Text(
                    'Create',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.primaryStart,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF0EEFF)),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.primaryStart.withOpacity(0.5), width: 2),
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _imageFile == null
                        ? Icon(Icons.camera_alt_rounded, color: theme.primaryStart, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: theme.textMain, fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    labelStyle: TextStyle(color: theme.primaryStart),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryStart, width: 2)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!, width: 1)),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _descController,
                  style: TextStyle(color: theme.textMain),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryStart, width: 2)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!, width: 1)),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'You can add members after creating the group.',
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
