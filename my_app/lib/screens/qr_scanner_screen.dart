import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/attendance_service.dart';

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

    await _attendanceService.markAttendance(
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
      const SnackBar(content: Text('Kehadiran berhasil dicatat.')),
    );
  }

  Future<void> _markSelfAttendance() async {
    await _attendanceService.markAttendance(
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
      const SnackBar(content: Text('Kehadiran Anda sudah tercatat.')),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.isAdminMode ? 'Kelola QR Event' : 'QR Kehadiran Ibadah'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.church, size: 80, color: Colors.blue),

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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black.withValues(alpha: 0.1),
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
              style: TextStyle(color: Colors.grey[600]),
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
                      label: const Text('Buat QR Event'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _simulateAdminScanMember,
                      icon: const Icon(Icons.document_scanner),
                      label: const Text('Scan QR Jemaat'),
                    ),
                  ),
                ],
              ),
            ] else ...[
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