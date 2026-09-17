import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attendance_confirmation.dart';
import '../providers/attendance_confirmation_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';

class AdminAttendanceMonitoringScreen extends StatefulWidget {
  const AdminAttendanceMonitoringScreen({super.key});

  @override
  State<AdminAttendanceMonitoringScreen> createState() =>
      _AdminAttendanceMonitoringScreenState();
}

class _AdminAttendanceMonitoringScreenState
    extends State<AdminAttendanceMonitoringScreen> {
  String _filterStatus = 'all'; // all, confirmed, pending
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AttendanceConfirmationProvider>();
      provider.loadAllConfirmations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AttendanceConfirmation> _getFilteredConfirmations(
    List<AttendanceConfirmation> confirmations,
  ) {
    List<AttendanceConfirmation> filtered = confirmations;

    // Filter by status
    if (_filterStatus == 'confirmed') {
      filtered = filtered.where((c) => c.confirmed).toList();
    } else if (_filterStatus == 'pending') {
      filtered = filtered.where((c) => !c.confirmed).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((c) =>
              c.userName.toLowerCase().contains(q) ||
              c.scheduleDate.toString().toLowerCase().contains(q))
          .toList();
    }

    return filtered;
  }

  Widget _buildSummaryCard(List<AttendanceConfirmation> all) {
    final confirmed = all.where((c) => c.confirmed).length;
    final pending = all.length - confirmed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: _MetricItem(
                label: 'Total',
                value: '${all.length}',
                color: AppTheme.primary,
                icon: Icons.people_alt_rounded,
              ),
            ),
            Container(width: 1, height: 40, color: AppTheme.neutralBorder),
            Expanded(
              child: _MetricItem(
                label: 'Konfirmasi',
                value: '$confirmed',
                color: AppTheme.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
            Container(width: 1, height: 40, color: AppTheme.neutralBorder),
            Expanded(
              child: _MetricItem(
                label: 'Menunggu',
                value: '$pending',
                color: AppTheme.gold,
                icon: Icons.hourglass_top_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.transparent,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Cari nama pelayan atau tanggal...',
              hintStyle: TextStyle(
                color: AppTheme.neutralMuted.withValues(alpha: 0.8),
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.neutralBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.neutralBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('confirmed', 'Sudah Konfirmasi'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Belum Konfirmasi'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = selected ? value : 'all');
      },
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.primary : AppTheme.darkCharcoal,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryLight,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildConfirmationTile(AttendanceConfirmation confirmation) {
    final dateFormat = DateFormat('EEEE, dd MMM yyyy • HH:mm', 'id_ID');
    final scheduleDate = dateFormat.format(confirmation.scheduleDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => _showConfirmationDetails(confirmation),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: confirmation.confirmed
                    ? const Color(0xFFD1FAE5)
                    : AppTheme.goldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                confirmation.confirmed
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                color: confirmation.confirmed
                    ? const Color(0xFF065F46)
                    : const Color(0xFF92400E),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          confirmation.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.darkCharcoal,
                          ),
                        ),
                      ),
                      AppStatusBadge(
                        label: confirmation.confirmed ? 'Hadir' : 'Menunggu',
                        type: confirmation.confirmed
                            ? AppStatusBadgeType.success
                            : AppStatusBadgeType.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppTheme.neutralMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          scheduleDate,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.neutralMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (confirmation.notes != null &&
                      confirmation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Catatan: ${confirmation.notes}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutralMedium,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDetails(AttendanceConfirmation confirmation) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Detail Presensi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Nama Pelayan', confirmation.userName),
              const SizedBox(height: 10),
              _detailRow(
                'Jadwal',
                dateFormat.format(confirmation.scheduleDate),
              ),
              const SizedBox(height: 10),
              _detailRow(
                'Status',
                confirmation.confirmed ? 'Sudah Dikonfirmasi' : 'Belum Dikonfirmasi',
                textColor: confirmation.confirmed ? AppTheme.success : AppTheme.gold,
              ),
              if (confirmation.confirmedAt != null) ...[
                const SizedBox(height: 10),
                _detailRow(
                  'Waktu Konfirmasi',
                  dateFormat.format(confirmation.confirmedAt!),
                ),
              ],
              if (confirmation.notes != null &&
                  confirmation.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow('Catatan', confirmation.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.neutralMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor ?? AppTheme.darkCharcoal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Monitor Kehadiran Pelayan',
          style: TextStyle(
            color: AppTheme.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      body: Consumer<AttendanceConfirmationProvider>(
        builder: (context, provider, _) {
          final allConfirmations = provider.allConfirmations;
          final filteredConfirmations =
              _getFilteredConfirmations(allConfirmations);

          return Column(
            children: [
              _buildSummaryCard(allConfirmations),
              _buildFilterBar(),
              Expanded(
                child: filteredConfirmations.isEmpty
                    ? Center(
                        child: AppEmptyState(
                          icon: Icons.fact_check_outlined,
                          title: allConfirmations.isEmpty
                              ? 'Belum Ada Data Kehadiran'
                              : 'Tidak Ada Data yang Cocok',
                          description: allConfirmations.isEmpty
                              ? 'Data presensi pelayan akan muncul setelah ada jadwal aktif.'
                              : 'Coba ubah kata kunci pencarian atau filter status.',
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: () async {
                          await provider.loadAllConfirmations();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredConfirmations.length,
                          itemBuilder: (context, index) =>
                              _buildConfirmationTile(
                            filteredConfirmations[index],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutralMuted,
          ),
        ),
      ],
    );
  }
}
