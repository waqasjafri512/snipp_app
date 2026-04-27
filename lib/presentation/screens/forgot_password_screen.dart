import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProv.forgotPassword(email);

    if (result['success'] && mounted) {
      setState(() => _isSent = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final theme = themeProv.currentTheme;
    final isDark = themeProv.currentThemeIndex == 1;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.primaryStart.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.lock_reset_rounded, color: theme.primaryStart, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              _isSent ? 'Check your email' : 'Forgot Password?',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: theme.textMain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isSent 
                ? 'We have sent a password recovery link to your email address. Please check your inbox and spam folder.'
                : 'No worries! Enter your email address below and we will send you a link to reset your password.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: isDark ? Colors.white54 : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (!_isSent) ...[
              Text(
                'Email Address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.textMain,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: theme.textMain),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                  filled: true,
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: theme.primaryStart.withOpacity(0.5), size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Send Reset Link',
                isLoading: Provider.of<AuthProvider>(context).isLoading,
                onPressed: _handleSubmit,
                borderRadius: 20,
                height: 60,
              ),
            ] else ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: theme.primaryStart.withOpacity(0.1),
                  ),
                  child: Text('Back to Login', style: GoogleFonts.plusJakartaSans(color: theme.primaryStart, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
