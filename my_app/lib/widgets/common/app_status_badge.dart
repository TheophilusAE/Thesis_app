import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

enum BadgeType {
  success,
  warning,
  error,
  info,
  gold,
  neutral,
}

typedef AppStatusBadgeType = BadgeType;

/// Accessible status badge pairing an icon and a text label.
/// Avoids communicating state solely through color.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeType type;
  final String? status;
  final bool isSmall;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = BadgeType.info,
    this.status,
    this.isSmall = false,
  });

  BadgeType get effectiveType => status != null ? _typeFromStatus(status!) : type;
  IconData get effectiveIcon => icon ?? (status != null ? _iconFromStatus(status!) : Icons.info_outline_rounded);

  static BadgeType _typeFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'selesai':
      case 'terjawab':
      case 'active':
      case 'hadir':
      case 'aktif':
        return BadgeType.success;
      case 'warning':
      case 'pending':
      case 'menunggu':
      case 'didoakan':
        return BadgeType.warning;
      case 'rejected':
      case 'batal':
      case 'cancelled':
      case 'tidak hadir':
      case 'penuh':
        return BadgeType.error;
      case 'admin':
      case 'gold':
        return BadgeType.gold;
      default:
        return BadgeType.info;
    }
  }

  static IconData _iconFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'selesai':
      case 'terjawab':
      case 'active':
      case 'hadir':
      case 'aktif':
        return Icons.check_circle_rounded;
      case 'warning':
      case 'pending':
      case 'menunggu':
      case 'didoakan':
        return Icons.schedule_rounded;
      case 'rejected':
      case 'batal':
      case 'cancelled':
      case 'tidak hadir':
      case 'penuh':
        return Icons.cancel_rounded;
      case 'admin':
      case 'gold':
        return Icons.shield_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  factory AppStatusBadge.success({required String label, IconData icon = Icons.check_circle_rounded, bool isSmall = false}) {
    return AppStatusBadge(label: label, icon: icon, type: BadgeType.success, isSmall: isSmall);
  }

  factory AppStatusBadge.warning({required String label, IconData icon = Icons.schedule_rounded, bool isSmall = false}) {
    return AppStatusBadge(label: label, icon: icon, type: BadgeType.warning, isSmall: isSmall);
  }

  factory AppStatusBadge.error({required String label, IconData icon = Icons.cancel_rounded, bool isSmall = false}) {
    return AppStatusBadge(label: label, icon: icon, type: BadgeType.error, isSmall: isSmall);
  }

  factory AppStatusBadge.info({required String label, IconData icon = Icons.info_outline_rounded, bool isSmall = false}) {
    return AppStatusBadge(label: label, icon: icon, type: BadgeType.info, isSmall: isSmall);
  }

  factory AppStatusBadge.gold({required String label, IconData icon = Icons.star_rounded, bool isSmall = false}) {
    return AppStatusBadge(label: label, icon: icon, type: BadgeType.gold, isSmall: isSmall);
  }

  factory AppStatusBadge.role({required String role, bool isSmall = false}) {
    final lower = role.toLowerCase();
    if (lower == 'admin') {
      return AppStatusBadge(
        label: 'Admin',
        icon: Icons.shield_rounded,
        type: BadgeType.gold,
        isSmall: isSmall,
      );
    } else if (lower == 'pelayan') {
      return AppStatusBadge(
        label: 'Pelayan',
        icon: Icons.volunteer_activism_rounded,
        type: BadgeType.info,
        isSmall: isSmall,
      );
    } else {
      return AppStatusBadge(
        label: 'Jemaat',
        icon: Icons.person_rounded,
        type: BadgeType.success,
        isSmall: isSmall,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (effectiveType) {
      case BadgeType.success:
        bg = AppTheme.successLight;
        fg = AppTheme.successColor;
        border = AppTheme.successColor.withValues(alpha: 0.25);
        break;
      case BadgeType.warning:
        bg = AppTheme.warningLight;
        fg = AppTheme.warningColor;
        border = AppTheme.warningColor.withValues(alpha: 0.25);
        break;
      case BadgeType.error:
        bg = AppTheme.errorLight;
        fg = AppTheme.errorColor;
        border = AppTheme.errorColor.withValues(alpha: 0.25);
        break;
      case BadgeType.info:
        bg = AppTheme.infoLight;
        fg = AppTheme.infoColor;
        border = AppTheme.infoColor.withValues(alpha: 0.25);
        break;
      case BadgeType.gold:
        bg = AppTheme.goldLight;
        fg = AppTheme.goldDark;
        border = AppTheme.gold.withValues(alpha: 0.35);
        break;
      case BadgeType.neutral:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        border = const Color(0xFFE2E8F0);
        break;
    }

    final double padH = isSmall ? 8 : 10;
    final double padV = isSmall ? 4 : 5;
    final double iconSize = isSmall ? 13 : 15;
    final double fontSize = isSmall ? 11.5 : 13;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(effectiveIcon, size: iconSize, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
