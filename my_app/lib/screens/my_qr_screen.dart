import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/checkin_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_error_state.dart';

/// Large, high-contrast display of the signed-in member's card QR — held up
/// to a pelayan's scanner. The QR carries a per-member secret from the
/// server, so it can't be forged from a user id alone.
class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  Future<String>? _qr;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _qr ??= _load();
  }

  Future<String> _load() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return Future.error('Data user tidak ditemukan');
    return context.read<CheckinProvider>().memberQrData(userId: user.id, name: user.name);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('QR Jemaat Saya')),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Data user tidak ditemukan'))
            : FutureBuilder<String>(
                future: _qr,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return AppErrorState(
                      title: 'QR belum dapat ditampilkan',
                      message: CheckinProvider.messageFor(snap.error!),
                      onRetry: () => setState(() => _qr = _load()),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'KODE QR JEMAAT PRIBADI',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // QR stays dark-on-white in every theme so it scans reliably.
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppTheme.neutralBorder),
                          ),
                          child: QrImageView(
                            data: snap.data!,
                            version: QrVersions.auto,
                            size: 260,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          user.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tunjukkan kode QR ini kepada petugas usher / pelayan\n'
                          'untuk pencatatan kehadiran ibadah atau event.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
