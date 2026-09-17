import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/komsel.dart';
import '../providers/komsel_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';

class AddEditKomselScreen extends StatefulWidget {
  final Komsel? komsel;

  const AddEditKomselScreen({super.key, this.komsel});

  @override
  State<AddEditKomselScreen> createState() => _AddEditKomselScreenState();
}

class _AddEditKomselScreenState extends State<AddEditKomselScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _wilayahController;
  late final TextEditingController _leaderNameController;
  late final TextEditingController _leaderPhoneController;
  late final TextEditingController _meetingScheduleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final komsel = widget.komsel;
    _namaController = TextEditingController(text: komsel?.nama ?? '');
    _wilayahController = TextEditingController(text: komsel?.wilayah ?? '');
    _leaderNameController = TextEditingController(text: komsel?.leaderName ?? '');
    _leaderPhoneController = TextEditingController(text: komsel?.leaderPhone ?? '');
    _meetingScheduleController = TextEditingController(text: komsel?.meetingSchedule ?? '');
    _locationController = TextEditingController(text: komsel?.location ?? '');
    _descriptionController = TextEditingController(text: komsel?.description ?? '');
    _isActive = komsel?.isActive ?? true;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _wilayahController.dispose();
    _leaderNameController.dispose();
    _leaderPhoneController.dispose();
    _meetingScheduleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final komsel = Komsel(
      id: widget.komsel?.id ?? '',
      nama: _namaController.text.trim(),
      wilayah: _wilayahController.text.trim(),
      leaderName: _leaderNameController.text.trim(),
      leaderPhone: _leaderPhoneController.text.trim(),
      meetingSchedule: _meetingScheduleController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
      createdAt: widget.komsel?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<KomselProvider>();
    final success = widget.komsel != null
        ? await provider.updateKomsel(widget.komsel!.id, komsel)
        : await provider.addKomsel(komsel);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.komsel != null ? 'Komsel diperbarui' : 'Komsel ditambahkan')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan komsel')),
      );
    }
  }

  InputDecoration _inputDecoration({required String label, String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.neutralBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.neutralBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.komsel != null;
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Komsel' : 'Tambah Komsel',
          style: const TextStyle(
            color: AppTheme.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: _inputDecoration(
                  label: 'Nama Komsel',
                  prefixIcon: const Icon(Icons.groups_rounded, color: AppTheme.primary),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wilayahController,
                decoration: _inputDecoration(
                  label: 'Wilayah',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _leaderNameController,
                decoration: _inputDecoration(
                  label: 'Nama Pemimpin',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _leaderPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  label: 'Nomor Telepon Pemimpin',
                  hint: 'Contoh: 081234567890',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _meetingScheduleController,
                decoration: _inputDecoration(
                  label: 'Jadwal Pertemuan',
                  hint: 'Contoh: Setiap Jumat, 19:00',
                  prefixIcon: const Icon(Icons.schedule_rounded, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration(
                  label: 'Lokasi',
                  prefixIcon: const Icon(Icons.home_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                  label: 'Deskripsi',
                  prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Komsel',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tampilkan di direktori jemaat',
                          style: TextStyle(fontSize: 12, color: AppTheme.mutedCharcoal),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _isActive,
                      activeTrackColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEditing ? 'Simpan Perubahan' : 'Tambah Komsel',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

