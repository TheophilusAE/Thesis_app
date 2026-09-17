import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'common/app_status_badge.dart';

/// Accessible role switcher component for GPDI Church App.
/// Provides a clear, intentional experience for congregation members,
/// ministers, and admins who hold multiple church roles.
class RoleSwitcher extends StatelessWidget {
  final bool showBadgeIfSingleRole;

  const RoleSwitcher({
    super.key,
    this.showBadgeIfSingleRole = true,
  });

  static String getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'pelayan':
        return 'Pelayan';
      case 'jemaat':
        return 'Jemaat';
      default:
        return role;
    }
  }

  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.shield_rounded;
      case 'pelayan':
        return Icons.volunteer_activism_rounded;
      case 'jemaat':
      default:
        return Icons.person_rounded;
    }
  }

  static String getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Kelola jemaat, jadwal pelayanan, kehadiran, dan administrasi gereja';
      case 'pelayan':
        return 'Lihat jadwal tugas, konfirmasi kehadiran, scan QR, dan jadwal latihan';
      case 'jemaat':
      default:
        return 'Ikuti ibadah, renungan harian, pembacaan Alkitab, event, dan komsel';
    }
  }

  static void showRolePickerSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userRoles = auth.userRoles;
    final currentRole = auth.currentDisplayRole;

    if (userRoles.length <= 1) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1C1F) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3E3B40) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF4A131A) : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.switch_account_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Mode Peran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Beralih mode aplikasi dengan aman tanpa keluar akun',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFA5A1A8) : AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...userRoles.map((role) {
                final isSelected = role == currentRole;
                final label = getRoleLabel(role);
                final icon = getRoleIcon(role);
                final desc = getRoleDescription(role);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF2A1519) : AppTheme.primaryLight.withValues(alpha: 0.5))
                        : (isDark ? const Color(0xFF262328) : const Color(0xFFFBFBFB)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : (isDark ? const Color(0xFF3E3B40) : const Color(0xFFE5E7EB)),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (!isSelected) {
                          auth.switchRole(role);
                          Navigator.pop(bottomSheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Beralih ke mode: $label',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.primary,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          Navigator.pop(bottomSheetContext);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : (isDark ? const Color(0xFF3E3B40) : const Color(0xFFEDEDED)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? Colors.white : AppTheme.secondaryText,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text(
                                            'Aktif',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFFA5A1A8) : AppTheme.secondaryText,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? AppTheme.primary : AppTheme.mutedText,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userRoles = authProvider.userRoles;
        final currentRole = authProvider.currentDisplayRole;

        if (userRoles.length <= 1) {
          if (!showBadgeIfSingleRole) return const SizedBox.shrink();
          return AppStatusBadge.role(role: currentRole);
        }

        final label = getRoleLabel(currentRole);
        final icon = getRoleIcon(currentRole);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showRolePickerSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
