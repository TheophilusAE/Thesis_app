import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/komsel.dart';
import '../providers/komsel_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';
import 'add_edit_komsel_screen.dart';

class KomselManagementScreen extends StatefulWidget {
  const KomselManagementScreen({super.key});

  @override
  State<KomselManagementScreen> createState() => _KomselManagementScreenState();
}

class _KomselManagementScreenState extends State<KomselManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KomselProvider>().loadAllKomsel();
    });
  }

  void _addNew() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddEditKomselScreen()))
        .then((_) {
      if (mounted) context.read<KomselProvider>().loadAllKomsel();
    });
  }

  void _edit(Komsel komsel) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AddEditKomselScreen(komsel: komsel)))
        .then((_) {
      if (mounted) context.read<KomselProvider>().loadAllKomsel();
    });
  }

  void _delete(Komsel komsel) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Komsel?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "${komsel.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.mutedCharcoal)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context.read<KomselProvider>().deleteKomsel(komsel.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Komsel berhasil dihapus')),
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

  List<Komsel> _filterKomsel(List<Komsel> all) {
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
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Kelola Komsel',
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
      body: Consumer<KomselProvider>(
        builder: (context, provider, _) {
          final filteredList = _filterKomsel(provider.allKomsel);

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
                        hintText: 'Cari komsel, wilayah, pemimpin...',
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
                          _buildFilterChip('all', 'Semua (${provider.allKomsel.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'active',
                            'Aktif (${provider.allKomsel.where((k) => k.isActive).length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'inactive',
                            'Nonaktif (${provider.allKomsel.where((k) => !k.isActive).length})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.neutralBorder),

              // Komsel List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : filteredList.isEmpty
                        ? AppEmptyState(
                            icon: Icons.groups_outlined,
                            title: 'Tidak Ada Data Komsel',
                            message: _searchQuery.isNotEmpty
                                ? 'Tidak ditemukan komsel dengan kata kunci "$_searchQuery".'
                                : 'Belum ada data kelompok sel yang terdaftar.',
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadAllKomsel,
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final komsel = filteredList[index];
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
                                                  komsel.nama,
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
                                                      komsel.wilayah,
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
                                            status: komsel.isActive ? 'aktif' : 'nonaktif',
                                            label: komsel.isActive ? 'Aktif' : 'Nonaktif',
                                            type: komsel.isActive ? BadgeType.success : BadgeType.neutral,
                                            isSmall: true,
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _edit(komsel),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorColor),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _delete(komsel),
                                          ),
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
                                              '${komsel.leaderName}${komsel.leaderPhone.isNotEmpty ? " • ${komsel.leaderPhone}" : ""}',
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
                                              komsel.meetingSchedule,
                                              style: const TextStyle(fontSize: 13, color: AppTheme.mutedCharcoal),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (komsel.location.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.home_outlined, size: 15, color: AppTheme.mutedCharcoal),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                komsel.location,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNew,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Komsel', style: TextStyle(fontWeight: FontWeight.bold)),
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

