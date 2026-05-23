import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/service_schedule.dart';
import '../models/substitution_request.dart';
import '../providers/auth_provider.dart';
import '../providers/service_schedule_provider.dart';
import '../providers/substitution_request_provider.dart';

class SubstitutionRequestScreen extends StatefulWidget {
  const SubstitutionRequestScreen({Key? key}) : super(key: key);

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
    _substitutionProvider.loadUserRequests(_authProvider.currentUser!.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ServiceSchedule> get _assignedSchedules {
    final currentUserId = _authProvider.currentUser!.id;
    return _scheduleProvider.allSchedules
        .where((schedule) =>
            schedule.pelayaniId == currentUserId &&
            schedule.serviceDate.isAfter(DateTime.now()))
        .toList();
  }

  Future<void> _showCreateRequestDialog(ServiceSchedule schedule) async {
    final reasonController = TextEditingController();
    final replacementNameController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Buat Permintaan Substitusi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal: ${DateFormat('dd MMM yyyy', 'id_ID').format(schedule.serviceDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Jenis: ${schedule.serviceType}'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Alasan (required)',
                    hintText: 'Jelaskan mengapa Anda membutuhkan substitusi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: replacementNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Pengganti (opsional)',
                    hintText: 'Siapa yang bisa menggantikan Anda?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                      final request = SubstitutionRequest(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        serviceScheduleId: schedule.id,
                        requestedByUserId: _authProvider.currentUser!.id,
                        requestedByName: _authProvider.currentUser!.name,
                        reason: reasonController.text.trim(),
                        replacementName:
                            replacementNameController.text.trim().isEmpty
                                ? null
                                : replacementNameController.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      await _substitutionProvider.createSubstitutionRequest(
                        request,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permintaan substitusi berhasil dibuat'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('Buat'),
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
        title: const Text('Permintaan Substitusi'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Jadwal Saya'),
            Tab(text: 'Riwayat Permintaan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Assigned Schedules
          Consumer<ServiceScheduleProvider>(
            builder: (context, scheduleProvider, child) {
              if (_assignedSchedules.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada jadwal yang tersedia',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _assignedSchedules.length,
                itemBuilder: (context, index) {
                  final schedule = _assignedSchedules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(schedule.serviceType),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, dd MMM yyyy pukul HH:mm', 'id_ID')
                                .format(schedule.serviceDate),
                          ),
                          const SizedBox(height: 4),
                          Text('${schedule.startTime} - ${schedule.endTime}'),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Minta Ganti'),
                        onPressed: () =>
                            _showCreateRequestDialog(schedule),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Tab 2: Request History
          Consumer<SubstitutionRequestProvider>(
            builder: (context, substitutionProvider, child) {
              final requests = substitutionProvider.userRequests;
              if (requests.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada permintaan substitusi',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
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
                                child: Text(
                                  schedule.serviceType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  _getStatusLabel(request.status),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor:
                                    _getStatusColor(request.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jadwal: ${DateFormat('dd MMM yyyy', 'id_ID').format(schedule.serviceDate)}',
                          ),
                          const SizedBox(height: 4),
                          Text('Alasan: ${request.reason}'),
                          if (request.replacementName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Pengganti yang disarankan: ${request.replacementName}',
                              ),
                            ),
                          if (request.replacementName != null &&
                              request.status == 'approved')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Pengganti yang disetujui: ${request.replacementName}',
                                style: const TextStyle(
                                  color: Colors.green,
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
                                  'Catatan Admin: ${request.adminNotes}',
                                  style: const TextStyle(fontSize: 12),
                                ),
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
        ],
      ),
    );
  }
}
