import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  gold,
  text,
}

/// Accessible, modern, all-generation button component for GPDI Church App.
/// - Minimum 48-52dp touch target
/// - Clear loading spinner state
/// - Support for leading/trailing icons
/// - High-contrast text
class AppButton extends StatelessWidget {
  final String? label;
  final String? text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isTrailingIcon;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? textColor;

  String get effectiveLabel => label ?? text ?? '';

  const AppButton({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isTrailingIcon = false,
    this.isLoading = false,
    this.width,
    this.height = 52.0,
    this.padding,
    this.color,
    this.textColor,
  });

  const AppButton.primary({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.icon,
    this.isTrailingIcon = false,
    this.isLoading = false,
    this.width,
    this.height = 52.0,
    this.padding,
    this.color,
    this.textColor,
  }) : variant = AppButtonVariant.primary;

  const AppButton.outline({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.icon,
    this.isTrailingIcon = false,
    this.isLoading = false,
    this.width,
    this.height = 52.0,
    this.padding,
    this.color,
    this.textColor,
  }) : variant = AppButtonVariant.outline;

  const AppButton.secondary({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.icon,
    this.isTrailingIcon = false,
    this.isLoading = false,
    this.width,
    this.height = 52.0,
    this.padding,
    this.color,
    this.textColor,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.gold({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.icon,
    this.isTrailingIcon = false,
    this.isLoading = false,
    this.width,
    this.height = 52.0,
    this.padding,
    this.color,
    this.textColor,
  }) : variant = AppButtonVariant.gold;

  const AppButton.text({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.icon,
    this.isTrailingIcon = false,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
    this.padding,
    this.color,
    this.textColor,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = color ?? AppTheme.primary;
        fg = textColor ?? Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = color ?? (isDark ? const Color(0xFF262328) : AppTheme.primaryLight);
        fg = textColor ?? (isDark ? Colors.white : AppTheme.primaryDark);
        break;
      case AppButtonVariant.outline:
        bg = color ?? (isDark ? Colors.transparent : Colors.white);
        fg = textColor ?? (isDark ? const Color(0xFFE56A7A) : AppTheme.primary);
        border = BorderSide(
          color: textColor ?? (isDark ? const Color(0xFFE56A7A) : AppTheme.primary),
          width: 1.5,
        );
        break;
      case AppButtonVariant.gold:
        bg = color ?? AppTheme.gold;
        fg = textColor ?? Colors.white;
        break;
      case AppButtonVariant.text:
        bg = color ?? Colors.transparent;
        fg = textColor ?? (isDark ? const Color(0xFFE56A7A) : AppTheme.primary);
        break;
    }

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget childContent;
    if (isLoading) {
      childContent = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      final textWidget = Text(
        effectiveLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: effectiveOnPressed == null ? fg.withValues(alpha: 0.5) : fg,
          letterSpacing: 0.2,
        ),
      );

      if (icon != null) {
        final iconWidget = Icon(icon, size: 20, color: effectiveOnPressed == null ? fg.withValues(alpha: 0.5) : fg);
        childContent = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: isTrailingIcon
              ? [Flexible(child: textWidget), const SizedBox(width: 8), iconWidget]
              : [iconWidget, const SizedBox(width: 8), Flexible(child: textWidget)],
        );
      } else {
        childContent = textWidget;
      }
    }

    Widget button;
    if (variant == AppButtonVariant.text) {
      button = TextButton(
        onPressed: effectiveOnPressed,
        style: TextButton.styleFrom(
          foregroundColor: fg,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: Size(width ?? 48, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: childContent,
      );
    } else {
      button = Material(
        color: effectiveOnPressed == null ? bg.withValues(alpha: 0.6) : bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border,
        ),
        elevation: 0,
        child: InkWell(
          onTap: effectiveOnPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: height,
            width: width,
            alignment: Alignment.center,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
            child: childContent,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: effectiveLabel,
      child: button,
    );
  }
}
