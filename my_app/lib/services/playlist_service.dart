import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/playlist.dart';

/// "Today's playlist" is admin-published worship content meant to be seen
/// by every jemaat. It lives in the `playlists` Supabase table; a local
/// cache is kept only so the last-fetched playlist stays readable offline.
class PlaylistService {
  static final SupabaseClient _db = Supabase.instance.client;
  static const _cacheKey = 'playlists_cache';

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

  Future<bool> addPlaylist({
    required String title,
    required String description,
    required List<Song> songs,
  }) async {
    try {
      await _db.from('playlists').insert({
        'id': 'pl-${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'description': description,
        'songs': songs.map((s) => s.toJson()).toList(),
        'playlist_date': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('addPlaylist error: $e');
      return false;
    }
  }

  Future<List<Playlist>> _loadAll() async {
    try {
      final data = await _db.from('playlists').select().order('playlist_date', ascending: false);
      final playlists = (data as List).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
      if (playlists.isNotEmpty) {
        await _cache(playlists);
        return playlists;
      }
    } catch (e) {
      debugPrint('_loadAll playlists (Supabase) error: $e');
    }
    return _loadCacheOrDefaults();
  }

  Playlist _fromRow(Map<String, dynamic> row) => Playlist(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String,
        songs: ((row['songs'] as List?) ?? [])
            .map((s) => Song.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        date: DateTime.parse(row['playlist_date'] as String),
        coverImage: row['cover_image'] as String?,
      );

  Future<void> _cache(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(playlists.map((p) => p.toJson()).toList()));
  }

  Future<List<Playlist>> _loadCacheOrDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return _defaultPlaylists();
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Playlist.fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
