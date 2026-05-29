import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pelayan.dart';
import '../providers/pelayan_provider.dart';
import 'add_edit_pelayan_screen.dart';

class PelayaniManagementScreen extends StatefulWidget {
  const PelayaniManagementScreen({super.key});

  @override
  State<PelayaniManagementScreen> createState() => _PelayaniManagementScreenState();
}

class _PelayaniManagementScreenState extends State<PelayaniManagementScreen> {
  late TextEditingController _searchController;
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
      appBar: AppBar(
        title: const Text('Manajemen Pelayan'),
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
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari Pelayan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<PelayaniProvider>().searchPelayan('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    context.read<PelayaniProvider>().searchPelayan(value);
                  },
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Semua'),
                              selected: _selectedFilter == 'all',
                              onSelected: (selected) {
                                setState(() => _selectedFilter = 'all');
                                context.read<PelayaniProvider>().loadAllPelayan();
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Aktif'),
                              selected: _selectedFilter == 'active',
                              onSelected: (selected) {
                                setState(() => _selectedFilter = 'active');
                                context.read<PelayaniProvider>().loadActivePelayan();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.filteredPelayan.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data Pelayan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: provider.filteredPelayan.length,
                  itemBuilder: (context, index) {
                    final pelayan = provider.filteredPelayan[index];
                    return _PelayaniCard(
                      pelayan: pelayan,
                      onEdit: () => _editPelayan(pelayan),
                      onDelete: () => _deletePelayan(pelayan),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewPelayan(),
        tooltip: 'Tambah Pelayan',
        child: const Icon(Icons.add),
      ),
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
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pelayan.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pelayan.posisi,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pelayan.isAktif
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pelayan.isAktif ? 'Aktif' : 'Nonaktif',
                              style: TextStyle(
                                fontSize: 12,
                                color: pelayan.isAktif ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Hapus',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  pelayan.noTelepon,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
