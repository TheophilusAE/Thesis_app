import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/church_group.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../utils/app_theme.dart';
import '../utils/permissions.dart';
import '../widgets/permission_guard.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';
import 'add_edit_group_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadAllGroups();
    });
  }

  void _addNew() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddEditGroupScreen()))
        .then((_) {
      if (mounted) context.read<GroupProvider>().loadAllGroups();
    });
  }

  void _edit(ChurchGroup churchGroup) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AddEditGroupScreen(churchGroup: churchGroup)))
        .then((_) {
      if (mounted) context.read<GroupProvider>().loadAllGroups();
    });
  }

  void _delete(ChurchGroup churchGroup) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Group?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "${churchGroup.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.mutedCharcoal)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context.read<GroupProvider>().deleteGroup(churchGroup.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group berhasil dihapus')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  List<ChurchGroup> _filterGroups(List<ChurchGroup> all) {
    return all.where((k) {
      if (_filterStatus == 'active' && !k.isActive) return false;
      if (_filterStatus == 'inactive' && k.isActive) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNama = k.nama.toLowerCase().contains(q);
        final matchWilayah = k.wilayah.toLowerCase().contains(q);
        final matchLeader = k.leaderName.toLowerCase().contains(q);
        return matchNama || matchWilayah || matchLeader;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.can(AppModule.group, PermissionAction.create);
    final canModify = auth.canModifyExisting;
    return PermissionGuard(
      module: AppModule.group,
      title: 'Kelola Group',
      child: Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Kelola Group',
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
      body: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          final filteredList = _filterGroups(provider.allGroups);

          return Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari group, wilayah, pemimpin...',
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
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'Semua (${provider.allGroups.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'active',
                            'Aktif (${provider.allGroups.where((k) => k.isActive).length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'inactive',
                            'Nonaktif (${provider.allGroups.where((k) => !k.isActive).length})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.neutralBorder),

              // ChurchGroup List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : filteredList.isEmpty
                        ? AppEmptyState(
                            icon: Icons.groups_outlined,
                            title: 'Tidak Ada Data Group',
                            message: _searchQuery.isNotEmpty
                                ? 'Tidak ditemukan group dengan kata kunci "$_searchQuery".'
                                : 'Belum ada data group yang terdaftar.',
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadAllGroups,
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final churchGroup = filteredList[index];
                                return AppCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Title + Status Badge + Actions
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  churchGroup.nama,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppTheme.darkCharcoal,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on_outlined,
                                                      size: 14,
                                                      color: AppTheme.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      churchGroup.wilayah,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: AppTheme.primary.withValues(alpha: 0.9),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          AppStatusBadge(
                                            status: churchGroup.isActive ? 'aktif' : 'nonaktif',
                                            label: churchGroup.isActive ? 'Aktif' : 'Nonaktif',
                                            type: churchGroup.isActive ? BadgeType.success : BadgeType.neutral,
                                            isSmall: true,
                                          ),
                                          if (canModify) ...[
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                                              visualDensity: VisualDensity.compact,
                                              onPressed: () => _edit(churchGroup),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorColor),
                                              visualDensity: VisualDensity.compact,
                                              onPressed: () => _delete(churchGroup),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: AppTheme.neutralBorder),
                                      const SizedBox(height: 10),

                                      // Leader & Schedule Details
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 15, color: AppTheme.mutedCharcoal),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${churchGroup.leaderName}${churchGroup.leaderPhone.isNotEmpty ? " • ${churchGroup.leaderPhone}" : ""}',
                                              style: const TextStyle(fontSize: 13, color: AppTheme.darkCharcoal),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded, size: 15, color: AppTheme.mutedCharcoal),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              churchGroup.meetingSchedule,
                                              style: const TextStyle(fontSize: 13, color: AppTheme.mutedCharcoal),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (churchGroup.location.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.home_outlined, size: 15, color: AppTheme.mutedCharcoal),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                churchGroup.location,
                                                style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedCharcoal),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: !canCreate ? null : FloatingActionButton.extended(
        onPressed: _addNew,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Group', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
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
      onSelected: (_) => setState(() => _filterStatus = key),
    );
  }
}

