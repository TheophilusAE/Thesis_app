import 'package:flutter/material.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'dart:io';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  // QRViewController? controller;
  String? scannedData;
  bool flashOn = false;

  // @override
  // void reassemble() {
  //   super.reassemble();
  //   if (Platform.isAndroid) {
  //     controller?.pauseCamera();
  //   }
  //   controller?.resumeCamera();
  // }

  @override
  void dispose() {
    // controller?.dispose();
    super.dispose();
  }

  // void _onQRViewCreated(QRViewController controller) {
  //   this.controller = controller;
  //   controller.scannedDataStream.listen((scanData) {
  //     setState(() {
  //       scannedData = scanData.code;
  //     });
  //     
  //     // Pause camera after scan
  //     controller.pauseCamera();
  //     
  //     // Show result dialog
  //     _showScanResult(scanData.code);
  //   });
  // }

  // void _showScanResult(String? data) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('QR Code Dipindai'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text('Data QR Code:'),
  //           const SizedBox(height: 8),
  //           Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: Colors.grey[200],
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Text(
  //               data ?? 'Tidak ada data',
  //               style: const TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           const Text(
  //             'Kehadiran Anda telah dicatat untuk acara ini.',
  //             style: TextStyle(color: Colors.green),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             controller?.resumeCamera();
  //           },
  //           child: const Text('Scan Lagi'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             Navigator.pop(context);
  //           },
  //           child: const Text('Selesai'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _toggleFlash() {
    // controller?.toggleFlash();
    setState(() {
      flashOn = !flashOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Event/Ibadah'),
        actions: [
          IconButton(
            icon: Icon(flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'QR Scanner Temporarily Disabled',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This feature will be available soon',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'Arahkan kamera ke QR Code event atau ibadah',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (scannedData != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Terakhir dipindai: ${scannedData!.substring(0, scannedData!.length > 20 ? 20 : scannedData!.length)}...',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
