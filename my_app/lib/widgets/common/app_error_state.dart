import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'app_button.dart';

/// Friendly, actionable error display for GPDI Church App.
/// Replaces raw technical stacktraces with clear Indonesian messages and retry actions.
class AppErrorState extends StatelessWidget {
  final Object? error;
  final String? customMessage;
  final String? message;
  final String? title;
  final VoidCallback? onRetry;
  final bool isCompact;

  const AppErrorState({
    super.key,
    this.error,
    this.customMessage,
    this.message,
    this.title,
    this.onRetry,
    this.isCompact = false,
  });

  static String mapErrorMessage(Object? error) {
    if (error == null) return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
    final raw = error.toString().toLowerCase();

    if (raw.contains('network') || raw.contains('socket') || raw.contains('failed host lookup') || raw.contains('connection refused')) {
      return 'Koneksi internet bermasalah. Pastikan perangkat Anda terhubung ke internet lalu coba lagi.';
    }
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'Waktu koneksi habis. Silakan periksa jaringan dan coba lagi.';
    }
    if (raw.contains('unauthorized') || raw.contains('jwt') || raw.contains('token')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }
    if (raw.contains('permission') || raw.contains('denied') || raw.contains('not permitted')) {
      return 'Akses tidak diizinkan. Hubungi administrator jika membutuhkan akses ini.';
    }
    if (raw.contains('not found') || raw.contains('404')) {
      return 'Data yang dicari tidak ditemukan.';
    }
    return 'Terjadi kendala saat memuat data. Silakan coba beberapa saat lagi.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTitle = title ?? 'Terjadi Kendala';
    final effectiveMessage = message ?? customMessage ?? mapErrorMessage(error);

    if (isCompact) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                effectiveMessage,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.errorColor,
                  height: 1.4,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.errorColor),
                onPressed: onRetry,
                tooltip: 'Coba lagi',
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorLight,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
              ),
            ),
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
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                label: 'Coba Lagi',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
