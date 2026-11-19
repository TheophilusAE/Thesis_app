import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/playlist_service.dart';
import '../models/playlist.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/permissions.dart';

/// Worship playlist (KF-14). The app has no audio player: a song with a
/// link (`Song.audioUrl`, stored in the existing `playlists.songs` jsonb)
/// opens externally (YouTube, Spotify, etc.); otherwise lyrics or the song
/// details are shown. Nothing pretends to "play".
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

/// One editable song row in the admin "Tambah Playlist" dialog.
class _SongDraft {
  final TextEditingController title = TextEditingController();
  final TextEditingController artist = TextEditingController();
  final TextEditingController link = TextEditingController();

  void dispose() {
    title.dispose();
    artist.dispose();
    link.dispose();
  }
}

bool _isWebUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final PlaylistService _playlistService = PlaylistService();
  late Future<Playlist> _todayFuture;
  late Future<List<Playlist>> _historyFuture;

  /// A past playlist picked from "Playlist Sebelumnya"; null shows today's.
  Playlist? _selectedPlaylist;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _todayFuture = _playlistService.getTodaysPlaylist();
    _historyFuture = _playlistService.getPlaylistHistory();
  }

  Future<void> _showCreatePlaylistDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final drafts = <_SongDraft>[_SongDraft()];
    String? formError;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Tambah Playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Judul Playlist *'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < drafts.length; i++) ...[
                    Row(
                      children: [
                        Text('Lagu ${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (drafts.length > 1)
                          IconButton(
                            tooltip: 'Hapus lagu',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setDialogState(() {
                              drafts.removeAt(i).dispose();
                            }),
                          ),
                      ],
                    ),
                    TextField(
                      controller: drafts[i].title,
                      decoration: const InputDecoration(labelText: 'Judul Lagu *'),
                    ),
                    TextField(
                      controller: drafts[i].artist,
                      decoration: const InputDecoration(labelText: 'Artis / Penyanyi'),
                    ),
                    TextField(
                      controller: drafts[i].link,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Tautan (opsional)',
                        hintText: 'https://youtube.com/...',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextButton.icon(
                    onPressed: () => setDialogState(() => drafts.add(_SongDraft())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Lagu'),
                  ),
                  if (formError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(formError!,
                          style: TextStyle(color: AppTheme.errorColor, fontSize: 12.5)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                String? error;
                if (titleController.text.trim().isEmpty) {
                  error = 'Judul playlist wajib diisi.';
                } else if (drafts.any((d) => d.title.text.trim().isEmpty)) {
                  error = 'Setiap lagu harus memiliki judul.';
                } else if (drafts.any(
                    (d) => d.link.text.trim().isNotEmpty && !_isWebUrl(d.link.text))) {
                  error = 'Tautan lagu harus diawali http:// atau https://';
                }
                if (error != null) {
                  setDialogState(() => formError = error);
                  return;
                }
                Navigator.pop(dialogCtx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true) {
      for (final d in drafts) {
        d.dispose();
      }
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final songs = [
      for (var i = 0; i < drafts.length; i++)
        Song(
          id: 'song-$now-$i',
          title: drafts[i].title.text.trim(),
          artist: drafts[i].artist.text.trim(),
          audioUrl: drafts[i].link.text.trim().isEmpty ? null : drafts[i].link.text.trim(),
        ),
    ];
    for (final d in drafts) {
      d.dispose();
    }

    final ok = await _playlistService.addPlaylist(
      title: titleController.text.trim(),
      description: descController.text.trim(),
      songs: songs,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Playlist berhasil ditambahkan (${songs.length} lagu)'
            : 'Gagal menyimpan playlist. Periksa koneksi dan hak akses admin.'),
        backgroundColor: ok ? AppTheme.emerald : AppTheme.errorColor,
      ),
    );
    if (ok) {
      setState(() {
        _selectedPlaylist = null;
        _reload();
      });
    }
  }

  Future<void> _onSongTap(Song song) async {
    final link = song.audioUrl;
    if (link != null && _isWebUrl(link)) {
      final opened = await launchUrl(Uri.parse(link.trim()), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan lagu')),
        );
      }
      return;
    }
    if (!mounted) return;
    if (song.lyrics != null && song.lyrics!.isNotEmpty) {
      _showLyrics(context, song);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tautan dan lirik untuk "${song.title}" belum tersedia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = context
        .watch<AuthProvider>()
        .can(AppModule.playlist, PermissionAction.create);

    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: Text(
          'Playlist Ibadah',
          style: TextStyle(
            color: AppTheme.darkCharcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
      ),
      floatingActionButton: canCreate
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
            return Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat playlist. Tarik untuk mencoba lagi.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada playlist'));
          }

          final playlist = _selectedPlaylist ?? snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {
              _selectedPlaylist = null;
              _reload();
            }),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(playlist),
                  if (_selectedPlaylist != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _selectedPlaylist = null),
                        icon: const Icon(Icons.today_rounded, size: 18),
                        label: const Text('Kembali ke playlist hari ini'),
                      ),
                    ),
                  _buildSongList(playlist),
                  _buildHistory(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Playlist playlist) {
    return Container(
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
            child: const Icon(Icons.queue_music_rounded, size: 36, color: AppTheme.gold),
          ),
          const SizedBox(height: 16),
          Text(
            playlist.title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            playlist.description,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.5),
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
                const Icon(Icons.music_note_rounded, size: 16, color: AppTheme.gold),
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
    );
  }

  Widget _buildSongList(Playlist playlist) {
    if (playlist.songs.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Belum ada lagu dalam playlist ini',
              style: TextStyle(color: AppTheme.mutedCharcoal)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: playlist.songs.length,
      itemBuilder: (context, index) {
        final song = playlist.songs[index];
        final hasLink = song.audioUrl != null && _isWebUrl(song.audioUrl!);
        final hasLyrics = song.lyrics != null && song.lyrics!.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                '${index + 1}',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              song.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkCharcoal,
                fontSize: 14.5,
              ),
            ),
            subtitle: Text(
              song.artist.isEmpty ? (hasLink ? 'Ketuk untuk membuka tautan' : '-') : song.artist,
              style: TextStyle(fontSize: 12.5, color: AppTheme.mutedCharcoal),
            ),
            trailing: hasLyrics
                ? IconButton(
                    tooltip: 'Lihat lirik',
                    icon: Icon(Icons.lyrics_outlined, color: AppTheme.primary),
                    onPressed: () => _showLyrics(context, song),
                  )
                : hasLink
                    ? Icon(Icons.open_in_new_rounded, color: AppTheme.primary, size: 20)
                    : null,
            onTap: () => _onSongTap(song),
          ),
        );
      },
    );
  }

  Widget _buildHistory() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Playlist Sebelumnya',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkCharcoal),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Playlist>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('Belum ada playlist sebelumnya',
                    style: TextStyle(fontSize: 13, color: AppTheme.mutedCharcoal));
              }
              return Column(
                children: snapshot.data!.map((pl) {
                  final selected = _selectedPlaylist?.id == pl.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected ? AppTheme.primary : AppTheme.neutralBorder),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.playlist_play_rounded, color: AppTheme.primary),
                      ),
                      title: Text(
                        pl.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${pl.songs.length} lagu',
                        style: TextStyle(fontSize: 12, color: AppTheme.mutedCharcoal),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppTheme.mutedCharcoal),
                      onTap: () => setState(() => _selectedPlaylist = pl),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
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
                  Text(song.artist, style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        song.lyrics ?? '',
                        style: const TextStyle(fontSize: 16, height: 1.8),
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
