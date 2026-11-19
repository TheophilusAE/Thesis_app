import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/checkin_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_empty_state.dart';

/// Jemaat-facing scanner: scans the check-in QR a pelayan/admin displays for
/// a worship date or event and checks the signed-in member in.
///
/// The database (`self_check_in`) decides everything: the code's token must
/// match that worship/event, the time window must be open, events require a
/// booking, and a second scan never counts twice.
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
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null) return;

    final checkin = context.read<CheckinProvider>();
    setState(() => _isProcessing = true);
    await _controller.stop();
    final result = await checkin.selfCheckIn(raw);
    if (!mounted) return;

    final done = await _showResult(result);
    if (!mounted) return;
    if (done) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isProcessing = false);
    await _controller.start();
  }

  /// Returns true when the screen should close (successful check-in).
  Future<bool> _showResult(CheckinResult r) async {
    final scheme = Theme.of(context).colorScheme;
    final title = !r.ok
        ? 'Check-in Gagal'
        : r.alreadyCheckedIn
            ? 'Sudah Tercatat'
            : 'Kehadiran Tercatat';
    final message = !r.ok
        ? r.error!
        : r.alreadyCheckedIn
            ? 'Kehadiran Anda di "${r.label ?? 'acara ini'}" sudah tercatat sebelumnya.'
            : 'Terima kasih! Kehadiran Anda di "${r.label ?? 'acara ini'}" sudah dicatat.';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          r.ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: r.ok ? Colors.green : scheme.error,
          size: 40,
        ),
        title: Text(title),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(r.ok ? 'Selesai' : 'Coba Lagi'),
          ),
        ],
      ),
    );
    return r.ok;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Ibadah / Event'),
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
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
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
                      errorBuilder: (context, error) => const Center(
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
                          'Arahkan kamera ke QR presensi yang ditampilkan petugas',
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
        description: 'Aplikasi membutuhkan izin akses kamera untuk memindai kode QR presensi.',
        actionLabel: openSettings != null ? 'Buka Pengaturan' : 'Berikan Izin Kamera',
        onAction: openSettings != null ? () => openSettings!() : onRetry,
      ),
    );
  }
}
