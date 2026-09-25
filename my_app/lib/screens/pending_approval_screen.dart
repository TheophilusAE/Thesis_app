import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';

/// Shown by `_AuthGate` when a session exists but the admin has not approved
/// the account yet (or has rejected it). It is the only screen such an
/// account can reach, so approval can't be bypassed by navigating elsewhere.
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rejected = auth.blockedStatus == 'rejected';

    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  rejected ? Icons.block_rounded : Icons.hourglass_top_rounded,
                  size: 64,
                  color: rejected ? AppTheme.errorColor : AppTheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  rejected ? 'Pendaftaran Ditolak' : 'Registrasi Berhasil',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  rejected
                      ? 'Pendaftaran akun Anda ditolak. Silakan hubungi admin gereja.'
                      : 'Akun Anda sedang menunggu verifikasi admin gereja.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppTheme.mutedCharcoal,
                  ),
                ),
                const SizedBox(height: 28),
                if (!rejected) ...[
                  AppButton.primary(
                    label: 'Periksa Status',
                    isLoading: auth.isLoading,
                    onPressed: auth.isLoading ? null : auth.refreshApprovalStatus,
                  ),
                  const SizedBox(height: 12),
                ],
                AppButton.outline(
                  label: 'Keluar',
                  onPressed: auth.logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
