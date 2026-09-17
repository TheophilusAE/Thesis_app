import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pelayan.dart';
import '../providers/pelayan_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';
import 'add_edit_pelayan_screen.dart';

class PelayaniManagementScreen extends StatefulWidget {
  const PelayaniManagementScreen({super.key});

  @override
  State<PelayaniManagementScreen> createState() => _PelayaniManagementScreenState();
}

class _PelayaniManagementScreenState extends State<PelayaniManagementScreen> {
  late final TextEditingController _searchController;
  String _selectedFilter = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PelayaniProvider>().loadAllPelayan();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Manajemen Pelayan',
          style: TextStyle(
            color: AppTheme.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau posisi pelayan...',
                    hintStyle: TextStyle(
                      color: AppTheme.neutralMuted.withValues(alpha: 0.8),
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              context.read<PelayaniProvider>().searchPelayan('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.warmIvory,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.neutralBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.neutralBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    context.read<PelayaniProvider>().searchPelayan(value);
                  },
                ),
                const SizedBox(height: 10),
                // Filter chips
                Row(
                  children: [
                    _filterChip('all', 'Semua'),
                    const SizedBox(width: 8),
                    _filterChip('active', 'Aktif'),
                  ],
                ),
              ],
            ),
          ),
          // Pelayan list
          Expanded(
            child: Consumer<PelayaniProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (provider.filteredPelayan.isEmpty) {
                  return Center(
                    child: AppEmptyState(
                      icon: Icons.person_off_rounded,
                      title: 'Tidak Ada Data Pelayan',
                      description: 'Belum ada data pelayan yang sesuai dengan pencarian atau filter.',
                      actionLabel: 'Tambah Pelayan',
                      onAction: _addNewPelayan,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.filteredPelayan.length,
                  itemBuilder: (context, index) {
                    final pelayan = provider.filteredPelayan[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PelayaniCard(
                        pelayan: pelayan,
                        onEdit: () => _editPelayan(pelayan),
                        onDelete: () => _deletePelayan(pelayan),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPelayan,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Pelayan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        if (value == 'all') {
          context.read<PelayaniProvider>().loadAllPelayan();
        } else {
          context.read<PelayaniProvider>().loadActivePelayan();
        }
      },
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.primary : AppTheme.darkCharcoal,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryLight,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _addNewPelayan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditPelayaniScreen(),
      ),
    ).then((_) {
      if (mounted) context.read<PelayaniProvider>().loadAllPelayan();
    });
  }

  void _editPelayan(Pelayan pelayan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditPelayaniScreen(pelayan: pelayan),
      ),
    ).then((_) {
      if (mounted) context.read<PelayaniProvider>().loadAllPelayan();
    });
  }

  void _deletePelayan(Pelayan pelayan) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pelayan?'),
        content: Text('Apakah Anda yakin ingin menghapus ${pelayan.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context.read<PelayaniProvider>().deletePelayan(pelayan.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pelayan berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _PelayaniCard extends StatelessWidget {
  final Pelayan pelayan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PelayaniCard({
    required this.pelayan,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pelayan.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warmIvory,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.neutralBorder),
                          ),
                          child: Text(
                            pelayan.posisi,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.darkCharcoal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        AppStatusBadge(
                          label: pelayan.isAktif ? 'Aktif' : 'Nonaktif',
                          type: pelayan.isAktif
                              ? AppStatusBadgeType.success
                              : AppStatusBadgeType.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.error),
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          if (pelayan.noTelepon.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.neutralBorder),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone_rounded, size: 14, color: AppTheme.neutralMuted),
                const SizedBox(width: 6),
                Text(
                  pelayan.noTelepon,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.neutralMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
