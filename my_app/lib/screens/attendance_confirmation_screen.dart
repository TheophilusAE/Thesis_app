import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attendance_confirmation.dart';
import '../models/service_schedule.dart';
import '../providers/attendance_confirmation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/service_schedule_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';
import '../widgets/common/app_text_field.dart';

class AttendanceConfirmationScreen extends StatefulWidget {
  const AttendanceConfirmationScreen({super.key});

  @override
  State<AttendanceConfirmationScreen> createState() =>
      _AttendanceConfirmationScreenState();
}

class _AttendanceConfirmationScreenState
    extends State<AttendanceConfirmationScreen> {
  late AuthProvider _authProvider;
  late AttendanceConfirmationProvider _attendanceProvider;
  late ServiceScheduleProvider _scheduleProvider;
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _attendanceProvider = context.read<AttendanceConfirmationProvider>();
    _scheduleProvider = context.read<ServiceScheduleProvider>();

    final user = _authProvider.currentUser;
    if (user != null) {
      _attendanceProvider.loadUserConfirmations(user.id);
    }
  }

  List<AttendanceConfirmation> get _filteredConfirmations {
    final all = _attendanceProvider.userConfirmations;
    if (_filterStatus == 'all') {
      return all;
    } else if (_filterStatus == 'pending') {
      return all.where((ac) => !ac.confirmed).toList();
    } else {
      return all.where((ac) => ac.confirmed).toList();
    }
  }

  ServiceSchedule? _findSchedule(String scheduleId) {
    try {
      return _scheduleProvider.allSchedules.firstWhere((s) => s.id == scheduleId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showConfirmSheet(
      AttendanceConfirmation confirmation, ServiceSchedule schedule) async {
    final notesController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutralBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Konfirmasi Kehadiran Tugas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pastikan Anda dapat hadir tepat waktu untuk mempersiapkan pelayanan ibadah.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutralMedium,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warmIvory,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.neutralBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.church_rounded, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        schedule.serviceType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.darkCharcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.neutralMedium),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(schedule.serviceDate),
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.darkCharcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.neutralMedium),
                      const SizedBox(width: 8),
                      Text(
                        '${schedule.startTime} - ${schedule.endTime} WIB',
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.darkCharcoal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: notesController,
              label: 'Catatan Kehadiran (Opsional)',
              hint: 'Contoh: Hadir bersama tim multimedia pk 06.30',
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Batal',
                    variant: AppButtonVariant.outline,
                    height: 48,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Konfirmasi Hadir',
                    variant: AppButtonVariant.primary,
                    icon: Icons.check_circle_outline_rounded,
                    height: 48,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final notes = notesController.text.trim();
                      await _attendanceProvider.confirmAttendance(
                        confirmation.id,
                        notes.isEmpty ? null : notes,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kehadiran pelayanan berhasil dikonfirmasi'),
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(AttendanceConfirmation confirmation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Batalkan Konfirmasi'),
          content: const Text(
            'Apakah Anda yakin ingin membatalkan konfirmasi kehadiran ini? Status tugas akan kembali menjadi belum dikonfirmasi.',
            style: TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Tidak', style: TextStyle(color: AppTheme.neutralMedium)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Batalkan Konfirmasi'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _attendanceProvider.cancelConfirmation(confirmation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kehadiran dibatalkan'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Konfirmasi Kehadiran'),
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          _buildFilterTabs(),

          // Main List
          Expanded(
            child: Consumer<AttendanceConfirmationProvider>(
              builder: (context, attendanceProvider, child) {
                final filtered = _filteredConfirmations;

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.how_to_reg_outlined,
                    title: 'Tidak Ada Konfirmasi Kehadiran',
                    description: _filterStatus == 'pending'
                        ? 'Semua jadwal pelayanan Anda saat ini sudah dikonfirmasi.'
                        : 'Tidak ada data konfirmasi kehadiran untuk filter ini.',
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () async {
                    final user = _authProvider.currentUser;
                    if (user != null) {
                      await _attendanceProvider.loadUserConfirmations(user.id);
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final confirmation = filtered[index];
                      final schedule = _findSchedule(confirmation.serviceScheduleId);

                      return _buildConfirmationCard(context, confirmation, schedule);
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

  Widget _buildFilterTabs() {
    final all = _attendanceProvider.userConfirmations;
    final pendingCount = all.where((c) => !c.confirmed).length;
    final confirmedCount = all.where((c) => c.confirmed).length;

    final tabs = [
      {'key': 'pending', 'label': 'Belum Konfirmasi', 'count': pendingCount},
      {'key': 'confirmed', 'label': 'Sudah Dikonfirmasi', 'count': confirmedCount},
      {'key': 'all', 'label': 'Semua', 'count': all.length},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.neutralBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final key = tab['key'] as String;
            final label = tab['label'] as String;
            final count = tab['count'] as int;
            final isSelected = _filterStatus == key;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: isSelected,
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.warmIvory,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.darkCharcoal,
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white24 : AppTheme.neutralBorder,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.neutralMedium,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _filterStatus = key);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(
    BuildContext context,
    AttendanceConfirmation confirmation,
    ServiceSchedule? schedule,
  ) {
    if (schedule == null) {
      return AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const Icon(Icons.event_busy_rounded, color: AppTheme.neutralMedium),
          title: const Text('Jadwal Tidak Ditemukan'),
          subtitle: Text('ID: ${confirmation.serviceScheduleId}'),
        ),
      );
    }

    final isConfirmed = confirmation.confirmed;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Service Type & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  schedule.serviceType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.darkCharcoal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isConfirmed)
                const AppStatusBadge(
                  label: 'Dikonfirmasi',
                  status: 'completed',
                )
              else
                const AppStatusBadge(
                  label: 'Menunggu',
                  status: 'warning',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Date & Time
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.neutralMedium),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(schedule.serviceDate),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.neutralMedium),
              const SizedBox(width: 8),
              Text(
                '${schedule.startTime} - ${schedule.endTime} WIB',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.darkCharcoal,
                ),
              ),
            ],
          ),

          // Role/Posisi Tugas
          if (schedule.pelayaniPosition.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_outlined, size: 13, color: AppTheme.primaryDark),
                  const SizedBox(width: 6),
                  Text(
                    'Peran: ${schedule.pelayaniPosition}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Confirmation time info
          if (isConfirmed && confirmation.confirmedAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.emerald),
                const SizedBox(width: 6),
                Text(
                  'Dikonfirmasi pada ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(confirmation.confirmedAt!)} WIB',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.emerald,
                  ),
                ),
              ],
            ),
          ],

          // Notes
          if (confirmation.notes != null && confirmation.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warmIvory,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.neutralBorder),
              ),
              child: Text(
                'Catatan: ${confirmation.notes}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.neutralMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Actions
          if (!isConfirmed)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Konfirmasi Kehadiran',
                icon: Icons.check_circle_rounded,
                variant: AppButtonVariant.primary,
                height: 44,
                onPressed: () => _showConfirmSheet(confirmation, schedule),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(confirmation),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Batalkan Konfirmasi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
