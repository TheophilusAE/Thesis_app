import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/qr_payload.dart';

/// Large, high-contrast display of the logged-in jemaat's own member QR —
/// meant to be held up to a pelayan's scanner, so it keeps the QR itself as
/// big and plain as possible instead of repeating the full digital card
/// from [MemberCardScreen].
class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('QR Jemaat Saya'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      body: SafeArea(
        child: user == null
            ? const Center(
                child: Text(
                  'Data user tidak ditemukan',
                  style: TextStyle(color: AppTheme.neutralMedium),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: const Text(
                        'KODE QR JEMAAT PRIBADI',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppTheme.neutralBorder),
                            boxShadow: AppTheme.cardShadow(),
                          ),
                          child: QrImageView(
                            data: encodeMemberPayload(userId: user.id, name: user.name),
                            version: QrVersions.auto,
                            size: 260,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tunjukkan kode QR ini kepada petugas usher / pelayan\nuntuk pencatatan presensi kehadiran.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutralMedium,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
