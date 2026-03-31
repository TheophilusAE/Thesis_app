import '../models/playlist.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistService {
  static const _playlistsKey = 'playlists_data';

  Future<List<Playlist>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playlistsKey);
    if (raw == null || raw.isEmpty) {
      return _defaultPlaylists();
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Playlist.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _saveAll(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _playlistsKey,
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
  }

  Future<Playlist> getTodaysPlaylist() async {
    final all = await _loadAll();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.first;
  }

  Future<List<Playlist>> getPlaylistHistory() async {
    final all = await _loadAll();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.skip(1).toList();
  }

  Future<void> addPlaylist({
    required String title,
    required String description,
    required List<Song> songs,
  }) async {
    final all = await _loadAll();
    all.add(
      Playlist(
        id: 'pl-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        date: DateTime.now(),
        songs: songs,
      ),
    );
    await _saveAll(all);
  }

  List<Playlist> _defaultPlaylists() {
    final now = DateTime.now();
    return [
      Playlist(
        id: '1',
        title: 'Playlist Hari Ini',
        description: 'Lagu-lagu pujian dan penyembahan untuk hari ini',
        date: now,
        songs: [
          Song(
            id: '1',
            title: 'Yesus Kaulah Segalanya',
            artist: 'Tim Pujian',
            lyrics: '''Yesus Kaulah segalanya
Dalam hidupku
Segala yang kutaruhkan
Hanya bagi-Mu

Reff:
Tak akan pernah ada
Yang dapat gantikan Dikau
Yesus Tuhan dan Rajaku''',
          ),
          Song(
            id: '2',
            title: 'Tuhan adalah Gembalaku',
            artist: 'Mazmur 23',
            lyrics: '''Tuhan adalah Gembalaku
Takkan kekurangan aku
Ia membaringkan aku
Di padang rumput hijau

Ia membimbingku ke air yang tenang
Ia menyegarkan jiwaku''',
          ),
          Song(
            id: '3',
            title: 'Kasih-Mu Yesus',
            artist: 'Tim Worship',
            lyrics: '''Kasih-Mu Yesus
Tak terbatas
Kasih-Mu Yesus
Sempurna adanya

Selalu mengampuni
Selalu memulihkan
Kasih-Mu Yesus
Terindah''',
          ),
        ],
      ),
      Playlist(
        id: '2',
        title: 'Playlist Kemarin',
        description: 'Koleksi lagu pujian minggu lalu',
        date: now.subtract(const Duration(days: 1)),
        songs: [
          Song(
            id: '4',
            title: 'Bapa yang Kekal',
            artist: 'Hymn',
          ),
        ],
      ),
    ];
  }
}
