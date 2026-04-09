import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _query = '';
  bool _loading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loadPendingUsers();
    _users = await authProvider.getAllUsers();
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _reloadUsers() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.loadPendingUsers();
    _users = await authProvider.getAllUsers();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  List<User> get _filteredUsers {
    return _users.where((user) {
      final matchesFilter = switch (_selectedFilter) {
        'admin' => user.role == 'admin',
        'jemaat' => user.role == 'jemaat',
        'pending' => user.membershipStatus == 'pending',
        'verified' => user.membershipStatus == 'verified',
        _ => true,
      };

      final searchTarget = [
        user.name,
        user.email,
        user.phone,
        user.identityNumber ?? '',
        user.familyGroup ?? '',
        user.memberCardNumber ?? '',
        user.address ?? '',
      ].join(' ').toLowerCase();

      final matchesSearch = _query.isEmpty || searchTarget.contains(_query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  double _profileCompleteness(User user) {
    final checks = [
      user.name.trim().isNotEmpty,
      user.email.trim().isNotEmpty,
      user.phone.trim().isNotEmpty,
      (user.identityNumber ?? '').trim().isNotEmpty,
      (user.address ?? '').trim().isNotEmpty,
      (user.familyGroup ?? '').trim().isNotEmpty,
      (user.memberCardNumber ?? '').trim().isNotEmpty,
    ];
    return checks.where((entry) => entry).length / checks.length;
  }

  Future<void> _verify(User user, bool approved) async {
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.verifyUser(userId: user.id, approved: approved);
    if (ok) {
      await _reloadUsers();
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approved ? 'Jemaat berhasil diverifikasi.' : 'Pendaftaran jemaat ditolak.')
              : 'Proses verifikasi gagal.',
        ),
      ),
    );
  }

  Future<void> _editUser(User user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final identityController = TextEditingController(text: user.identityNumber ?? '');
    final familyController = TextEditingController(text: user.familyGroup ?? '');
    final membershipTypeController = TextEditingController(text: user.membershipType ?? '');
    final memberCardController = TextEditingController(text: user.memberCardNumber ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
    final memberSinceController = TextEditingController(text: user.memberSince ?? '');
    final baptismController = TextEditingController(text: user.baptismDate ?? '');
    String membershipStatus = user.membershipStatus;

    final updatedUser = await showDialog<User>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${user.name}'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nama'),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Telepon'),
                      ),
                      TextField(
                        controller: identityController,
                        decoration: const InputDecoration(labelText: 'NIK'),
                      ),
                      TextField(
                        controller: familyController,
                        decoration: const InputDecoration(labelText: 'Komunitas / Family Group'),
                      ),
                      TextField(
                        controller: membershipTypeController,
                        decoration: const InputDecoration(labelText: 'Tipe Keanggotaan'),
                      ),
                      TextField(
                        controller: memberCardController,
                        decoration: const InputDecoration(labelText: 'Nomor Kartu Anggota'),
                      ),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                      ),
                      TextField(
                        controller: memberSinceController,
                        decoration: const InputDecoration(labelText: 'Member Sejak'),
                      ),
                      TextField(
                        controller: baptismController,
                        decoration: const InputDecoration(labelText: 'Tanggal Baptis'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: membershipStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'verified', child: Text('Verified')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() {
                            membershipStatus = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      user.copyWith(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        phone: phoneController.text.trim(),
                        identityNumber: identityController.text.trim().isEmpty
                            ? null
                            : identityController.text.trim(),
                        familyGroup: familyController.text.trim().isEmpty
                            ? null
                            : familyController.text.trim(),
                        membershipType: membershipTypeController.text.trim().isEmpty
                            ? null
                            : membershipTypeController.text.trim(),
                        memberCardNumber: memberCardController.text.trim().isEmpty
                            ? null
                            : memberCardController.text.trim(),
                        address: addressController.text.trim().isEmpty
                            ? null
                            : addressController.text.trim(),
                        memberSince: memberSinceController.text.trim().isEmpty
                            ? null
                            : memberSinceController.text.trim(),
                        baptismDate: baptismController.text.trim().isEmpty
                            ? null
                            : baptismController.text.trim(),
                        membershipStatus: membershipStatus,
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updatedUser == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.updateUser(updatedUser);
    if (ok) {
      await _reloadUsers();
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Data user berhasil diperbarui.' : 'Gagal memperbarui data user.',
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 12),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kelola Data User')),
        body: const Center(
          child: Text('Akses ditolak. Hanya admin yang dapat membuka halaman ini.'),
        ),
      );
    }

    final filteredUsers = _filteredUsers;
    final pendingCount = _users.where((user) => user.role == 'jemaat' && user.membershipStatus == 'pending').length;
    final adminCount = _users.where((user) => user.role == 'admin').length;
    final verifiedCount = _users.where((user) => user.membershipStatus == 'verified').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data User'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _reloadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadUsers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: 160, child: _buildSummaryCard(context, 'Total User', _users.length, Icons.groups)),
                SizedBox(width: 160, child: _buildSummaryCard(context, 'Pending', pendingCount, Icons.pending_actions)),
                SizedBox(width: 160, child: _buildSummaryCard(context, 'Verified', verifiedCount, Icons.verified)),
                SizedBox(width: 160, child: _buildSummaryCard(context, 'Admin', adminCount, Icons.admin_panel_settings)),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Cari user',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Semua'),
                          selected: _selectedFilter == 'all',
                          onSelected: (_) => setState(() => _selectedFilter = 'all'),
                        ),
                        FilterChip(
                          label: const Text('Jemaat'),
                          selected: _selectedFilter == 'jemaat',
                          onSelected: (_) => setState(() => _selectedFilter = 'jemaat'),
                        ),
                        FilterChip(
                          label: const Text('Admin'),
                          selected: _selectedFilter == 'admin',
                          onSelected: (_) => setState(() => _selectedFilter = 'admin'),
                        ),
                        FilterChip(
                          label: const Text('Pending'),
                          selected: _selectedFilter == 'pending',
                          onSelected: (_) => setState(() => _selectedFilter = 'pending'),
                        ),
                        FilterChip(
                          label: const Text('Verified'),
                          selected: _selectedFilter == 'verified',
                          onSelected: (_) => setState(() => _selectedFilter = 'verified'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (filteredUsers.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Tidak ada user yang cocok dengan filter saat ini.'),
                ),
              )
            else
              ...filteredUsers.map(
                (user) {
                  final completeness = _profileCompleteness(user);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(user.email),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Chip(label: Text(user.role == 'admin' ? 'Admin' : 'Jemaat')),
                                        Chip(label: Text(user.membershipStatus)),
                                        Chip(label: Text('${(completeness * 100).toStringAsFixed(0)}% lengkap')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit data',
                                onPressed: () => _editUser(user),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Telepon: ${user.phone}'),
                          Text('NIK: ${user.identityNumber ?? '-'}'),
                          Text('Komunitas: ${user.familyGroup ?? '-'}'),
                          Text('Kartu Anggota: ${user.memberCardNumber ?? '-'}'),
                          Text('Alamat: ${user.address ?? '-'}'),
                          Text('Member Sejak: ${user.memberSince ?? '-'}'),
                          Text('Tanggal Baptis: ${user.baptismDate ?? '-'}'),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: completeness),
                          const SizedBox(height: 12),
                          if (user.role == 'jemaat' && user.membershipStatus == 'pending')
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _verify(user, false),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Tolak'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _verify(user, true),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Verifikasi'),
                                  ),
                                ),
                              ],
                            )
                          else
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _editUser(user),
                                icon: const Icon(Icons.manage_accounts),
                                label: const Text('Kelola data'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
