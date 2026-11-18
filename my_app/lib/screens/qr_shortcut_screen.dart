import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/permissions.dart';
import '../widgets/member_qr_image.dart';
import 'event_qr_scan_screen.dart';
import 'qr_attendance_scan_screen.dart';

/// What the "Scan QR" button opens for the signed-in account.
enum QrScanMode {
  /// Jemaat: scan the check-in code shown at a service or event.
  selfCheckIn,

  /// Pelayan / admin with `kehadiran:create`: scan members' cards.
  staff,
}

/// Same rule as the database's `is_checkin_staff()`: pelayan or kehadiran:create.
QrScanMode qrScanModeFor(AuthProvider auth) {
  final role = auth.currentDisplayRole;
  if (role == 'jemaat') return QrScanMode.selfCheckIn;
  final staff = auth.isPelayan || auth.can(AppModule.kehadiran, PermissionAction.create);
  return staff ? QrScanMode.staff : QrScanMode.selfCheckIn;
}

/// Opens the QR sheet from the center button of the bottom navigation bar:
/// the member's own QR (large) and a "Scan QR" button.
Future<void> showQrAccessSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const QrAccessSheet(),
  );
}

class QrAccessSheet extends StatelessWidget {
  const QrAccessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final mode = qrScanModeFor(auth);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7);
    final qrSize = (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 280.0);

    void close() => Navigator.of(context).pop();

    void scan() {
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.push(MaterialPageRoute(
        builder: (_) => mode == QrScanMode.staff ? const QrAttendanceScanScreen() : const EventQrScanScreen(),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.dialogTheme.backgroundColor ?? scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, 16 + MediaQuery.paddingOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Kembali',
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: close,
                ),
                Expanded(
                  child: Text(
                    'QR Saya',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: close,
                ),
              ],
            ),
            Text('Kode QR pribadi Anda', style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.neutralBorder),
              ),
              child: user == null
                  ? SizedBox(
                      width: qrSize,
                      height: qrSize,
                      child: const Center(child: Text('QR belum tersedia', style: TextStyle(color: Colors.black54))),
                    )
                  : MemberQrImage(user: user, size: qrSize),
            ),
            const SizedBox(height: 24),
            Text('Kode QR Anda', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tunjukkan kode QR ini untuk dipindai.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: scan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan QR'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mode == QrScanMode.staff
                  ? 'Untuk memindai kartu anggota jemaat (presensi ibadah/event).'
                  : 'Untuk memindai QR presensi ibadah atau event.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
