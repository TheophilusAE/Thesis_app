import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/training_schedule.dart';
import '../providers/training_schedule_provider.dart';
import '../providers/pelayan_provider.dart';

class AddEditTrainingScheduleScreen extends StatefulWidget {
  final TrainingSchedule? schedule;

  const AddEditTrainingScheduleScreen({super.key, this.schedule});

  @override
  State<AddEditTrainingScheduleScreen> createState() =>
      _AddEditTrainingScheduleScreenState();
}

class _AddEditTrainingScheduleScreenState
    extends State<AddEditTrainingScheduleScreen> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _lokasiController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late List<String> _selectedPelayaniIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _namaController = TextEditingController(text: widget.schedule?.nama ?? '');
    _deskripsiController =
        TextEditingController(text: widget.schedule?.deskripsi ?? '');
    _startTimeController =
        TextEditingController(text: widget.schedule?.startTime ?? '09:00');
    _endTimeController =
        TextEditingController(text: widget.schedule?.endTime ?? '11:00');
    _lokasiController = TextEditingController(text: widget.schedule?.lokasi ?? '');
    _notesController = TextEditingController(text: widget.schedule?.notes ?? '');

    _selectedDate = widget.schedule?.trainingDate ?? DateTime.now();
    _selectedPelayaniIds = widget.schedule?.pelayaniIds ?? [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PelayaniProvider>().loadActivePelayan();
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _lokasiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Jadwal Latihan' : 'Tambah Jadwal Latihan'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Latihan',
                  hintText: 'Contoh: Latihan Opsir',
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama latihan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Deskripsi
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Tanggal
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  hintText: DateFormat('dd/MM/yyyy').format(_selectedDate),
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Start time
              TextFormField(
                controller: _startTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Jam Mulai',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () => _selectTime(context, true),
              ),
              const SizedBox(height: 16),

              // End time
              TextFormField(
                controller: _endTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Jam Selesai',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () => _selectTime(context, false),
              ),
              const SizedBox(height: 16),

              // Lokasi
              TextFormField(
                controller: _lokasiController,
                decoration: InputDecoration(
                  labelText: 'Lokasi',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lokasi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pelayan selection
              const Text(
                'Pilih Peserta Latihan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Consumer<PelayaniProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const CircularProgressIndicator();
                  }

                  final pelayaniList = provider.filteredPelayan;

                  return Wrap(
                    spacing: 8,
                    children: pelayaniList
                        .map((p) => FilterChip(
                          label: Text(p.nama),
                          selected: _selectedPelayaniIds.contains(p.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPelayaniIds.add(p.id);
                              } else {
                                _selectedPelayaniIds.remove(p.id);
                              }
                            });
                          },
                        ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Simpan Perubahan' : 'Tambah Latihan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final currentTime =
        isStartTime ? _startTimeController.text : _endTimeController.text;
    final timeParts = currentTime.split(':');
    final initialHour = int.parse(timeParts[0]);
    final initialMinute = int.parse(timeParts[1]);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStartTime) {
          _startTimeController.text = formattedTime;
        } else {
          _endTimeController.text = formattedTime;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<TrainingScheduleProvider>();
      final isEditing = widget.schedule != null;

      if (isEditing) {
        final success = await provider.updateTrainingSchedule(
          widget.schedule!.id,
          nama: _namaController.text.trim(),
          trainingDate: _selectedDate,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          deskripsi: _deskripsiController.text.trim(),
          pelayaniIds: _selectedPelayaniIds,
          lokasi: _lokasiController.text.trim(),
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil diperbarui')),
          );
          Navigator.pop(context);
        }
      } else {
        final success = await provider.addTrainingSchedule(
          nama: _namaController.text.trim(),
          trainingDate: _selectedDate,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          deskripsi: _deskripsiController.text.trim(),
          pelayaniIds: _selectedPelayaniIds,
          lokasi: _lokasiController.text.trim(),
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
