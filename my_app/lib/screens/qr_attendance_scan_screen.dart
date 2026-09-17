import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/attendance_confirmation.dart';
import '../models/service_schedule.dart';
import '../providers/attendance_confirmation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_schedule_provider.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import '../utils/qr_payload.dart';
import '../widgets/common/app_empty_state.dart';

/// Pelayan-facing screen: pick today's service schedule, then scan a
/// member's QR card to mark them present.
class QrAttendanceScanScreen extends StatefulWidget {
  const QrAttendanceScanScreen({super.key});

  @override
  State<QrAttendanceScanScreen> createState() => _QrAttendanceScanScreenState();
}

class _QrAttendanceScanScreenState extends State<QrAttendanceScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final SupabaseService _supabaseService = SupabaseService();

  bool _permissionGranted = false;
  bool _checkingPermission = true;
  bool _isProcessing = false;
  bool _torchOn = false;
  ServiceSchedule? _selectedSchedule;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
      _checkingPermission = false;
    });
    if (_permissionGranted) {
      await context.read<ServiceScheduleProvider>().loadSchedulesByDate(DateTime.now());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() {
      _torchOn = !_torchOn;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _selectedSchedule == null) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final payload = decodeMemberPayload(raw);
    if (payload == null) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    final profile = await _supabaseService.getUserProfile(payload.userId);
    final memberName = (profile?['nama'] as String?) ?? payload.name;

    if (!mounted) return;
    await _confirmCheckIn(userId: payload.userId, name: memberName);

    if (!mounted) return;
    setState(() => _isProcessing = false);
    await _controller.start();
  }

  Future<void> _confirmCheckIn({required String userId, required String name}) async {
    final schedule = _selectedSchedule!;
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
              child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 22),
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
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.church_rounded, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        schedule.serviceType,
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
              'Tandai kehadiran jemaat ini pada jadwal ibadah yang dipilih?',
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

    final auth = context.read<AuthProvider>();
    final provider = context.read<AttendanceConfirmationProvider>();
    final now = DateTime.now();
    final success = await provider.createOrUpdateConfirmation(
      AttendanceConfirmation(
        id: '',
        userId: userId,
        userName: name,
        serviceScheduleId: schedule.id,
        scheduleDate: schedule.serviceDate,
        confirmed: true,
        confirmedAt: now,
        checkInMethod: 'qr',
        checkedInBy: auth.currentUser?.id,
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
                success ? '$name berhasil ditandai hadir' : 'Gagal mencatat kehadiran',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Kehadiran'),
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
              ? _PermissionDenied(onRetry: _init)
              : Column(
                  children: [
                    // Schedule Picker Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.warmIvory,
                      child: Consumer<ServiceScheduleProvider>(
                        builder: (context, scheduleProvider, _) {
                          final todaysSchedules = scheduleProvider.filteredSchedules;
                          if (todaysSchedules.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.info_outline_rounded, color: Color(0xFF92400E), size: 18),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tidak ada jadwal ibadah terdaftar untuk hari ini.',
                                      style: TextStyle(
                                        color: Color(0xFF92400E),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          _selectedSchedule ??= todaysSchedules.first;

                          return DropdownButtonFormField<ServiceSchedule>(
                            initialValue: todaysSchedules.contains(_selectedSchedule)
                                ? _selectedSchedule
                                : todaysSchedules.first,
                            decoration: InputDecoration(
                              labelText: 'Ibadah yang Berlangsung',
                              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              prefixIcon: const Icon(Icons.church_rounded, color: AppTheme.primary, size: 20),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.neutralBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.neutralBorder),
                              ),
                            ),
                            items: todaysSchedules
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        '${s.serviceType} (${s.startTime} - ${s.endTime})',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (s) => setState(() => _selectedSchedule = s),
                          );
                        },
                      ),
                    ),

                    // Scanner Viewport
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          MobileScanner(controller: _controller, onDetect: _onDetect),

                          // Scanner Viewfinder Overlay
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.gold, width: 3),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),

                          // Instruction Banner
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
                                    'Arahkan kamera ke Kartu QR Jemaat',
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
                    ),
                  ],
                ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDenied({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.warmIvory,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: AppEmptyState(
        icon: Icons.camera_alt_outlined,
        title: 'Izin Kamera Dibutuhkan',
        description:
            'Aplikasi membutuhkan izin akses kamera untuk dapat memindai kode QR kartu jemaat digital.',
        actionLabel: 'Berikan Izin Kamera',
        onAction: onRetry,
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
