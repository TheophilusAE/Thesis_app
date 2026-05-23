import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pelayan.dart';
import '../providers/pelayan_provider.dart';

class AddEditPelayaniScreen extends StatefulWidget {
  final Pelayan? pelayan;

  const AddEditPelayaniScreen({Key? key, this.pelayan}) : super(key: key);

  @override
  State<AddEditPelayaniScreen> createState() => _AddEditPelayaniScreenState();
}

class _AddEditPelayaniScreenState extends State<AddEditPelayaniScreen> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _namaController;
  late TextEditingController _noTeleponController;
  late TextEditingController _posisiController;
  late bool _isAktif;
  bool _isLoading = false;

  // Default positions
  static const List<String> positions = [
    'Opsir',
    'Cantor',
    'Penjaga',
    'Musisi',
    'Pemandu Doa',
    'Penatalayan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _namaController = TextEditingController(text: widget.pelayan?.nama ?? '');
    _noTeleponController = TextEditingController(text: widget.pelayan?.noTelepon ?? '');
    _posisiController = TextEditingController(text: widget.pelayan?.posisi ?? '');
    _isAktif = widget.pelayan?.isAktif ?? true;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noTeleponController.dispose();
    _posisiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pelayan != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Pelayan' : 'Tambah Pelayan'),
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
              // Nama field
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Pelayan',
                  hintText: 'Masukkan nama pelayan',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  if (value.trim().length < 3) {
                    return 'Nama minimal 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // No Telepon field
              TextFormField(
                controller: _noTeleponController,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  hintText: 'Contoh: 081234567890',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  if (!RegExp(r'^0\d{9,12}$').hasMatch(value.trim())) {
                    return 'Nomor telepon harus dimulai 0 dan berisi 10-13 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Posisi field (dropdown)
              DropdownButtonFormField<String>(
                value: _posisiController.text.isNotEmpty ? _posisiController.text : null,
                decoration: InputDecoration(
                  labelText: 'Posisi Pelayanan',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _posisiController.text = value;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Posisi harus dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status Aktif toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Pelayan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Switch(
                        value: _isAktif,
                        onChanged: (value) {
                          setState(() => _isAktif = value);
                        },
                      ),
                    ],
                  ),
                ),
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
                      : Text(isEditing ? 'Simpan Perubahan' : 'Tambah Pelayan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<PelayaniProvider>();
      final isEditing = widget.pelayan != null;

      if (isEditing) {
        final success = await provider.updatePelayan(
          widget.pelayan!.id,
          nama: _namaController.text.trim(),
          noTelepon: _noTeleponController.text.trim(),
          posisi: _posisiController.text,
          isAktif: _isAktif,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelayan berhasil diperbarui')),
          );
          Navigator.pop(context);
        }
      } else {
        // For adding new Pelayan, we need a userId
        // In this case, we'll use a temporary ID - should be updated based on logged-in user
        final userId = 'admin-user'; // This should come from auth provider

        final success = await provider.addPelayan(
          userId: userId,
          nama: _namaController.text.trim(),
          noTelepon: _noTeleponController.text.trim(),
          posisi: _posisiController.text,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelayan berhasil ditambahkan')),
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
