import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(child: Text('Tidak ada data user'));
          }

          return _isEditing
              ? EditProfileForm(
                  user: authProvider.currentUser!,
                  onSave: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                )
              : ProfileView(user: authProvider.currentUser!);
        },
      ),
    );
  }
}

class ProfileView extends StatelessWidget {
  final User user;

  const ProfileView({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Profile Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF059669).withValues(alpha: 0.8),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        user.profileImage != null &&
                            user.profileImage!.isNotEmpty
                        ? FileImage(File(user.profileImage!))
                        : null,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child:
                        user.profileImage == null || user.profileImage!.isEmpty
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        user.role == 'admin' ? 'Admin' : 'Jemaat',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    Chip(
                      label: Text(
                        'Status: ${user.membershipStatus}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profile Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoCard(
                  title: 'Informasi Pribadi',
                  items: [
                    _InfoItem(
                      icon: Icons.phone,
                      label: 'Telepon',
                      value: user.phone,
                    ),
                    _InfoItem(
                      icon: Icons.calendar_today,
                      label: 'Tanggal Lahir',
                      value: user.birthDate != null
                          ? DateFormat('dd MMMM yyyy').format(user.birthDate!)
                          : '-',
                    ),
                    _InfoItem(
                      icon: Icons.home,
                      label: 'Alamat',
                      value: user.address ?? '-',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Informasi Jemaat',
                  items: [
                    _InfoItem(
                      icon: Icons.card_membership,
                      label: 'No. Kartu Jemaat',
                      value: user.memberCardNumber ?? '-',
                    ),
                    _InfoItem(
                      icon: Icons.water_drop,
                      label: 'Tanggal Baptis',
                      value: user.baptismDate ?? '-',
                    ),
                    _InfoItem(
                      icon: Icons.badge,
                      label: 'No. Identitas',
                      value: user.identityNumber ?? '-',
                    ),
                    _InfoItem(
                      icon: Icons.event_available,
                      label: 'Anggota Sejak',
                      value: user.memberSince ?? '-',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileForm extends StatefulWidget {
  final User user;
  final VoidCallback onSave;

  const EditProfileForm({Key? key, required this.user, required this.onSave})
    : super(key: key);

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _baptismDateController;
  late TextEditingController _identityController;
  late TextEditingController _familyGroupController;
  late TextEditingController _membershipTypeController;
  String? _profileImagePath;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address);
    _baptismDateController = TextEditingController(
      text: widget.user.baptismDate,
    );
    _identityController = TextEditingController(text: widget.user.identityNumber);
    _familyGroupController = TextEditingController(text: widget.user.familyGroup);
    _membershipTypeController = TextEditingController(text: widget.user.membershipType);
    _profileImagePath = widget.user.profileImage;
    _selectedBirthDate = widget.user.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _baptismDateController.dispose();
    _identityController.dispose();
    _familyGroupController.dispose();
    _membershipTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
      });
    }
  }

  Future<void> _save() async {
    final updatedUser = widget.user.copyWith(
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      baptismDate: _baptismDateController.text,
      identityNumber: _identityController.text,
      familyGroup: _familyGroupController.text,
      membershipType: _membershipTypeController.text,
      profileImage: _profileImagePath,
      birthDate: _selectedBirthDate,
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(updatedUser);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      widget.onSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImagePath != null
                      ? FileImage(File(_profileImagePath!))
                      : null,
                  child: _profileImagePath == null
                      ? Text(
                          widget.user.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 48),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Nomor Telepon',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Alamat',
              prefixIcon: Icon(Icons.home),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectBirthDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal Lahir',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              child: Text(
                _selectedBirthDate != null
                    ? DateFormat('dd MMMM yyyy').format(_selectedBirthDate!)
                    : 'Pilih tanggal',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _baptismDateController,
            decoration: const InputDecoration(
              labelText: 'Tanggal Baptis',
              prefixIcon: Icon(Icons.water_drop),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _identityController,
            decoration: const InputDecoration(
              labelText: 'No. Identitas',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _familyGroupController,
            decoration: const InputDecoration(
              labelText: 'Komunitas/Kelompok',
              prefixIcon: Icon(Icons.groups),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _membershipTypeController,
            decoration: const InputDecoration(
              labelText: 'Jenis Keanggotaan',
              prefixIcon: Icon(Icons.card_membership),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoCard({Key? key, required this.title, required this.items})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(item.icon, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          Text(
                            item.value,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({required this.icon, required this.label, required this.value});
}
