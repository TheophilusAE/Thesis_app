import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/church_group.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../utils/app_theme.dart';
import '../utils/permissions.dart';
import '../widgets/common/app_card.dart';

class AddEditGroupScreen extends StatefulWidget {
  final ChurchGroup? churchGroup;

  const AddEditGroupScreen({super.key, this.churchGroup});

  @override
  State<AddEditGroupScreen> createState() => _AddEditGroupScreenState();
}

class _AddEditGroupScreenState extends State<AddEditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _wilayahController;
  late final TextEditingController _leaderNameController;
  late final TextEditingController _leaderPhoneController;
  late final TextEditingController _meetingScheduleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  String? _categoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupProvider>().loadCategories();
    });
    _categoryId = widget.churchGroup?.categoryId;
    final churchGroup = widget.churchGroup;
    _namaController = TextEditingController(text: churchGroup?.nama ?? '');
    _wilayahController = TextEditingController(text: churchGroup?.wilayah ?? '');
    _leaderNameController = TextEditingController(text: churchGroup?.leaderName ?? '');
    _leaderPhoneController = TextEditingController(text: churchGroup?.leaderPhone ?? '');
    _meetingScheduleController = TextEditingController(text: churchGroup?.meetingSchedule ?? '');
    _locationController = TextEditingController(text: churchGroup?.location ?? '');
    _descriptionController = TextEditingController(text: churchGroup?.description ?? '');
    _isActive = churchGroup?.isActive ?? true;
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
    if (_categoryId == null && context.read<GroupProvider>().categories.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori group (Umum, Anak, atau Pemuda).')),
      );
      return;
    }
    setState(() => _isLoading = true);

    final churchGroup = ChurchGroup(
      id: widget.churchGroup?.id ?? '',
      nama: _namaController.text.trim(),
      wilayah: _wilayahController.text.trim(),
      leaderName: _leaderNameController.text.trim(),
      leaderPhone: _leaderPhoneController.text.trim(),
      meetingSchedule: _meetingScheduleController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
      categoryId: _categoryId,
      createdAt: widget.churchGroup?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<GroupProvider>();
    final success = widget.churchGroup != null
        ? await provider.updateGroup(widget.churchGroup!.id, churchGroup)
        : await provider.addGroup(churchGroup);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.churchGroup != null ? 'Group diperbarui' : 'Group ditambahkan')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan group')),
      );
    }
  }

  InputDecoration _inputDecoration({required String label, String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppTheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.neutralBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.neutralBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.churchGroup != null;
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Group' : 'Tambah Group',
          style: TextStyle(
            color: AppTheme.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
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
                  label: 'Nama Group',
                  prefixIcon: Icon(Icons.groups_rounded, color: AppTheme.primary),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final auth = context.watch<AuthProvider>();
                // Only categories this admin may create in (Super Admin: all).
                final cats = context
                    .watch<GroupProvider>()
                    .categories
                    .where((c) => auth.can(AppModule.group, PermissionAction.create, categoryId: c.id))
                    .toList();
                if (cats.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String>(
                  initialValue: cats.any((c) => c.id == _categoryId) ? _categoryId : null,
                  decoration: _inputDecoration(
                    label: 'Kategori Group',
                    prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primary),
                  ),
                  items: [
                    for (final c in cats)
                      DropdownMenuItem(value: c.id, child: Text(groupCategoryLabel(c))),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wilayahController,
                decoration: _inputDecoration(
                  label: 'Wilayah',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _leaderNameController,
                decoration: _inputDecoration(
                  label: 'Nama Pemimpin',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _leaderPhoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  label: 'Nomor Telepon Pemimpin',
                  hint: 'Contoh: 081234567890',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _meetingScheduleController,
                decoration: _inputDecoration(
                  label: 'Jadwal Pertemuan',
                  hint: 'Contoh: Setiap Jumat, 19:00',
                  prefixIcon: Icon(Icons.schedule_rounded, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration(
                  label: 'Lokasi',
                  prefixIcon: Icon(Icons.home_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration(
                  label: 'Deskripsi',
                  prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Group',
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
                          isEditing ? 'Simpan Perubahan' : 'Tambah Group',
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

