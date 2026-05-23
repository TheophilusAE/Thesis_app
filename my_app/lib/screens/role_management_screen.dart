import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({Key? key}) : super(key: key);

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  late AuthProvider _authProvider;
  String _searchQuery = '';
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
    });
    try {
      final users = await _authProvider.getAllUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    return _users
        .where((user) =>
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _showRoleUpdateDialog(User user) async {
    final selectedRoles = List<String>.from(user.roles);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Kelola Role: ${user.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text('Jemaat'),
                      value: selectedRoles.contains('jemaat'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (!selectedRoles.contains('jemaat')) {
                              selectedRoles.add('jemaat');
                            }
                          } else {
                            selectedRoles.remove('jemaat');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Pelayan'),
                      value: selectedRoles.contains('pelayan'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (!selectedRoles.contains('pelayan')) {
                              selectedRoles.add('pelayan');
                            }
                          } else {
                            selectedRoles.remove('pelayan');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Admin'),
                      value: selectedRoles.contains('admin'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (!selectedRoles.contains('admin')) {
                              selectedRoles.add('admin');
                            }
                          } else {
                            selectedRoles.remove('admin');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedRoles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Minimal satu role harus dipilih',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: selectedRoles.isEmpty
                      ? null
                      : () async {
                          final updatedUser = user.copyWith(roles: selectedRoles);
                          final success =
                              await _authProvider.updateUser(updatedUser);
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Role berhasil diperbarui'
                                  : 'Gagal memperbarui role'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Role Pengguna'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama atau email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final filteredUsers = _filteredUsers;
                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Belum ada pengguna'
                            : 'Tidak ada hasil pencarian',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(user.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(user.email),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: user.roles
                                    .map((role) => Chip(
                                          label: Text(
                                            _getRoleLabel(role),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor:
                                              _getRoleColor(role),
                                          padding: EdgeInsets.zero,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _showRoleUpdateDialog(user),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'pelayan':
        return 'Pelayan';
      case 'jemaat':
        return 'Jemaat';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'pelayan':
        return Colors.blue;
      case 'jemaat':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
