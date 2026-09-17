import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/prayer_request.dart';
import '../providers/auth_provider.dart';
import '../providers/prayer_request_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';

const _kCategories = [
  {'key': 'pribadi', 'label': 'Pribadi', 'icon': Icons.person_outline_rounded},
  {'key': 'keluarga', 'label': 'Keluarga', 'icon': Icons.family_restroom_rounded},
  {'key': 'kesehatan', 'label': 'Kesehatan', 'icon': Icons.favorite_outline_rounded},
  {'key': 'pekerjaan', 'label': 'Pekerjaan', 'icon': Icons.work_outline_rounded},
  {'key': 'lainnya', 'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
];

class PrayerRequestScreen extends StatefulWidget {
  const PrayerRequestScreen({super.key});

  @override
  State<PrayerRequestScreen> createState() => _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends State<PrayerRequestScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _category = 'pribadi';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<PrayerRequestProvider>().loadMyRequests(user.id);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon tuliskan pokok doa Anda terlebih dahulu'),
        ),
      );
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    final success = await context.read<PrayerRequestProvider>().submitRequest(
          userId: user.id,
          userName: user.name,
          category: _category,
          content: content,
          isAnonymous: _isAnonymous,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Permohonan doa berhasil dikirimkan ke Tim Doa Syafaat'
              : 'Gagal mengirim permohonan doa. Silakan coba lagi.',
        ),
        backgroundColor: success ? AppTheme.emerald : AppTheme.primary,
      ),
    );

    if (success) {
      _contentController.clear();
      setState(() => _isAnonymous = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Doa & Permohonan'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          final user = context.read<AuthProvider>().currentUser;
          if (user != null) {
            await context.read<PrayerRequestProvider>().loadMyRequests(user.id);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Privacy Reassurance Banner
              _buildReassuranceBanner(),

              const SizedBox(height: 16),

              // Prayer Request Submission Card
              _buildFormCard(),

              const SizedBox(height: 28),

              // Request History Header
              Row(
                children: const [
                  Icon(Icons.history_rounded, size: 20, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Riwayat Permohonan Doa Saya',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // History List
              Consumer<PrayerRequestProvider>(
                builder: (context, provider, _) {
                  final requests = provider.myRequests;
                  if (requests.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.volunteer_activism_outlined,
                      title: 'Belum ada permohonan doa',
                      description: 'Pokok doa yang Anda kirimkan akan muncul di sini beserta status doanya.',
                    );
                  }

                  return Column(
                    children: requests
                        .map((req) => _buildPrayerCard(context, req))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReassuranceBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kerahasiaan Terjaga',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primaryDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Setiap pokok doa Anda didoakan secara khusus dan dijaga kerahasiaannya oleh Tim Doa Syafaat & Hamba Tuhan GPDI.',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sampaikan Permohonan Doa',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.darkCharcoal,
            ),
          ),
          const SizedBox(height: 14),

          // Category Chips
          const Text(
            'Kategori Doa',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.neutralMedium,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kCategories.map((cat) {
              final isSelected = _category == cat['key'];
              return ChoiceChip(
                avatar: Icon(
                  cat['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : AppTheme.primary,
                ),
                label: Text(cat['label'] as String),
                selected: isSelected,
                selectedColor: AppTheme.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkCharcoal,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _category = cat['key'] as String);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Content Input
          const Text(
            'Tuliskan Pokok Doa',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.neutralMedium,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppTheme.darkCharcoal),
            decoration: InputDecoration(
              hintText: 'Tuliskan pergumulan atau ucapan syukur yang ingin didoakan...',
              hintStyle: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
              filled: true,
              fillColor: AppTheme.warmIvory,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.neutralBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.neutralBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          const SizedBox(height: 12),

          // Anonymous Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.warmIvory,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.neutralBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility_off_outlined, color: AppTheme.neutralMedium, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kirim sebagai Anonim',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        'Nama Anda tidak ditampilkan ke tim pendoa',
                        style: TextStyle(color: AppTheme.neutralMedium, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isAnonymous,
                  activeTrackColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _isAnonymous = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Submit Button
          AppButton(
            label: 'Kirim Permohonan Doa',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(BuildContext context, PrayerRequest request) {
    final formattedDate = DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(request.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                AppStatusBadge(
                  label: _statusLabel(request.status),
                  status: request.status,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.darkCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.neutralMedium),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(color: AppTheme.neutralMedium, fontSize: 12),
                ),
                if (request.isAnonymous) ...[
                  const Spacer(),
                  const Row(
                    children: [
                      Icon(Icons.visibility_off_outlined, size: 14, color: AppTheme.neutralMedium),
                      SizedBox(width: 4),
                      Text(
                        'Anonim',
                        style: TextStyle(color: AppTheme.neutralMedium, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'didoakan':
        return 'Sedang Didoakan';
      case 'terjawab':
        return 'Doa Terjawab';
      default:
        return 'Diterima';
    }
  }
}
