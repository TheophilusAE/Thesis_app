import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/service_schedule.dart';
import '../providers/auth_provider.dart';
import '../providers/pelayan_provider.dart';
import '../providers/service_schedule_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import 'add_edit_service_schedule_screen.dart';

class ServiceScheduleManagementScreen extends StatefulWidget {
  const ServiceScheduleManagementScreen({super.key});

  @override
  State<ServiceScheduleManagementScreen> createState() =>
      _ServiceScheduleManagementScreenState();
}

class _ServiceScheduleManagementScreenState
    extends State<ServiceScheduleManagementScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceScheduleProvider>().loadAllSchedules();
      context.read<PelayaniProvider>().loadAllPelayan();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AuthProvider>().isAdminMode;
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Jadwal Pelayanan',
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
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pelayan, jenis ibadah, atau tugas...',
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
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.warmIvory,
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
          ),

          // Schedule list
          Expanded(
            child: Consumer<ServiceScheduleProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (provider.allSchedules.isEmpty) {
                  return Center(
                    child: AppEmptyState(
                      icon: Icons.calendar_today_rounded,
                      title: 'Tidak Ada Jadwal Pelayanan',
                      description: 'Belum ada jadwal ibadah atau tugas pelayanan yang terdaftar.',
                      actionLabel: canManage ? 'Tambah Jadwal' : null,
                      onAction: canManage ? _addNewSchedule : null,
                    ),
                  );
                }

                final query = _searchQuery.toLowerCase().trim();
                final schedules = provider.allSchedules.where((s) {
                  if (query.isEmpty) return true;
                  return s.pelayaniName.toLowerCase().contains(query) ||
                      s.serviceType.toLowerCase().contains(query) ||
                      s.pelayaniPosition.toLowerCase().contains(query);
                }).toList();

                if (schedules.isEmpty) {
                  return Center(
                    child: AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Tidak Ditemukan',
                      description: 'Tidak ada jadwal yang cocok dengan kata kunci "$_searchQuery".',
                      actionLabel: 'Reset Pencarian',
                      onAction: () => _searchController.clear(),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ServiceScheduleCard(
                        schedule: schedule,
                        onEdit: canManage ? () => _editSchedule(schedule) : null,
                        onDelete: canManage ? () => _deleteSchedule(schedule) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !canManage ? null : FloatingActionButton.extended(
        onPressed: _addNewSchedule,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Jadwal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _addNewSchedule() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditServiceScheduleScreen(),
          ),
        )
        .then((_) {
      if (mounted) context.read<ServiceScheduleProvider>().loadAllSchedules();
    });
  }

  void _editSchedule(ServiceSchedule schedule) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditServiceScheduleScreen(schedule: schedule),
          ),
        )
        .then((_) {
      if (mounted) context.read<ServiceScheduleProvider>().loadAllSchedules();
    });
  }

  void _deleteSchedule(ServiceSchedule schedule) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jadwal?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus jadwal ${schedule.pelayaniName} pada ${DateFormat('dd/MM/yyyy').format(schedule.serviceDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context
                  .read<ServiceScheduleProvider>()
                  .deleteServiceSchedule(schedule.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jadwal berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _ServiceScheduleCard extends StatelessWidget {
  final ServiceSchedule schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ServiceScheduleCard({
    required this.schedule,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final dateStr = dateFormatter.format(schedule.serviceDate);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Service Type & Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.church_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.pelayaniName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schedule.serviceType,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.neutralMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null && onDelete != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.error),
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.neutralBorder),
          const SizedBox(height: 12),

          // Detail rows
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 15, color: AppTheme.neutralMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkCharcoal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: AppTheme.neutralMuted),
              const SizedBox(width: 8),
              Text(
                '${schedule.startTime} - ${schedule.endTime}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkCharcoal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.assignment_ind_outlined, size: 15, color: AppTheme.neutralMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schedule.pelayaniPosition,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (schedule.isRecurring) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.goldLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.repeat_rounded, size: 14, color: Color(0xFF92400E)),
                  const SizedBox(width: 6),
                  Text(
                    'Berulang: ${schedule.recurringPattern}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
