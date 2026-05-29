import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/service_schedule.dart';
import '../models/substitution_request.dart';
import '../providers/service_schedule_provider.dart';
import '../providers/substitution_request_provider.dart';

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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Setujui Permintaan Substitusi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diminta oleh: ${request.requestedByName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Alasan: ${request.reason}'),
                if (request.replacementName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child:
                        Text('Pengganti yang disarankan: ${request.replacementName}'),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: replacementNameController,
                  decoration: InputDecoration(
                    labelText: 'Pengganti yang Disetujui (required)',
                    hintText: 'Nama pelayan pengganti',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adminNotesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan Admin (opsional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: replacementNameController.text.trim().isEmpty
                  ? null
                  : () async {
                      await _substitutionProvider.approveRequest(
                        requestId: request.id,
                        replacementUserId: request.requestedByUserId,
                        replacementName: replacementNameController.text.trim(),
                        adminNotes: adminNotesController.text.trim().isEmpty
                            ? null
                            : adminNotesController.text.trim(),
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permintaan disetujui'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tolak Permintaan Substitusi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diminta oleh: ${request.requestedByName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Alasan: ${request.reason}'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Alasan Penolakan (required)',
                    hintText: 'Jelaskan mengapa permintaan ditolak',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: reasonController.text.trim().isEmpty
                  ? null
                  : () async {
                      await _substitutionProvider.rejectRequest(
                        requestId: request.id,
                        adminNotes: reasonController.text.trim(),
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permintaan ditolak'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    },
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Permintaan Substitusi'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'pending', label: Text('Menunggu')),
                      ButtonSegment(value: 'approved', label: Text('Disetujui')),
                      ButtonSegment(value: 'rejected', label: Text('Ditolak')),
                      ButtonSegment(value: 'all', label: Text('Semua')),
                    ],
                    selected: <String>{_statusFilter},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _statusFilter = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SubstitutionRequestProvider>(
              builder: (context, substitutionProvider, child) {
                final filtered = _filteredRequests;
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada permintaan ${_getStatusLabel(_statusFilter).toLowerCase()}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final request = filtered[index];
                  final schedule = _scheduleProvider.allSchedules
                      .firstWhere(
                        (s) => s.id == request.serviceScheduleId,
                        orElse: () => ServiceSchedule(
                          id: '',
                          serviceType: 'Unknown',
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.requestedByName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        schedule.serviceType,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    _getStatusLabel(request.status),
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor:
                                      _getStatusColor(request.status),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            Text(
                              'Jadwal: ${DateFormat('EEEE, dd MMM yyyy pukul HH:mm', 'id_ID').format(schedule.serviceDate)}',
                            ),
                            const SizedBox(height: 4),
                            Text('Alasan: ${request.reason}'),
                            if (request.replacementName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Pengganti: ${request.replacementName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (request.adminNotes != null &&
                                request.adminNotes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Catatan: ${request.adminNotes}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            if (request.status == 'pending')
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          _showRejectionDialog(request),
                                      child: const Text('Tolak'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _showApprovalDialog(request),
                                      child: const Text('Setujui'),
                                    ),
                                  ],
                                ),
                              ),
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
}
