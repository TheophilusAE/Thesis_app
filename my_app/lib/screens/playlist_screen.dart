import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/playlist_service.dart';
import '../models/playlist.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final PlaylistService _playlistService = PlaylistService();
  late Future<Playlist> _todayFuture;

  @override
  void initState() {
    super.initState();
    _todayFuture = _playlistService.getTodaysPlaylist();
  }

  Future<void> _showCreatePlaylistDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final songTitleController = TextEditingController();
    final artistController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Playlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul Playlist'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                TextField(
                  controller: songTitleController,
                  decoration: const InputDecoration(labelText: 'Lagu Utama'),
                ),
                TextField(
                  controller: artistController,
                  decoration: const InputDecoration(labelText: 'Artis'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    await _playlistService.addPlaylist(
      title: titleController.text.trim(),
      description: descController.text.trim(),
      songs: [
        Song(
          id: 'song-${DateTime.now().millisecondsSinceEpoch}',
          title: songTitleController.text.trim(),
          artist: artistController.text.trim(),
        ),
      ],
    );

    setState(() {
      _todayFuture = _playlistService.getTodaysPlaylist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().currentDisplayRole == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text(
          'Playlist Ibadah',
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
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreatePlaylistDialog,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: FutureBuilder<Playlist>(
        future: _todayFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada playlist'));
          }

          final playlist = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.redGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.queue_music_rounded,
                          size: 36,
                          color: AppTheme.gold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        playlist.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        playlist.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.music_note_rounded,
                              size: 16,
                              color: AppTheme.gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${playlist.songs.length} lagu pujian',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Songs List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: playlist.songs.length,
                  itemBuilder: (context, index) {
                    final song = playlist.songs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.neutralBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkCharcoal,
                            fontSize: 14.5,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.mutedCharcoal),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.lyrics_outlined, color: AppTheme.primary),
                          onPressed: () {
                            if (song.lyrics != null) {
                              _showLyrics(context, song);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lirik tidak tersedia'),
                                ),
                              );
                            }
                          },
                        ),
                        onTap: () {
                          // Play song
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Memutar: ${song.title}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                // Previous Playlists
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Playlist Sebelumnya',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Playlist>>(
                        future: _playlistService.getPlaylistHistory(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: snapshot.data!.map((pl) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.neutralBorder),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.playlist_play_rounded, color: AppTheme.primary),
                                  ),
                                  title: Text(
                                    pl.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '${pl.songs.length} lagu',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.mutedCharcoal),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.mutedCharcoal),
                                  onTap: () {
                                    // Navigate to playlist
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLyrics(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.72);
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondaryTextColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        song.lyrics ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
