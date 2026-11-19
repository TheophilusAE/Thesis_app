import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pelayan.dart';
import '../models/service_schedule.dart';
import '../models/substitution_request.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/pelayan_provider.dart';
import '../providers/service_schedule_provider.dart';
import '../providers/substitution_request_provider.dart';
import '../utils/app_theme.dart';
import '../utils/permissions.dart';
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
  late PelayaniProvider _pelayanProvider;
  String _statusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _substitutionProvider = context.read<SubstitutionRequestProvider>();
    _scheduleProvider = context.read<ServiceScheduleProvider>();
    _pelayanProvider = context.read<PelayaniProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await Future.wait([
      _substitutionProvider.loadAllRequests(),
      _scheduleProvider.loadAllSchedules(),
      _pelayanProvider.loadAllPelayan(),
    ]);
    if (mounted) setState(() {});
  }

  ServiceSchedule? _scheduleFor(SubstitutionRequest request) {
    for (final s in _scheduleProvider.allSchedules) {
      if (s.id == request.serviceScheduleId) return s;
    }
    return null;
  }

  /// Active Pelayan who can take over [schedule]: everyone except the one
  /// currently assigned to it.
  List<Pelayan> _candidatesFor(ServiceSchedule? schedule) {
    return _pelayanProvider.allPelayan
        .where((p) => p.isAktif && p.id != schedule?.pelayaniId)
        .toList()
      ..sort((a, b) => a.nama.compareTo(b.nama));
  }

  void _showResult(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.emerald : AppTheme.errorColor,
      ),
    );
  }

  /// Approval: the database moves the duty to the chosen Pelayan and marks
  /// the request approved in ONE transaction (`review_substitution` RPC), so
  /// a failure can never leave the schedule half-reassigned. Then the people
  /// involved are notified. Returns true only when the request was approved.
  Future<bool> _approve(
    SubstitutionRequest request,
    ServiceSchedule schedule,
    Pelayan replacement,
    String? adminNotes,
  ) async {
    final notifications = context.read<NotificationProvider>();

    final approved = await _substitutionProvider.approveRequest(
      requestId: request.id,
      replacementPelayanId: replacement.id,
      adminNotes: adminNotes,
    );
    if (!approved) {
      _showResult(
        _friendlyReviewError(_substitutionProvider.error,
            fallback: 'Gagal menyetujui permintaan. Jadwal tidak diubah.'),
        success: false,
      );
      return false;
    }
    await _scheduleProvider.loadAllSchedules();

    final dateLabel = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(schedule.serviceDate);
    final sentToRequester = await notifications.notifyUsers(
      userIds: [request.requestedByUserId],
      title: 'Permintaan Penggantian Disetujui',
      message: 'Tugas ${schedule.serviceType} pada $dateLabel kini dilayani oleh ${replacement.nama}.',
      type: 'substitution',
      relatedScheduleId: schedule.id,
    );
    final sentToReplacement = !replacement.hasUserAccount ||
        await notifications.notifyUsers(
          userIds: [replacement.userId],
          title: 'Penugasan Pelayanan Baru',
          message: 'Anda ditugaskan sebagai pengganti untuk ${schedule.serviceType} pada '
              '$dateLabel (${schedule.startTime} - ${schedule.endTime}).',
          type: 'schedule',
          relatedScheduleId: schedule.id,
        );

    _showResult(
      sentToRequester && sentToReplacement
          ? 'Permintaan disetujui. Jadwal dipindahkan ke ${replacement.nama}.'
          : 'Permintaan disetujui, namun notifikasi gagal dikirim.',
      success: true,
    );
    return true;
  }

  Future<void> _showApprovalDialog(SubstitutionRequest request) async {
    final schedule = _scheduleFor(request);
    if (schedule == null) {
      _showResult(
        'Jadwal untuk permintaan ini tidak ditemukan, sehingga tidak dapat dipindahkan.',
        success: false,
      );
      return;
    }
    final candidates = _candidatesFor(schedule);
    final adminNotesController =
        TextEditingController(text: request.adminNotes ?? '');
    Pelayan? selected;
    var submitting = false;

    return showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
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
                  style: TextStyle(fontSize: 13, color: AppTheme.neutralMedium),
                ),
                if (request.requestedReplacementName != null &&
                    request.requestedReplacementName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Saran pemohon: ${request.requestedReplacementName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (candidates.isEmpty)
                  Text(
                    'Tidak ada pelayan aktif lain yang dapat ditugaskan.',
                    style: TextStyle(fontSize: 13, color: AppTheme.errorColor),
                  )
                else
                  DropdownButtonFormField<Pelayan>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Pelayan Pengganti *',
                      filled: true,
                      fillColor: AppTheme.warmIvory,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: candidates
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.posisi.isEmpty ? p.nama : '${p.nama} • ${p.posisi}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: submitting
                        ? null
                        : (p) => setDialogState(() => selected = p),
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
              onPressed: submitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (selected == null || submitting)
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      final notes = adminNotesController.text.trim();
                      final ok = await _approve(
                        request,
                        schedule,
                        selected!,
                        notes.isEmpty ? null : notes,
                      );
                      if (!dialogCtx.mounted) return;
                      if (ok) {
                        Navigator.of(dialogCtx).pop();
                      } else {
                        setDialogState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Setujui'),
            ),
          ],
          ),
        );
      },
    );
  }

  List<SubstitutionRequest> get _filteredRequests {
    final all = _substitutionProvider.allRequests;
    if (_statusFilter == 'all') {
      return all;
    }
    return all.where((req) => req.status == _statusFilter).toList();
  }

  /// Maps an RPC failure to a message for the admin. Permission errors from
  /// the database are shown as such instead of a generic network error.
  String _friendlyReviewError(String? error, {required String fallback}) {
    final msg = (error ?? '').toLowerCase();
    if (msg.contains('izin') || msg.contains('42501') || msg.contains('permission')) {
      return 'Anda tidak memiliki izin meninjau penggantian tugas. Hubungi Super Admin.';
    }
    if (msg.contains('sudah diproses')) {
      return 'Permintaan ini sudah diproses oleh admin lain.';
    }
    return fallback;
  }

  Future<bool> _reject(SubstitutionRequest request, String reason) async {
    final notifications = context.read<NotificationProvider>();
    final ok = await _substitutionProvider.rejectRequest(
      requestId: request.id,
      adminNotes: reason,
    );
    if (!ok) {
      _showResult(
        _friendlyReviewError(_substitutionProvider.error,
            fallback: 'Gagal menolak permintaan. Periksa koneksi lalu coba lagi.'),
        success: false,
      );
      return false;
    }
    final schedule = _scheduleFor(request);
    final sent = await notifications.notifyUsers(
      userIds: [request.requestedByUserId],
      title: 'Permintaan Penggantian Ditolak',
      message: schedule == null
          ? 'Permintaan penggantian Anda ditolak. Alasan: $reason'
          : 'Permintaan penggantian untuk ${schedule.serviceType} ditolak. Alasan: $reason',
      type: 'substitution',
      relatedScheduleId: schedule?.id,
    );
    _showResult(
      sent ? 'Permintaan ditolak' : 'Permintaan ditolak, namun notifikasi gagal dikirim.',
      success: true,
    );
    return true;
  }

  Future<void> _showRejectionDialog(SubstitutionRequest request) async {
    final reasonController = TextEditingController();
    var submitting = false;

    return showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
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
                  style: TextStyle(fontSize: 13, color: AppTheme.neutralMedium),
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
              onPressed: submitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: submitting
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        _showResult('Mohon isi alasan penolakan.', success: false);
                        return;
                      }
                      setDialogState(() => submitting = true);
                      final ok = await _reject(request, reason);
                      if (!dialogCtx.mounted) return;
                      if (ok) {
                        Navigator.of(dialogCtx).pop();
                      } else {
                        setDialogState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Tolak'),
            ),
          ],
          ),
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
    // UI guard only — the real gate is RLS (`subreq_select`) and the
    // `review_substitution` RPC permission check.
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdminMode || !auth.canAccess(AppModule.jadwalPelayanan)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Penggantian Tugas')),
        body: const AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Akses ditolak',
          description: 'Halaman ini hanya untuk admin.',
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: Text(
          'Review Penggantian Tugas',
          style: TextStyle(
            color: AppTheme.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
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
                    final schedule = _scheduleFor(request);

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
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppTheme.darkCharcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        schedule?.serviceType ?? 'Jadwal tidak ditemukan',
                                        style: TextStyle(
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
                            Divider(height: 1, color: AppTheme.neutralBorder),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.neutralMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    schedule == null
                                        ? 'Tanggal tidak diketahui'
                                        : '${DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(schedule.serviceDate)}'
                                            ' • ${schedule.startTime}',
                                    style: TextStyle(
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
                                Icon(Icons.notes_rounded, size: 14, color: AppTheme.neutralMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Alasan: ${request.reason}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.neutralMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (request.requestedReplacementName != null &&
                                request.requestedReplacementName!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.person_search_rounded, size: 14, color: AppTheme.neutralMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Saran pemohon: ${request.requestedReplacementName}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.neutralMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (request.status == 'approved' &&
                                request.replacementName != null &&
                                request.replacementName!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF92400E)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Pengganti: ${request.replacementName}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                      ),
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.neutralMedium,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],

                            if (request.status == 'pending' &&
                                auth.can(AppModule.jadwalPelayanan, PermissionAction.approve)) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.error,
                                        side: BorderSide(color: AppTheme.error),
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
      backgroundColor: AppTheme.surface,
      selectedColor: AppTheme.primaryLight,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
