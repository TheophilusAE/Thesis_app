import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/service_schedule.dart';
import '../models/pelayan.dart';
import '../providers/service_schedule_provider.dart';
import '../providers/pelayan_provider.dart';

class AddEditServiceScheduleScreen extends StatefulWidget {
  final ServiceSchedule? schedule;

  const AddEditServiceScheduleScreen({super.key, this.schedule});

  @override
  State<AddEditServiceScheduleScreen> createState() =>
      _AddEditServiceScheduleScreenState();
}

class _AddEditServiceScheduleScreenState
    extends State<AddEditServiceScheduleScreen> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _namaJenisController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late Pelayan? _selectedPelayan;
  late bool _isRecurring;
  late String _recurringPattern;
  bool _isLoading = false;

  static const List<String> serviceTypes = [
    'Ibadah Minggu',
    'Ibadah Malam',
    'Doa Syafaat',
    'Ibadah Pemuda',
    'Ibadah Anak-Anak',
    'Lainnya',
  ];

  static const List<String> recurringPatterns = [
    'WEEKLY',
    'BI_WEEKLY',
    'MONTHLY',
  ];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _namaJenisController = TextEditingController(text: widget.schedule?.serviceType ?? '');
    _startTimeController =
        TextEditingController(text: widget.schedule?.startTime ?? '07:00');
    _endTimeController =
        TextEditingController(text: widget.schedule?.endTime ?? '12:00');
    _notesController = TextEditingController(text: widget.schedule?.notes ?? '');

    _selectedDate = widget.schedule?.serviceDate ?? DateTime.now();
    _selectedPelayan = null;
    _isRecurring = widget.schedule?.isRecurring ?? false;
    _recurringPattern =
        widget.schedule?.recurringPattern ?? 'WEEKLY';
  }

  @override
  void dispose() {
    _namaJenisController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Jadwal' : 'Tambah Jadwal'),
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
              // Pelayan selection
              if (!isEditing) ...[
                const Text(
                  'Pilih Pelayan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Consumer<PelayaniProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const CircularProgressIndicator();
                    }

                    final pelayaniList = provider.allPelayan
                        .where((p) => p.isAktif)
                        .toList();

                    return DropdownButtonFormField<Pelayan>(
                      initialValue: _selectedPelayan,
                      decoration: InputDecoration(
                        labelText: 'Pilih Pelayan',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: pelayaniList
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.nama),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedPelayan = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih pelayan';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Service type
              DropdownButtonFormField<String>(
                initialValue: _namaJenisController.text.isNotEmpty
                    ? _namaJenisController.text
                    : null,
                decoration: InputDecoration(
                  labelText: 'Jenis Ibadah',
                  prefixIcon: const Icon(Icons.church),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: serviceTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _namaJenisController.text = value;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih jenis ibadah';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date picker
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
                validator: (_) => null,
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

              // Recurring toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jadwal Berulang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() => _isRecurring = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring pattern
              if (_isRecurring)
                DropdownButtonFormField<String>(
                  initialValue: _recurringPattern,
                  decoration: InputDecoration(
                    labelText: 'Pola Pengulangan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: recurringPatterns
                      .map((pattern) => DropdownMenuItem(
                            value: pattern,
                            child: Text(pattern),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _recurringPattern = value);
                    }
                  },
                ),
              if (_isRecurring) const SizedBox(height: 16),

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
                      : Text(isEditing ? 'Simpan Perubahan' : 'Tambah Jadwal'),
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
      final provider = context.read<ServiceScheduleProvider>();
      final isEditing = widget.schedule != null;

      if (isEditing) {
        final success = await provider.updateServiceSchedule(
          widget.schedule!.id,
          serviceDate: _selectedDate,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          serviceType: _namaJenisController.text,
          isRecurring: _isRecurring,
          recurringPattern: _recurringPattern,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil diperbarui')),
          );
          Navigator.pop(context);
        }
      } else {
        if (_selectedPelayan == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih pelayan terlebih dahulu')),
          );
          return;
        }

        final success = await provider.addServiceSchedule(
          pelayaniId: _selectedPelayan!.id,
          pelayaniName: _selectedPelayan!.nama,
          pelayaniPosition: _selectedPelayan!.posisi,
          serviceDate: _selectedDate,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          serviceType: _namaJenisController.text,
          isRecurring: _isRecurring,
          recurringPattern: _recurringPattern,
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
