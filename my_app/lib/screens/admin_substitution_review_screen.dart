import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/service_schedule.dart';
import '../models/substitution_request.dart';
import '../providers/service_schedule_provider.dart';
import '../providers/substitution_request_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';

class AdminSubstitutionReviewScreen extends StatefulWidget {
  const AdminSubstitutionReviewScreen({super.key});

  @override
  State<AdminSubstitutionReviewScreen> createState() =>
      _AdminSubstitutionReviewScreenState();
}

class _AdminSubstitutionReviewScreenState
    extends State<AdminSubstitutionReviewScreen> {
  late SubstitutionRequestProvider _substitutionProvider;
  late ServiceScheduleProvider _scheduleProvider;
  String _statusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _substitutionProvider = context.read<SubstitutionRequestProvider>();
    _scheduleProvider = context.read<ServiceScheduleProvider>();
    _substitutionProvider.loadAllRequests();
  }

  List<SubstitutionRequest> get _filteredRequests {
    final all = _substitutionProvider.allRequests;
    if (_statusFilter == 'all') {
      return all;
    }
    return all.where((req) => req.status == _statusFilter).toList();
  }

  Future<void> _showApprovalDialog(SubstitutionRequest request) async {
    final replacementNameController =
        TextEditingController(text: request.replacementName ?? '');
    final adminNotesController =
        TextEditingController(text: request.adminNotes ?? '');

    return showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Setujui Permintaan Penggantian',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemohon: ${request.requestedByName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alasan: ${request.reason}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.neutralMedium),
                ),
                if (request.replacementName != null &&
                    request.replacementName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pengganti yang diajukan: ${request.replacementName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: replacementNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pelayan Pengganti *',
                    hintText: 'Masukkan nama pelayan pengganti',
                    filled: true,
                    fillColor: AppTheme.warmIvory,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adminNotesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan Admin (opsional)',
                    filled: true,
                    fillColor: AppTheme.warmIvory,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final replacementName = replacementNameController.text.trim();
                if (replacementName.isEmpty) return;

                await _substitutionProvider.approveRequest(
                  requestId: request.id,
                  replacementUserId: request.requestedByUserId,
                  replacementName: replacementName,
                  adminNotes: adminNotesController.text.trim().isEmpty
                      ? null
                      : adminNotesController.text.trim(),
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permintaan penggantian disetujui'),
                  ),
                );
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Setujui'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRejectionDialog(SubstitutionRequest request) async {
    final reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Tolak Permintaan Penggantian',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemohon: ${request.requestedByName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alasan: ${request.reason}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.neutralMedium),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Alasan Penolakan *',
                    hintText: 'Jelaskan mengapa permintaan ditolak',
                    filled: true,
                    fillColor: AppTheme.warmIvory,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;

                await _substitutionProvider.rejectRequest(
                  requestId: request.id,
                  adminNotes: reason,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permintaan ditolak'),
                  ),
                );
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
  }

  AppStatusBadgeType _getBadgeType(String status) {
    switch (status) {
      case 'approved':
        return AppStatusBadgeType.success;
      case 'rejected':
        return AppStatusBadgeType.error;
      case 'completed':
        return AppStatusBadgeType.info;
      default:
        return AppStatusBadgeType.warning;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Review Penggantian Tugas',
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusFilterChip('pending', 'Menunggu'),
                  const SizedBox(width: 8),
                  _statusFilterChip('approved', 'Disetujui'),
                  const SizedBox(width: 8),
                  _statusFilterChip('rejected', 'Ditolak'),
                  const SizedBox(width: 8),
                  _statusFilterChip('all', 'Semua'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<SubstitutionRequestProvider>(
              builder: (context, substitutionProvider, child) {
                final filtered = _filteredRequests;
                if (filtered.isEmpty) {
                  return Center(
                    child: AppEmptyState(
                      icon: Icons.swap_horizontal_circle_outlined,
                      title: 'Tidak Ada Permintaan',
                      description:
                          'Tidak ada pengajuan penggantian dengan status "${_getStatusLabel(_statusFilter)}".',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final request = filtered[index];
                    final schedule = _scheduleProvider.allSchedules.firstWhere(
                      (s) => s.id == request.serviceScheduleId,
                      orElse: () => ServiceSchedule(
                        id: '',
                        serviceType: 'Ibadah',
                        serviceDate: DateTime.now(),
                        pelayaniId: '',
                        pelayaniName: '',
                        pelayaniPosition: '',
                        startTime: '',
                        endTime: '',
                        isRecurring: false,
                        recurringPattern: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.swap_horiz_rounded,
                                    color: Color(0xFF92400E),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.requestedByName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppTheme.darkCharcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        schedule.serviceType,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.neutralMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppStatusBadge(
                                  label: _getStatusLabel(request.status),
                                  type: _getBadgeType(request.status),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppTheme.neutralBorder),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.neutralMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    DateFormat('EEEE, dd MMM yyyy • HH:mm', 'id_ID').format(schedule.serviceDate),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.darkCharcoal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.notes_rounded, size: 14, color: AppTheme.neutralMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Alasan: ${request.reason}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.neutralMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (request.replacementName != null &&
                                request.replacementName!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF92400E)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pengganti: ${request.replacementName}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (request.adminNotes != null &&
                                request.adminNotes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.warmIvory,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.neutralBorder),
                                ),
                                child: Text(
                                  'Catatan Admin: ${request.adminNotes}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.neutralMedium,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],

                            if (request.status == 'pending') ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.error,
                                        side: const BorderSide(color: AppTheme.error),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      onPressed: () => _showRejectionDialog(request),
                                      child: const Text('Tolak'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      onPressed: () => _showApprovalDialog(request),
                                      child: const Text('Setujui'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = value),
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
}
