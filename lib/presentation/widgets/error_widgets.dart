import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable error banner widget that slides down from the top of the screen.
/// Shows connectivity issues and API errors with retry functionality.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isOffline;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOffline ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOffline ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            color: isOffline ? const Color(0xFFD97706) : const Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOffline ? const Color(0xFF92400E) : const Color(0xFF991B1B),
              ),
            ),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOffline
                      ? const Color(0xFFF59E0B).withOpacity(0.2)
                      : const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isOffline ? const Color(0xFFD97706) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          if (onDismiss != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isOffline ? const Color(0xFFD97706) : const Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An empty state widget with an icon, title, and optional action button.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor ?? (isDark ? Colors.white38 : Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1033),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A loading overlay that shows a translucent backdrop with a spinner.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
