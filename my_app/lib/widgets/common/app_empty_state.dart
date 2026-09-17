import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'app_button.dart';

/// Meaningful, friendly empty state component for GPDI Church App.
/// Clearly explains:
/// 1. What is empty
/// 2. Why it may be empty
/// 3. What the user can do next (optional action)
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  String get effectiveMessage =>
      (message != null && message!.isNotEmpty) ? message! : (description ?? '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = iconColor ?? (isDark ? const Color(0xFFE56A7A) : AppTheme.primary);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2E2B30) : AppTheme.primaryLight,
              ),
              child: Icon(
                icon,
                size: 42,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
              ),
            ),
            if (effectiveMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                effectiveMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFFA5A1A8) : AppTheme.secondaryText,
                  height: 1.45,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
