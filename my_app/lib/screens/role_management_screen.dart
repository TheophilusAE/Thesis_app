import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  late AuthProvider _authProvider;
  String _searchQuery = '';
  String _roleFilter = 'all'; // all, admin, pelayan, jemaat
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
      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<User> get _filteredUsers {
    return _users.where((user) {
      if (_roleFilter != 'all' && !user.roles.contains(_roleFilter)) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return user.name.toLowerCase().contains(q) || user.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showRoleUpdateDialog(User user) async {
    final selectedRoles = List<String>.from(user.roles);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kelola Role: ${user.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _roleCheckboxTile(
                      title: 'Jemaat',
                      subtitle: 'Akses umum ke renungan, doa, dan materi ibadah',
                      value: selectedRoles.contains('jemaat'),
                      color: AppTheme.successColor,
                      icon: Icons.person_rounded,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            if (!selectedRoles.contains('jemaat')) selectedRoles.add('jemaat');
                          } else {
                            selectedRoles.remove('jemaat');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _roleCheckboxTile(
                      title: 'Pelayan',
                      subtitle: 'Akses jadwal pelayanan, absensi, dan substitusi',
                      value: selectedRoles.contains('pelayan'),
                      color: const Color(0xFF1E3A8A),
                      icon: Icons.church_rounded,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            if (!selectedRoles.contains('pelayan')) selectedRoles.add('pelayan');
                          } else {
                            selectedRoles.remove('pelayan');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _roleCheckboxTile(
                      title: 'Admin',
                      subtitle: 'Akses penuh manajemen data jemaat, jadwal, & sistem',
                      value: selectedRoles.contains('admin'),
                      color: AppTheme.primary,
                      icon: Icons.shield_rounded,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            if (!selectedRoles.contains('admin')) selectedRoles.add('admin');
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
                          style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.mutedCharcoal)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: selectedRoles.isEmpty
                      ? null
                      : () async {
                          final updatedUser = user.copyWith(roles: selectedRoles);
                          final success = await _authProvider.updateUser(updatedUser);
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Role berhasil diperbarui'
                                  : 'Gagal memperbarui role'),
                              backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                            ),
                          );
                          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          _loadUsers();
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

  Widget _roleCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required IconData icon,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.3) : AppTheme.neutralBorder,
        ),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.mutedCharcoal)),
        value: value,
        activeColor: color,
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.warmIvory,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Kelola Role Pengguna',
          style: TextStyle(
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
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        color: AppTheme.primary,
        child: Column(
          children: [
            // Search & Filter Container
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan nama atau email...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.mutedCharcoal),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: AppTheme.warmIvory,
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
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Semua (${_users.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('admin', 'Admin (${_users.where((u) => u.roles.contains("admin")).length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('pelayan', 'Pelayan (${_users.where((u) => u.roles.contains("pelayan")).length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('jemaat', 'Jemaat (${_users.where((u) => u.roles.contains("jemaat")).length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.neutralBorder),

            // Users List
            Expanded(
              child: Builder(
                builder: (context) {
                  final filteredUsers = _filteredUsers;
                  if (filteredUsers.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Tidak Ada Pengguna',
                      message: _searchQuery.isEmpty
                          ? 'Belum ada pengguna terdaftar untuk role ini.'
                          : 'Tidak ditemukan pengguna dengan kata kunci "$_searchQuery".',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: AppTheme.darkCharcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.mutedCharcoal),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: user.roles.map((role) => _buildRoleBadge(role)).toList(),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                              tooltip: 'Ubah Role',
                              onPressed: () => _showRoleUpdateDialog(user),
                            ),
                          ],
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

  Widget _buildRoleBadge(String role) {
    Color color;
    IconData icon;
    String label;

    switch (role) {
      case 'admin':
        color = AppTheme.primary;
        icon = Icons.shield_rounded;
        label = 'Admin';
        break;
      case 'pelayan':
        color = const Color(0xFF1E3A8A);
        icon = Icons.church_rounded;
        label = 'Pelayan';
        break;
      default:
        color = AppTheme.successColor;
        icon = Icons.person_rounded;
        label = 'Jemaat';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _roleFilter == key;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.darkCharcoal,
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
        ),
      ),
      onSelected: (_) => setState(() => _roleFilter = key),
    );
  }
}

