import 'package:flutter/material.dart';
import '../services/playlist_service.dart';
import '../models/playlist.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final PlaylistService _playlistService = PlaylistService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist Hari Ini'),
      ),
      body: FutureBuilder<Playlist>(
        future: _playlistService.getTodaysPlaylist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.music_note,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        playlist.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        playlist.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.queue_music,
                            size: 20,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${playlist.songs.length} lagu',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(song.artist),
                        trailing: IconButton(
                          icon: const Icon(Icons.lyrics),
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
                      Text(
                        'Playlist Sebelumnya',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.playlist_play),
                                  title: Text(pl.title),
                                  subtitle: Text('${pl.songs.length} lagu'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
      builder: (context) => DraggableScrollableSheet(
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
                      color: Colors.grey[300],
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
                    color: Colors.grey[600],
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
      ),
    );
  }
}
