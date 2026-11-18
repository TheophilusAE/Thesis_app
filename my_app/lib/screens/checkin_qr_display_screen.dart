import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/checkin_provider.dart';
import '../widgets/common/app_error_state.dart';

/// Pelayan/admin screen that displays the check-in QR for one worship date
/// or event (e.g. on a phone held up at the door or mirrored to a screen).
///
/// The code embeds a server-issued token valid only for this target and
/// only from 2 hours before the start until the end of that day (WITA).
class CheckinQrDisplayScreen extends StatefulWidget {
  final String targetType; // CheckinTarget.occurrence / .event
  final String targetId;
  final String title;
  final String subtitle;

  const CheckinQrDisplayScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.title,
    this.subtitle = '',
  });

  @override
  State<CheckinQrDisplayScreen> createState() => _CheckinQrDisplayScreenState();
}

class _CheckinQrDisplayScreenState extends State<CheckinQrDisplayScreen> {
  late Future<CheckinCode> _code;

  @override
  void initState() {
    super.initState();
    _code = _load();
  }

  Future<CheckinCode> _load() =>
      context.read<CheckinProvider>().issueCode(widget.targetType, widget.targetId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Presensi'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _code = _load()),
          ),
        ],
      ),
      body: FutureBuilder<CheckinCode>(
        future: _code,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return AppErrorState(
              title: 'QR tidak dapat ditampilkan',
              message: CheckinProvider.messageFor(snap.error!),
              onRetry: () => setState(() => _code = _load()),
            );
          }
          final code = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Text(
                  code.label.isNotEmpty ? code.label : widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (widget.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(widget.subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                // QR codes must stay dark-on-white to scan reliably, in any theme.
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: QrImageView(
                    data: code.qrData,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Berlaku sampai ${DateFormat('EEEE, d MMM yyyy HH:mm', 'id_ID').format(code.validUntil)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jemaat memindai QR ini dari menu QR → "Scan Event". '
                  'Setiap jemaat hanya tercatat satu kali.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
