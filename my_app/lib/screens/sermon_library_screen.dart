import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sermon.dart';
import '../providers/sermon_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_skeleton.dart';

class SermonLibraryScreen extends StatefulWidget {
  const SermonLibraryScreen({super.key});

  @override
  State<SermonLibraryScreen> createState() => _SermonLibraryScreenState();
}

class _SermonLibraryScreenState extends State<SermonLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SermonProvider>().loadActiveSermons();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _open(Sermon sermon) async {
    final uri = Uri.tryParse(sermon.mediaUrl);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan khotbah')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Khotbah & Media Rohani'),
      ),
      body: Consumer<SermonProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingSkeleton();
          }

          var items = provider.activeSermons;

          if (_selectedType != 'all') {
            items = items.where((s) => s.mediaType.toLowerCase() == _selectedType).toList();
          }

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            items = items.where((s) {
              return s.title.toLowerCase().contains(query) ||
                  s.speaker.toLowerCase().contains(query) ||
                  s.description.toLowerCase().contains(query);
            }).toList();
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: provider.loadActiveSermons,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // Search bar
                _buildSearchBar(),

                const SizedBox(height: 12),

                // Media type filter chips
                _buildFilterChips(),

                const SizedBox(height: 16),

                if (items.isEmpty)
                  AppEmptyState(
                    icon: Icons.video_library_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'Khotbah Tidak Ditemukan'
                        : 'Belum ada khotbah yang tersedia',
                    description: _searchQuery.isNotEmpty
                        ? 'Tidak ada rekaman khotbah yang sesuai dengan "$_searchQuery".'
                        : 'Belum ada rekaman khotbah yang tersedia saat ini.',
                  )
                else
                  ...items.map((sermon) => _buildSermonCard(sermon)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari judul khotbah atau pembicara...',
          hintStyle: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neutralMedium, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Semua Media'},
      {'key': 'youtube', 'label': 'YouTube'},
      {'key': 'audio', 'label': 'Audio Podcast'},
      {'key': 'livestream', 'label': 'Live Stream'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedType == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              selectedColor: AppTheme.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.darkCharcoal,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = f['key']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSermonCard(Sermon sermon) {
    final thumbnail = sermon.resolvedThumbnailUrl;
    final formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(sermon.sermonDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => _open(sermon),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Area with Play Button Overlay
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _buildMediaFallback(),
                        )
                      : _buildMediaFallback(),

                  // Soft gradient scrim
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Center Play Button Icon
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  // Media Type Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMediaIcon(sermon.mediaType),
                            size: 14,
                            color: AppTheme.goldLight,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _getMediaLabel(sermon.mediaType),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sermon Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sermon.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (sermon.speaker.isNotEmpty) ...[
                        const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sermon.speaker,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.neutralMedium),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutralMedium,
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutralMedium,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaFallback() {
    return Container(
      color: AppTheme.burgundyDark,
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          size: 56,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  IconData _getMediaIcon(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return Icons.headphones_rounded;
      case 'livestream':
        return Icons.sensors_rounded;
      default:
        return Icons.play_circle_fill_rounded;
    }
  }

  String _getMediaLabel(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return 'Audio';
      case 'livestream':
        return 'Live';
      default:
        return 'YouTube';
    }
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          AppSkeleton(height: 46, borderRadius: BorderRadius.all(Radius.circular(12))),
          SizedBox(height: 12),
          AppSkeleton(height: 36, borderRadius: BorderRadius.all(Radius.circular(10))),
          SizedBox(height: 16),
          AppSkeleton(height: 240, borderRadius: BorderRadius.all(Radius.circular(16))),
          SizedBox(height: 16),
          AppSkeleton(height: 240, borderRadius: BorderRadius.all(Radius.circular(16))),
        ],
      ),
    );
  }
}
