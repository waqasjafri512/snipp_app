import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class ThemeCenterScreen extends StatelessWidget {
  const ThemeCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProv, _) {
        final currentTheme = themeProv.currentTheme;
        final isDark = themeProv.currentThemeIndex == 1;
        
        return Scaffold(
          backgroundColor: currentTheme.background,
          appBar: AppBar(
            backgroundColor: currentTheme.background,
            elevation: 0,
            title: Text(
              'Theme Center ✨',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: currentTheme.textMain,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: currentTheme.textMain,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF0EEFF)),
            ),
          ),
          body: Stack(
            children: [
              // Decorative background elements
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        currentTheme.primaryStart.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalize your vibe',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: currentTheme.textMain,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose from 10 luxurious presets to transform your experience.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: themeProv.themes.length,
                      itemBuilder: (context, index) {
                        final theme = themeProv.themes[index];
                        final isSelected = themeProv.currentThemeIndex == index;
                        final themeIsDark = index == 1;
                        
                        return GestureDetector(
                          onTap: () => themeProv.setTheme(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isSelected ? theme.primaryStart : (isDark ? Colors.white10 : const Color(0xFFF0EEFF)),
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: theme.primaryStart.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ] : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: theme.gradient,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (isSelected)
                                          const Center(
                                            child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 36),
                                          ),
                                        Positioned(
                                          bottom: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              themeIsDark ? 'DARK' : 'LIGHT',
                                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        theme.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : const Color(0xFF1A1033),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _colorDot(theme.primaryStart),
                                          const SizedBox(width: 4),
                                          _colorDot(theme.primaryMiddle),
                                          const SizedBox(width: 4),
                                          _colorDot(theme.primaryEnd),
                                          const Spacer(),
                                          if (isSelected)
                                            Text(
                                              'Active',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: theme.primaryStart,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
    );
  }
}
