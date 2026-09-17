import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sermon.dart';
import '../providers/sermon_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_status_badge.dart';
import 'add_edit_sermon_screen.dart';

class SermonManagementScreen extends StatefulWidget {
  const SermonManagementScreen({super.key});

  @override
  State<SermonManagementScreen> createState() => _SermonManagementScreenState();
}

class _SermonManagementScreenState extends State<SermonManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SermonProvider>().loadAllSermons();
    });
  }

  void _addNew() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddEditSermonScreen()))
        .then((_) {
      if (mounted) context.read<SermonProvider>().loadAllSermons();
    });
  }

  void _edit(Sermon sermon) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AddEditSermonScreen(sermon: sermon)))
        .then((_) {
      if (mounted) context.read<SermonProvider>().loadAllSermons();
    });
  }

  void _delete(Sermon sermon) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Khotbah?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "${sermon.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.mutedCharcoal)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context.read<SermonProvider>().deleteSermon(sermon.id);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Khotbah berhasil dihapus')),
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

  List<Sermon> _filterSermons(List<Sermon> all) {
    return all.where((s) {
      if (_filterStatus == 'active' && !s.isActive) return false;
      if (_filterStatus == 'inactive' && s.isActive) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = s.title.toLowerCase().contains(q);
        final matchSpeaker = s.speaker.toLowerCase().contains(q);
        return matchTitle || matchSpeaker;
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
          'Kelola Khotbah',
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
      body: Consumer<SermonProvider>(
        builder: (context, provider, _) {
          final filteredList = _filterSermons(provider.allSermons);

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
                        hintText: 'Cari judul khotbah, pembicara...',
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
                          _buildFilterChip('all', 'Semua (${provider.allSermons.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'active',
                            'Aktif (${provider.allSermons.where((s) => s.isActive).length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'inactive',
                            'Nonaktif (${provider.allSermons.where((s) => !s.isActive).length})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.neutralBorder),

              // Sermons List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : filteredList.isEmpty
                        ? AppEmptyState(
                            icon: Icons.video_library_outlined,
                            title: 'Tidak Ada Data Khotbah',
                            message: _searchQuery.isNotEmpty
                                ? 'Tidak ditemukan khotbah dengan kata kunci "$_searchQuery".'
                                : 'Belum ada rekaman khotbah yang diunggah.',
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadAllSermons,
                            color: AppTheme.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final sermon = filteredList[index];
                                return AppCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Media Type Chip + Date + Status + Actions
                                      Row(
                                        children: [
                                          _mediaTypeBadge(sermon.mediaType),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('dd MMM yyyy', 'id_ID').format(sermon.sermonDate),
                                            style: const TextStyle(fontSize: 12, color: AppTheme.mutedCharcoal),
                                          ),
                                          const Spacer(),
                                          AppStatusBadge(
                                            status: sermon.isActive ? 'aktif' : 'nonaktif',
                                            label: sermon.isActive ? 'Aktif' : 'Nonaktif',
                                            type: sermon.isActive ? BadgeType.success : BadgeType.neutral,
                                            isSmall: true,
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _edit(sermon),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorColor),
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => _delete(sermon),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Title
                                      Text(
                                        sermon.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.5,
                                          color: AppTheme.darkCharcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Speaker
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 15, color: AppTheme.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            sermon.speaker,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primary.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (sermon.description.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          sermon.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedCharcoal),
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
        label: const Text('Tambah Khotbah', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _mediaTypeBadge(String mediaType) {
    IconData icon;
    Color color;
    String label;

    switch (mediaType.toLowerCase()) {
      case 'youtube':
        icon = Icons.play_circle_fill_rounded;
        color = Colors.red.shade700;
        label = 'YouTube';
        break;
      case 'audio':
        icon = Icons.headphones_rounded;
        color = const Color(0xFF1E3A8A);
        label = 'Audio';
        break;
      case 'livestream':
        icon = Icons.live_tv_rounded;
        color = Colors.purple.shade700;
        label = 'Live';
        break;
      default:
        icon = Icons.perm_media_rounded;
        color = AppTheme.mutedCharcoal;
        label = mediaType;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
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

