import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/qr_payload.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_status_badge.dart';

class MemberCardScreen extends StatelessWidget {
  const MemberCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Kartu Jemaat Digital'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text(
                'Data user tidak ditemukan',
                style: TextStyle(color: AppTheme.neutralMedium),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Digital ID Card
                  _buildDigitalCard(context, user),

                  const SizedBox(height: 24),

                  // Quick Instructions Banner
                  _buildNoticeBanner(context),

                  const SizedBox(height: 24),

                  // Member Information Details
                  _buildDetailsSection(context, user),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDigitalCard(BuildContext context, User user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.burgundyDark,
            AppTheme.primary,
            AppTheme.burgundy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.burgundy.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle Watermark Graphic
          Positioned(
            right: -25,
            bottom: -25,
            child: Icon(
              Icons.church_rounded,
              size: 200,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header of the card: Church Name & Gold Seal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.goldLight.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.church_rounded,
                        color: AppTheme.goldLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GEREJA PANTEKOSTA DI INDONESIA',
                            style: TextStyle(
                              color: AppTheme.goldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'KARTU TANDA ANGGOTA JEMAAT',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Name & Role
                Text(
                  user.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.goldLight.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    user.membershipType ?? 'Anggota Jemaat',
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Card Body: Info column & QR Code
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Member Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardField(
                            'NO. KARTU ANGGOTA',
                            user.memberCardNumber ?? user.identityNumber ?? '-',
                          ),
                          const SizedBox(height: 10),
                          _buildCardField(
                            'WILAYAH / KOMSEL',
                            user.familyGroup ?? '-',
                          ),
                          const SizedBox(height: 10),
                          _buildCardField(
                            'STATUS',
                            user.membershipStatus.toUpperCase(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Scannable QR Code Container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: encodeMemberPayload(
                              userId: user.id,
                              name: user.name,
                            ),
                            version: QrVersions.auto,
                            size: 108,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'SCAN SAYA',
                            style: TextStyle(
                              color: AppTheme.primaryDark,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tunjukkan kode QR ini kepada petugas usher / pelayan saat hadir di ibadah untuk pencatatan presensi kehadiran otomatis.',
              style: TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Lengkap Jemaat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.darkCharcoal,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _buildDetailRow(
                icon: Icons.badge_outlined,
                label: 'Status Keanggotaan',
                customValue: AppStatusBadge(
                  label: user.membershipStatus,
                  status: user.membershipStatus.toLowerCase(),
                ),
              ),
              const Divider(height: 20),
              _buildDetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              const Divider(height: 20),
              _buildDetailRow(
                icon: Icons.phone_outlined,
                label: 'Nomor Telepon',
                value: user.phone.isNotEmpty ? user.phone : '-',
              ),
              const Divider(height: 20),
              _buildDetailRow(
                icon: Icons.fingerprint_rounded,
                label: 'NIK / Nomor Identitas',
                value: user.identityNumber ?? '-',
              ),
              const Divider(height: 20),
              _buildDetailRow(
                icon: Icons.group_outlined,
                label: 'Wilayah / Komsel',
                value: user.familyGroup ?? '-',
              ),
              const Divider(height: 20),
              _buildDetailRow(
                icon: Icons.location_on_outlined,
                label: 'Alamat',
                value: user.address ?? '-',
              ),
              const Divider(height: 20),
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Anggota Sejak',
                value: user.memberSince ?? '-',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? customValue,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.neutralMedium),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.neutralMedium,
              fontSize: 13,
            ),
          ),
        ),
        if (customValue != null)
          customValue
        else
          Flexible(
            child: Text(
              value ?? '-',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.darkCharcoal,
              ),
            ),
          ),
      ],
    );
  }
}
