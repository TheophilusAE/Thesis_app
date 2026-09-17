import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sermon.dart';
import '../providers/auth_provider.dart';
import '../providers/sermon_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';

class AddEditSermonScreen extends StatefulWidget {
  final Sermon? sermon;

  const AddEditSermonScreen({super.key, this.sermon});

  @override
  State<AddEditSermonScreen> createState() => _AddEditSermonScreenState();
}

class _AddEditSermonScreenState extends State<AddEditSermonScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _speakerController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _mediaUrlController;
  late final TextEditingController _thumbnailUrlController;
  late String _mediaType;
  late DateTime _sermonDate;
  late bool _isActive;
  bool _isLoading = false;

  static const _mediaTypes = ['youtube', 'audio', 'livestream'];

  @override
  void initState() {
    super.initState();
    final sermon = widget.sermon;
    _titleController = TextEditingController(text: sermon?.title ?? '');
    _speakerController = TextEditingController(text: sermon?.speaker ?? '');
    _descriptionController = TextEditingController(text: sermon?.description ?? '');
    _mediaUrlController = TextEditingController(text: sermon?.mediaUrl ?? '');
    _thumbnailUrlController = TextEditingController(text: sermon?.thumbnailUrl ?? '');
    _mediaType = sermon?.mediaType ?? _mediaTypes.first;
    _sermonDate = sermon?.sermonDate ?? DateTime.now();
    _isActive = sermon?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _speakerController.dispose();
    _descriptionController.dispose();
    _mediaUrlController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sermonDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkCharcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _sermonDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final currentUser = context.read<AuthProvider>().currentUser;
    final sermon = Sermon(
      id: widget.sermon?.id ?? '',
      title: _titleController.text.trim(),
      speaker: _speakerController.text.trim(),
      description: _descriptionController.text.trim(),
      mediaType: _mediaType,
      mediaUrl: _mediaUrlController.text.trim(),
      thumbnailUrl:
          _thumbnailUrlController.text.trim().isEmpty ? null : _thumbnailUrlController.text.trim(),
      sermonDate: _sermonDate,
      isActive: _isActive,
      createdBy: widget.sermon?.createdBy ?? currentUser?.id,
      createdAt: widget.sermon?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<SermonProvider>();
    final success = widget.sermon != null
        ? await provider.updateSermon(widget.sermon!.id, sermon)
        : await provider.addSermon(sermon);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.sermon != null ? 'Khotbah diperbarui' : 'Khotbah ditambahkan')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan khotbah')),
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
    final isEditing = widget.sermon != null;
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Khotbah' : 'Tambah Khotbah',
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
                controller: _titleController,
                decoration: _inputDecoration(
                  label: 'Judul Khotbah',
                  prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.primary),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _speakerController,
                decoration: _inputDecoration(
                  label: 'Pembicara / Pengkhotbah',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _mediaType,
                decoration: _inputDecoration(
                  label: 'Jenis Media',
                  prefixIcon: const Icon(Icons.perm_media_outlined, color: AppTheme.primary),
                ),
                items: _mediaTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _mediaType = v ?? _mediaType),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mediaUrlController,
                decoration: _inputDecoration(
                  label: 'Tautan Media',
                  hint: 'https://youtube.com/watch?v=...',
                  prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.primary),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Tautan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thumbnailUrlController,
                decoration: _inputDecoration(
                  label: 'Tautan Thumbnail (opsional)',
                  hint: 'Kosongkan untuk YouTube — diambil otomatis',
                  prefixIcon: const Icon(Icons.image_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                  label: 'Deskripsi / Ringkasan',
                  prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
                  ),
                  title: const Text('Tanggal Khotbah', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  subtitle: Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_sermonDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkCharcoal),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedCharcoal),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status Khotbah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Tampilkan di pustaka jemaat', style: TextStyle(fontSize: 12, color: AppTheme.mutedCharcoal)),
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
                          isEditing ? 'Simpan Perubahan' : 'Tambah Khotbah',
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

