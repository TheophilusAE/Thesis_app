import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/checkin_provider.dart';
import '../providers/ibadah_provider.dart';
import '../services/event_service.dart';
import '../utils/app_theme.dart';
import '../utils/qr_payload.dart';
import '../widgets/common/app_empty_state.dart';

/// One thing a pelayan can check people in to today.
class _Target {
  final String type; // CheckinTarget.occurrence / .event
  final String id;
  final String label;
  const _Target(this.type, this.id, this.label);
}

/// Pelayan/admin screen: choose today's worship service or event, then scan
/// members' card QRs. The database (`staff_check_in`) verifies the card's
/// secret, the time window and — for events — that the member booked, and
/// never records the same person twice.
class QrAttendanceScanScreen extends StatefulWidget {
  /// Loads today's events; injectable for tests.
  final Future<List<ChurchEvent>> Function()? eventLoader;

  const QrAttendanceScanScreen({super.key, this.eventLoader});

  @override
  State<QrAttendanceScanScreen> createState() => _QrAttendanceScanScreenState();
}

class _QrAttendanceScanScreenState extends State<QrAttendanceScanScreen> {
  final MobileScannerController _controller = MobileScannerController();

  bool _permissionGranted = false;
  bool _permissionPermanentlyDenied = false;
  bool _checkingPermission = true;
  bool _isProcessing = false;
  bool _torchOn = false;
  bool _loadingTargets = true;
  List<_Target> _targets = [];
  _Target? _selected;

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
    await _loadTargets();
  }

  Future<void> _loadTargets() async {
    final ibadah = context.read<IbadahProvider>();
    final now = DateTime.now();
    await ibadah.load(from: now, days: 1);
    final events = await (widget.eventLoader ?? EventService().getActiveEvents)();
    if (!mounted) return;
    bool sameDay(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;
    final targets = <_Target>[
      for (final o in ibadah.occurrencesOn(now))
        _Target(CheckinTarget.occurrence, o.id, '${o.nama} (${o.timeLabel})'),
      for (final e in events.where((e) => sameDay(e.date)))
        _Target(CheckinTarget.event, e.id, 'Event: ${e.title}'),
    ];
    setState(() {
      _targets = targets;
      _selected = targets.isEmpty ? null : targets.first;
      _loadingTargets = false;
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
    final target = _selected;
    if (_isProcessing || target == null) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null) return;

    final checkin = context.read<CheckinProvider>();
    setState(() => _isProcessing = true);
    await _controller.stop();
    final r = await checkin.staffCheckIn(targetType: target.type, targetId: target.id, rawQr: raw);
    if (!mounted) return;

    final scheme = Theme.of(context).colorScheme;
    final name = r.memberName ?? 'Jemaat';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!r.ok
            ? r.error!
            : r.alreadyCheckedIn
                ? '$name sudah tercatat hadir sebelumnya.'
                : '$name berhasil ditandai hadir.'),
        backgroundColor: !r.ok
            ? scheme.error
            : r.alreadyCheckedIn
                ? Colors.orange.shade800
                : AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    // Short pause so the same card isn't read again immediately.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    await _controller.start();
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
              ? _PermissionDenied(
                  onRetry: _init,
                  openSettings: _permissionPermanentlyDenied ? openAppSettings : null,
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surface,
                      child: _loadingTargets
                          ? const LinearProgressIndicator()
                          : _targets.isEmpty
                              ? const Text(
                                  'Tidak ada ibadah atau event hari ini. Check-in hanya dapat '
                                  'dilakukan pada hari acara.',
                                )
                              : DropdownButtonFormField<_Target>(
                                  initialValue: _selected,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Catat kehadiran untuk',
                                    prefixIcon: Icon(Icons.church_rounded),
                                  ),
                                  items: [
                                    for (final t in _targets)
                                      DropdownMenuItem(
                                        value: t,
                                        child: Text(t.label, overflow: TextOverflow.ellipsis),
                                      ),
                                  ],
                                  onChanged: (t) => setState(() => _selected = t),
                                ),
                    ),
                    Expanded(
                      child: Stack(
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
                            left: 24,
                            right: 24,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Text(
                                'Arahkan kamera ke QR kartu jemaat',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          if (_isProcessing)
                            Container(
                              color: Colors.black54,
                              child: const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
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
  final Future<bool> Function()? openSettings;

  const _PermissionDenied({required this.onRetry, this.openSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: AppEmptyState(
        icon: Icons.camera_alt_outlined,
        title: 'Izin Kamera Dibutuhkan',
        description: 'Aplikasi membutuhkan izin akses kamera untuk memindai QR kartu jemaat.',
        actionLabel: openSettings != null ? 'Buka Pengaturan' : 'Berikan Izin Kamera',
        onAction: openSettings != null ? () => openSettings!() : onRetry,
      ),
    );
  }
}
