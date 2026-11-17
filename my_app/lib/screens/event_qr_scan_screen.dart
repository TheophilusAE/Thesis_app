import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/attendance_confirmation.dart';
import '../models/service_schedule.dart';
import '../providers/attendance_confirmation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_schedule_provider.dart';
import '../utils/app_theme.dart';
import '../utils/qr_payload.dart';
import '../widgets/common/app_empty_state.dart';

/// Jemaat-facing screen: scans an ibadah/event QR (displayed by an
/// admin/pelayan, see `ServiceScheduleManagementScreen`) and self-checks the
/// logged-in jemaat in for that service schedule.
///
/// Mirrors the permission-handling shell of [QrAttendanceScanScreen] (same
/// camera setup pattern), but the scan/check-in logic is intentionally
/// separate: that screen lets a *pelayan* check in *another* member from a
/// member-card QR, while this one lets a *jemaat* self-check-in from a
/// *service* QR — different payload, different writer, different RLS path.
class EventQrScanScreen extends StatefulWidget {
  const EventQrScanScreen({super.key});

  @override
  State<EventQrScanScreen> createState() => _EventQrScanScreenState();
}

class _EventQrScanScreenState extends State<EventQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _permissionGranted = false;
  bool _permissionPermanentlyDenied = false;
  bool _checkingPermission = true;
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    var status = await Permission.camera.status;
    if (!status.isGranted && !status.isPermanentlyDenied && !status.isRestricted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
      _permissionPermanentlyDenied = status.isPermanentlyDenied || status.isRestricted;
      _checkingPermission = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final payload = decodeServiceCheckinPayload(raw);
    if (payload == null) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    if (!mounted) return;
    await _handleScheduleFound(payload.scheduleId);

    if (!mounted) return;
    setState(() => _isProcessing = false);
    await _controller.start();
  }

  Future<void> _handleScheduleFound(String scheduleId) async {
    final scheduleProvider = context.read<ServiceScheduleProvider>();
    if (scheduleProvider.allSchedules.isEmpty) {
      await scheduleProvider.loadAllSchedules();
    }
    if (!mounted) return;

    ServiceSchedule? schedule;
    for (final s in scheduleProvider.allSchedules) {
      if (s.id == scheduleId) {
        schedule = s;
        break;
      }
    }

    if (schedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal ibadah untuk kode QR ini tidak ditemukan.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    await _confirmCheckIn(schedule);
  }

  Future<void> _confirmCheckIn(ServiceSchedule schedule) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.church_rounded, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Konfirmasi Presensi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warmIvory,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neutralBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.serviceType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.neutralMedium),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(schedule.serviceDate),
                        style: const TextStyle(fontSize: 13, color: AppTheme.darkCharcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.neutralMedium),
                      const SizedBox(width: 6),
                      Text(
                        '${schedule.startTime} - ${schedule.endTime} WIB',
                        style: const TextStyle(fontSize: 13, color: AppTheme.neutralMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Catat kehadiran Anda pada ibadah ini?',
              style: TextStyle(fontSize: 13, color: AppTheme.neutralMedium, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.neutralMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Tandai Hadir'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<AttendanceConfirmationProvider>();
    final now = DateTime.now();
    final success = await provider.createOrUpdateConfirmation(
      AttendanceConfirmation(
        id: '',
        userId: user.id,
        userName: user.name,
        serviceScheduleId: schedule.id,
        scheduleDate: schedule.serviceDate,
        confirmed: true,
        confirmedAt: now,
        checkInMethod: 'qr',
        checkedInBy: null,
        createdAt: now,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success ? 'Kehadiran berhasil dicatat' : 'Gagal mencatat kehadiran',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppTheme.emerald : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Ibadah'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_permissionGranted)
            IconButton(
              icon: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _torchOn ? AppTheme.gold : Colors.white,
              ),
              onPressed: _toggleTorch,
              tooltip: _torchOn ? 'Matikan Lampu' : 'Nyalakan Lampu',
            ),
        ],
      ),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : !_permissionGranted
              ? _PermissionDenied(
                  onRetry: _init,
                  openSettings: _permissionPermanentlyDenied ? openAppSettings : null,
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error, child) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Kamera tidak dapat digunakan saat ini. Tutup lalu buka kembali halaman ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.gold, width: 3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    Positioned(
                      bottom: 36,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Arahkan kamera ke QR Ibadah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppTheme.gold),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  final VoidCallback onRetry;
  final Future<bool> Function()? openSettings;

  const _PermissionDenied({required this.onRetry, this.openSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.warmIvory,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: AppEmptyState(
        icon: Icons.camera_alt_outlined,
        title: 'Izin Kamera Dibutuhkan',
        description: 'Aplikasi membutuhkan izin akses kamera untuk dapat memindai kode QR ibadah.',
        actionLabel: openSettings != null ? 'Buka Pengaturan' : 'Berikan Izin Kamera',
        onAction: openSettings != null ? () => openSettings!() : onRetry,
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
