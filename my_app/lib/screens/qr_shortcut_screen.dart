import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'event_qr_scan_screen.dart';
import 'my_qr_screen.dart';

/// Entry point opened from the jemaat bottom navigation bar's center QR
/// button — a quick-access fork between showing one's own member QR and
/// scanning an ibadah/event QR to self-check-in.
class QrShortcutScreen extends StatelessWidget {
  const QrShortcutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Akses QR'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih salah satu fitur QR di bawah ini',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutralMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _QrOptionCard(
                icon: Icons.qr_code_2_rounded,
                title: 'QR Jemaat Saya',
                subtitle: 'Tampilkan kode QR pribadi untuk presensi kehadiran.',
                accentColor: AppTheme.goldDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyQrScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _QrOptionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan QR Ibadah',
                subtitle: 'Pindai kode QR ibadah/acara untuk mencatat kehadiran Anda.',
                accentColor: AppTheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventQrScanScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _QrOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.neutralBorder),
            boxShadow: AppTheme.cardShadow(),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.neutralMedium,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.neutralMuted),
            ],
          ),
        ),
      ),
    );
  }
}
