import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/service_schedule.dart';
import '../providers/service_schedule_provider.dart';
import '../providers/pelayan_provider.dart';
import 'add_edit_service_schedule_screen.dart';

class ServiceScheduleManagementScreen extends StatefulWidget {
  const ServiceScheduleManagementScreen({super.key});

  @override
  State<ServiceScheduleManagementScreen> createState() =>
      _ServiceScheduleManagementScreenState();
}

class _ServiceScheduleManagementScreenState
    extends State<ServiceScheduleManagementScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pelayanan'),
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
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari jadwal...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Schedule list
          Expanded(
            child: Consumer<ServiceScheduleProvider>(
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
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada jadwal pelayanan',
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: provider.allSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = provider.allSchedules[index];
                    return _ServiceScheduleCard(
                      schedule: schedule,
                      onEdit: () => _editSchedule(schedule),
                      onDelete: () => _deleteSchedule(schedule),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewSchedule(),
        tooltip: 'Tambah Jadwal',
        child: const Icon(Icons.add),
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
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ServiceScheduleCard extends StatelessWidget {
  final ServiceSchedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final dateStr = dateFormatter.format(schedule.serviceDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.pelayaniName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schedule.serviceType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Hapus',
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
                Icon(Icons.work, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(schedule.pelayaniPosition),
              ],
            ),
            if (schedule.isRecurring) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text('Berulang: ${schedule.recurringPattern}'),
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
