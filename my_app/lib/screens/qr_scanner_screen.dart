import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/attendance_service.dart';
import '../utils/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  final String memberId;
  final String memberName;
  final String serviceName;
  final bool isAdminMode;

  const QRScannerScreen({
    super.key,
    this.memberId = "MEMBER_ID",
    this.memberName = "Anggota Gereja",
    this.serviceName = "Ibadah",
    this.isAdminMode = false,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  late String qrData;
  String _eventId = 'evt-default';
  String _eventName = 'Ibadah Umum';
  Timer? timer;

  bool get _supportsCameraScan {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    generateQR();
    startAutoRefresh();
  }

  void generateQR() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (widget.isAdminMode) {
      qrData =
          'CHURCH_EVENT|EID:$_eventId|EVENT:$_eventName|MODE:option1|TIME:$timestamp';
    } else {
      qrData =
          'CHURCH_MEMBER|UID:${widget.memberId}|NAME:${widget.memberName}|SERVICE:${widget.serviceName}|MODE:option2|TIME:$timestamp';
    }
    
    setState(() {});
  }

  void startAutoRefresh() {
    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      generateQR();
    });
  }

  Future<void> _createEventQr() async {
    final controller = TextEditingController(text: _eventName);
    final eventName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buat QR Event (Pilihan 1)'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama Event/Ibadah',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Buat'),
            ),
          ],
        );
      },
    );

    if (eventName == null || eventName.isEmpty) {
      return;
    }

    final event = await _attendanceService.createEvent(
      name: eventName,
      mode: 'option1',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _eventId = event['id'] as String;
      _eventName = event['name'] as String;
    });
    generateQR();
  }

  Future<void> _simulateAdminScanMember() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Catat Kehadiran (Pilihan 2)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Member ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Jemaat'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    final memberId = idController.text.trim();
    final memberName = nameController.text.trim();
    if (memberId.isEmpty || memberName.isEmpty) {
      return;
    }

    final isRecorded = await _attendanceService.markAttendance(
      eventId: _eventId,
      eventName: _eventName,
      memberId: memberId,
      memberName: memberName,
      source: 'scanner-admin',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRecorded
              ? 'Kehadiran berhasil dicatat.'
              : 'Kehadiran sudah pernah dicatat untuk event ini.',
        ),
      ),
    );
  }

  Future<String?> _scanQrPayloadWithCamera({required String title}) async {
    if (!_supportsCameraScan) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pemindaian kamera belum didukung di perangkat ini. Gunakan input manual.',
          ),
        ),
      );
      return null;
    }

    bool alreadyHandled = false;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(
              fit: BoxFit.cover,
              onDetect: (capture) {
                if (alreadyHandled || capture.barcodes.isEmpty) {
                  return;
                }

                final rawValue = capture.barcodes.first.rawValue;
                if (rawValue == null || rawValue.trim().isEmpty) {
                  return;
                }

                alreadyHandled = true;
                Navigator.of(context).pop(rawValue.trim());
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanAdminMemberWithCamera() async {
    final rawPayload = await _scanQrPayloadWithCamera(title: 'Scan QR Jemaat');
    if (rawPayload == null || rawPayload.isEmpty) {
      return;
    }

    final parsed = _attendanceService.parseMemberQr(rawPayload);
    if (parsed == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format QR jemaat tidak valid.')),
      );
      return;
    }

    final isRecorded = await _attendanceService.markAttendance(
      eventId: _eventId,
      eventName: _eventName,
      memberId: parsed.memberId,
      memberName: parsed.memberName,
      source: 'scanner-admin',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRecorded
              ? 'Kehadiran ${parsed.memberName} berhasil dicatat.'
              : 'Jemaat ini sudah tercatat untuk event ini.',
        ),
      ),
    );
  }

  Future<void> _simulateMemberScanEvent() async {
    final controller = TextEditingController();
    final rawPayload = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input QR Event'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tempel payload QR event',
            hintText: 'CHURCH_EVENT|EID:...|EVENT:...|...',
          ),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Gunakan'),
          ),
        ],
      ),
    );

    if (rawPayload == null || rawPayload.isEmpty) {
      return;
    }

    final parsed = _attendanceService.parseEventQr(rawPayload);
    if (parsed == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format QR event tidak valid.')),
      );
      return;
    }

    setState(() {
      _eventId = parsed.eventId;
      _eventName = parsed.eventName;
    });
    generateQR();
  }

  Future<void> _scanMemberEventWithCamera() async {
    final rawPayload = await _scanQrPayloadWithCamera(title: 'Scan QR Event');
    if (rawPayload == null || rawPayload.isEmpty) {
      return;
    }

    final parsed = _attendanceService.parseEventQr(rawPayload);
    if (parsed == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format QR event tidak valid.')),
      );
      return;
    }

    setState(() {
      _eventId = parsed.eventId;
      _eventName = parsed.eventName;
    });
    generateQR();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event terdeteksi: ${parsed.eventName}')),
    );
  }

  Future<void> _markSelfAttendance() async {
    final isRecorded = await _attendanceService.markAttendance(
      eventId: _eventId,
      eventName: _eventName,
      memberId: widget.memberId,
      memberName: widget.memberName,
      source: 'scan-jemaat',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRecorded
              ? 'Kehadiran Anda sudah tercatat.'
              : 'Anda sudah tercatat untuk event ini.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isAdminMode ? 'Kelola QR Event' : 'QR Kehadiran Ibadah'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFF58A77E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isAdminMode
                          ? 'Mode Admin: buat dan validasi QR event.'
                          : 'Mode Jemaat: tunjukkan QR ke petugas.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 gradient: AppTheme.purpleBlueGradient,
                 borderRadius: BorderRadius.circular(22),
               ),
               child: const Icon(Icons.church, size: 80, color: Colors.white),
             ),

            const SizedBox(height: 16),

            Text(
              widget.isAdminMode
                  ? 'Buat QR event (Pilihan 1) atau scan QR jemaat (Pilihan 2)'
                  : 'Tunjukkan QR ini ke petugas atau scanner admin',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: const Color(0xFF58A77E).withValues(alpha: 0.2),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 260,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              widget.isAdminMode ? _eventName : widget.memberName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              'ID: ${widget.isAdminMode ? _eventId : widget.memberId}',
              style: TextStyle(color: secondaryTextColor),
            ),

            const SizedBox(height: 8),

            Text(
              'Ibadah: ${widget.serviceName}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 20),

            if (widget.isAdminMode) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _createEventQr,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Buat QR'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scanAdminMemberWithCamera,
                      icon: const Icon(Icons.document_scanner),
                      label: const Text('Scan Jemaat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _simulateAdminScanMember,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Input Manual Jemaat'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scanMemberEventWithCamera,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Event'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _simulateMemberScanEvent,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Input QR Event Manual'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markSelfAttendance,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Saya Sudah Scan QR Event'),
                ),
              ),
            ],

            const SizedBox(height: 16),

            const Text(
              "QR otomatis diperbarui setiap 30 detik",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}