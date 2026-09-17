import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/prayer_request.dart';
import '../providers/prayer_request_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';

class PrayerRequestManagementScreen extends StatefulWidget {
  const PrayerRequestManagementScreen({super.key});

  @override
  State<PrayerRequestManagementScreen> createState() => _PrayerRequestManagementScreenState();
}

class _PrayerRequestManagementScreenState extends State<PrayerRequestManagementScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerRequestProvider>().loadAllRequests();
    });
  }

  List<PrayerRequest> _filtered(List<PrayerRequest> all) {
    if (_filterStatus == 'all') return all;
    return all.where((r) => r.status == _filterStatus).toList();
  }

  Future<void> _updateStatus(PrayerRequest request) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Ubah Status Doa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusOption(dialogContext, 'baru', 'Baru', Icons.fiber_new_rounded, AppTheme.infoColor),
            const SizedBox(height: 8),
            _statusOption(dialogContext, 'didoakan', 'Didoakan', Icons.favorite_rounded, AppTheme.warningColor),
            const SizedBox(height: 8),
            _statusOption(dialogContext, 'terjawab', 'Terjawab', Icons.check_circle_rounded, AppTheme.successColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal', style: TextStyle(color: AppTheme.mutedCharcoal)),
          ),
        ],
      ),
    );
    if (newStatus == null || !mounted) return;
    await context.read<PrayerRequestProvider>().updateStatus(request.id, newStatus);
  }

  Widget _statusOption(BuildContext context, String statusKey, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(statusKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkCharcoal,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedCharcoal, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PrayerRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Permohonan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context.read<PrayerRequestProvider>().deleteRequest(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Permohonan dihapus' : 'Gagal menghapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Doa Jemaat',
          style: TextStyle(
            color: AppTheme.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Consumer<PrayerRequestProvider>(
              builder: (context, provider, _) {
                final all = provider.allRequests;
                final countBaru = all.where((r) => r.status == 'baru').length;
                final countDidoakan = all.where((r) => r.status == 'didoakan').length;
                final countTerjawab = all.where((r) => r.status == 'terjawab').length;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Semua', all.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('baru', 'Baru', countBaru),
                      const SizedBox(width: 8),
                      _buildFilterChip('didoakan', 'Didoakan', countDidoakan),
                      const SizedBox(width: 8),
                      _buildFilterChip('terjawab', 'Terjawab', countTerjawab),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.neutralBorder),

          // List Content
          Expanded(
            child: Consumer<PrayerRequestProvider>(
              builder: (context, provider, _) {
                final requests = _filtered(provider.allRequests);
                if (requests.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Tidak Ada Permohonan Doa',
                    message: _filterStatus == 'all'
                        ? 'Belum ada permohonan doa yang dikirim jemaat.'
                        : 'Tidak ada permohonan doa dengan status "$_filterStatus".',
                  );
                }
                return RefreshIndicator(
                  onRefresh: provider.loadAllRequests,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final isAnon = request.isAnonymous;
                      final displayName = isAnon ? 'Anonim' : request.userName;

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isAnon
                                      ? AppTheme.mutedCharcoal.withValues(alpha: 0.12)
                                      : AppTheme.primary.withValues(alpha: 0.1),
                                  child: Icon(
                                    isAnon ? Icons.visibility_off_rounded : Icons.person_rounded,
                                    size: 18,
                                    color: isAnon ? AppTheme.mutedCharcoal : AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppTheme.darkCharcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        request.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primary.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppStatusBadge(
                                  status: request.status,
                                  label: request.status.toUpperCase(),
                                  isSmall: true,
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: AppTheme.mutedCharcoal),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (value) {
                                    if (value == 'status') _updateStatus(request);
                                    if (value == 'delete') _confirmDelete(request);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'status',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.primary),
                                          SizedBox(width: 10),
                                          Text('Ubah Status'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorColor),
                                          SizedBox(width: 10),
                                          Text('Hapus', style: TextStyle(color: AppTheme.errorColor)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Content
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.warmIvory,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.neutralBorder),
                              ),
                              child: Text(
                                request.content,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: AppTheme.darkCharcoal,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Timestamp Footer
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.mutedCharcoal),
                                const SizedBox(width: 5),
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(request.createdAt),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.mutedCharcoal),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count) {
    final isSelected = _filterStatus == key;
    return FilterChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.darkCharcoal,
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
        ),
      ),
      onSelected: (_) => setState(() => _filterStatus = key),
    );
  }
}

