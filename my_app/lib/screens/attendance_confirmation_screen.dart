import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/attendance_confirmation.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_confirmation_provider.dart';
import '../providers/service_schedule_provider.dart';

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

    // Load user's attendance confirmations
    _attendanceProvider
        .loadUserConfirmations(_authProvider.currentUser!.id);
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

  Future<void> _showConfirmDialog(
      AttendanceConfirmation confirmation) async {
    final notesController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final schedule = _scheduleProvider.allSchedules.firstWhere(
          (s) => s.id == confirmation.serviceScheduleId,
          orElse: () => throw Exception('Schedule not found'),
        );

        return AlertDialog(
          title: const Text('Konfirmasi Kehadiran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal: ${schedule.serviceType}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tanggal: ${DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(schedule.serviceDate)}',
                ),
                Text(
                  'Waktu: ${schedule.startTime} - ${schedule.endTime}',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan (opsional)',
                    hintText: 'Tambahkan catatan tentang kehadiran Anda',
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
              onPressed: () async {
                await _attendanceProvider.confirmAttendance(
                  confirmation.id,
                  notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kehadiran berhasil dikonfirmasi'),
                    backgroundColor: Colors.green,
                  ),
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Konfirmasi Hadir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelDialog(
      AttendanceConfirmation confirmation) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Batalkan Konfirmasi'),
          content: const Text(
              'Apakah Anda yakin ingin membatalkan konfirmasi kehadiran ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _attendanceProvider.cancelConfirmation(confirmation.id);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Konfirmasi dibatalkan'),
                    backgroundColor: Colors.orange,
                  ),
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Batalkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Kehadiran'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Belum')),
                ButtonSegment(value: 'confirmed', label: Text('Sudah')),
                ButtonSegment(value: 'all', label: Text('Semua')),
              ],
              selected: <String>{_filterStatus},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _filterStatus = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<AttendanceConfirmationProvider>(
              builder: (context, attendanceProvider, child) {
                final filtered = _filteredConfirmations;
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada konfirmasi kehadiran',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final confirmation = filtered[index];
                    final schedule = _scheduleProvider.allSchedules
                        .firstWhere(
                          (s) => s.id == confirmation.serviceScheduleId,
                          orElse: () => throw Exception(
                            'Schedule not found',
                          ),
                        );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(schedule.serviceType),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, dd MMM yyyy', 'id_ID')
                                  .format(schedule.serviceDate),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${schedule.startTime} - ${schedule.endTime}',
                            ),
                            if (confirmation.confirmed)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Dikonfirmasi: ${DateFormat('dd MMM HH:mm', 'id_ID').format(confirmation.confirmedAt!)}',
                                      style:
                                          const TextStyle(color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            if (confirmation.notes != null &&
                                confirmation.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Catatan: ${confirmation.notes}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!confirmation.confirmed)
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () =>
                                      _showConfirmDialog(confirmation),
                                  tooltip: 'Konfirmasi',
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _showCancelDialog(confirmation),
                                  tooltip: 'Batalkan',
                                ),
                            ],
                          ),
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
