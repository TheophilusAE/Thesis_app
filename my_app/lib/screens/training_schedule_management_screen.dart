import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/training_schedule.dart';
import '../providers/training_schedule_provider.dart';
import 'add_edit_training_schedule_screen.dart';

class TrainingScheduleManagementScreen extends StatefulWidget {
  const TrainingScheduleManagementScreen({super.key});

  @override
  State<TrainingScheduleManagementScreen> createState() =>
      _TrainingScheduleManagementScreenState();
}

class _TrainingScheduleManagementScreenState
    extends State<TrainingScheduleManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrainingScheduleProvider>().loadAllSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Latihan'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
        ),
      ),
      body: Consumer<TrainingScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.allSchedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada jadwal latihan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.allSchedules.length,
            itemBuilder: (context, index) {
              final schedule = provider.allSchedules[index];
              return _TrainingScheduleCard(
                schedule: schedule,
                onEdit: () => _editSchedule(schedule),
                onDelete: () => _deleteSchedule(schedule),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewSchedule(),
        tooltip: 'Tambah Jadwal Latihan',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNewSchedule() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditTrainingScheduleScreen(),
          ),
        )
        .then((_) {
          if (mounted) context.read<TrainingScheduleProvider>().loadAllSchedules();
        });
  }

  void _editSchedule(TrainingSchedule schedule) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                AddEditTrainingScheduleScreen(schedule: schedule),
          ),
        )
        .then((_) {
          if (mounted) context.read<TrainingScheduleProvider>().loadAllSchedules();
        });
  }

  void _deleteSchedule(TrainingSchedule schedule) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Jadwal Latihan?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus jadwal ${schedule.nama}?',
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
                  .read<TrainingScheduleProvider>()
                  .deleteTrainingSchedule(schedule.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jadwal berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TrainingScheduleCard extends StatelessWidget {
  final TrainingSchedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TrainingScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final dateStr = dateFormatter.format(schedule.trainingDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schedule.deskripsi,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(dateStr),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('${schedule.startTime} - ${schedule.endTime}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(child: Text(schedule.lokasi)),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text('${schedule.pelayaniIds.length} Peserta'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
