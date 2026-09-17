import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/service_schedule.dart';
import '../models/substitution_request.dart';
import '../providers/auth_provider.dart';
import '../providers/service_schedule_provider.dart';
import '../providers/substitution_request_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';
import '../widgets/common/app_text_field.dart';

class SubstitutionRequestScreen extends StatefulWidget {
  const SubstitutionRequestScreen({super.key});

  @override
  State<SubstitutionRequestScreen> createState() =>
      _SubstitutionRequestScreenState();
}

class _SubstitutionRequestScreenState extends State<SubstitutionRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AuthProvider _authProvider;
  late SubstitutionRequestProvider _substitutionProvider;
  late ServiceScheduleProvider _scheduleProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _authProvider = context.read<AuthProvider>();
    _substitutionProvider = context.read<SubstitutionRequestProvider>();
    _scheduleProvider = context.read<ServiceScheduleProvider>();

    final user = _authProvider.currentUser;
    if (user != null) {
      _substitutionProvider.loadUserRequests(user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ServiceSchedule> get _assignedSchedules {
    final currentUserId = _authProvider.currentUser?.id;
    if (currentUserId == null) return [];
    return _scheduleProvider.allSchedules
        .where((schedule) =>
            schedule.pelayaniId == currentUserId &&
            schedule.serviceDate.isAfter(DateTime.now().subtract(const Duration(hours: 3))))
        .toList();
  }

  Future<void> _showCreateRequestSheet(ServiceSchedule schedule) async {
    final reasonController = TextEditingController();
    final replacementNameController = TextEditingController();

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
              'Ajukan Penggantian Tugas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkCharcoal,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Permohonan akan diteruskan ke Tim Koordinator Pelayanan untuk ditinjau dan disetujui.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutralMedium,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Schedule info pill
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
                  Text(
                    schedule.serviceType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13.5, color: AppTheme.neutralMedium),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(schedule.serviceDate),
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.darkCharcoal),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule_rounded, size: 13.5, color: AppTheme.neutralMedium),
                      const SizedBox(width: 6),
                      Text(
                        '${schedule.startTime} - ${schedule.endTime}',
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.darkCharcoal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: reasonController,
              label: 'Alasan Berhalangan *',
              hint: 'Jelaskan mengapa Anda memerlukan penggantian jadwal',
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: replacementNameController,
              label: 'Saran Pelayan Pengganti (Opsional)',
              hint: 'Nama rekan pelayan yang telah dihubungi / bersedia',
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
                    label: 'Kirim Permohonan',
                    variant: AppButtonVariant.primary,
                    icon: Icons.send_rounded,
                    height: 48,
                    onPressed: () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mohon isi alasan berhalangan')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      final request = SubstitutionRequest(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        serviceScheduleId: schedule.id,
                        requestedByUserId: _authProvider.currentUser!.id,
                        requestedByName: _authProvider.currentUser!.name,
                        reason: reason,
                        replacementName: replacementNameController.text.trim().isEmpty
                            ? null
                            : replacementNameController.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      await _substitutionProvider.createSubstitutionRequest(request);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permintaan penggantian berhasil diajukan'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Penggantian Tugas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.neutralMedium,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Jadwal Saya'),
            Tab(text: 'Riwayat Pengajuan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Assigned Schedules
          _buildAssignedSchedulesTab(),

          // Tab 2: Request History
          _buildRequestHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildAssignedSchedulesTab() {
    return Consumer<ServiceScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        final schedules = _assignedSchedules;

        if (schedules.isEmpty) {
          return const AppEmptyState(
            icon: Icons.event_available_outlined,
            title: 'Tidak Ada Jadwal Mendatang',
            description: 'Anda tidak memiliki penugasan pelayanan mendatang yang dapat diajukan penggantian.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];

            return AppCard(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      if (schedule.pelayaniPosition.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            schedule.pelayaniPosition,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.neutralMedium),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(schedule.serviceDate),
                        style: const TextStyle(fontSize: 13, color: AppTheme.darkCharcoal),
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
                        style: const TextStyle(fontSize: 13, color: AppTheme.darkCharcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCreateRequestSheet(schedule),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Ajukan Pengganti'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD97706),
                        side: const BorderSide(color: Color(0xFFD97706), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestHistoryTab() {
    return Consumer<SubstitutionRequestProvider>(
      builder: (context, substitutionProvider, child) {
        final requests = substitutionProvider.userRequests;

        if (requests.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history_rounded,
            title: 'Belum Ada Permintaan',
            description: 'Riwayat pengajuan penggantian jadwal tugas pelayanan akan ditampilkan di sini.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final schedule = _scheduleProvider.allSchedules.cast<ServiceSchedule?>().firstWhere(
                  (s) => s?.id == request.serviceScheduleId,
                  orElse: () => null,
                );

            final serviceTitle = schedule?.serviceType ?? 'Jadwal Pelayanan';
            final scheduleDate = schedule != null
                ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(schedule.serviceDate)
                : 'Tanggal tidak diketahui';

            return AppCard(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          serviceTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.darkCharcoal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(request.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13.5, color: AppTheme.neutralMedium),
                      const SizedBox(width: 6),
                      Text(
                        scheduleDate,
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.darkCharcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warmIvory,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.neutralBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alasan Berhalangan:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neutralMedium),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          request.reason,
                          style: const TextStyle(fontSize: 13, color: AppTheme.darkCharcoal),
                        ),
                      ],
                    ),
                  ),
                  if (request.replacementName != null && request.replacementName!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.neutralMedium),
                        const SizedBox(width: 6),
                        Text(
                          'Pengganti disarankan: ${request.replacementName}',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.darkCharcoal),
                        ),
                      ],
                    ),
                  ],
                  if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan Koordinator Pelayanan:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.adminNotes!,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const AppStatusBadge(label: 'Disetujui', status: 'completed');
      case 'rejected':
        return const AppStatusBadge(label: 'Ditolak', status: 'rejected');
      case 'completed':
        return const AppStatusBadge(label: 'Selesai', status: 'completed');
      default:
        return const AppStatusBadge(label: 'Menunggu', status: 'warning');
    }
  }
}
