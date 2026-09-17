import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/devotional.dart';

/// Devotionals are admin-authored content meant to be shared with every
/// jemaat. They live in the `devotionals` Supabase table; a local cache is
/// kept only so the last-fetched devotionals remain readable offline.
class DevotionalService {
  static final SupabaseClient _db = Supabase.instance.client;
  static const _cacheKey = 'devotionals_cache';

  Future<Devotional> getTodaysDevotional() async {
    final all = await getAllDevotionals();
    return all.first;
  }

  Future<List<Devotional>> getDevotionalHistory() async {
    final all = await getAllDevotionals();
    return all.skip(1).toList();
  }

  Future<List<Devotional>> getAllDevotionals() async {
    try {
      final data = await _db
          .from('devotionals')
          .select()
          .order('devotional_date', ascending: false);
      final devotionals =
          (data as List).map((e) => _fromRow(e as Map<String, dynamic>)).toList();
      if (devotionals.isNotEmpty) {
        await _cache(devotionals);
        return devotionals;
      }
    } catch (e) {
      debugPrint('getAllDevotionals (Supabase) error: $e');
    }
    return _loadCacheOrDefaults();
  }

  Future<bool> addDevotional({
    required String title,
    required String content,
    required String verse,
    required String verseReference,
    required DateTime date,
    required String author,
  }) async {
    try {
      await _db.from('devotionals').insert({
        'id': 'dev-${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'content': content,
        'verse': verse,
        'verse_reference': verseReference,
        'devotional_date': date.toIso8601String(),
        'author': author,
      });
      return true;
    } catch (e) {
      debugPrint('addDevotional error: $e');
      return false;
    }
  }

  Future<bool> updateDevotional(Devotional updatedDevotional) async {
    try {
      await _db.from('devotionals').update({
        'title': updatedDevotional.title,
        'content': updatedDevotional.content,
        'verse': updatedDevotional.verse,
        'verse_reference': updatedDevotional.verseReference,
        'devotional_date': updatedDevotional.date.toIso8601String(),
        'author': updatedDevotional.author,
      }).eq('id', updatedDevotional.id);
      return true;
    } catch (e) {
      debugPrint('updateDevotional error: $e');
      return false;
    }
  }

  Future<bool> deleteDevotional(String devotionalId) async {
    try {
      await _db.from('devotionals').delete().eq('id', devotionalId);
      return true;
    } catch (e) {
      debugPrint('deleteDevotional error: $e');
      return false;
    }
  }

  Devotional _fromRow(Map<String, dynamic> row) => Devotional(
        id: row['id'] as String,
        title: row['title'] as String,
        content: row['content'] as String,
        verse: row['verse'] as String,
        verseReference: row['verse_reference'] as String,
        date: DateTime.parse(row['devotional_date'] as String),
        author: row['author'] as String?,
      );

  Future<void> _cache(List<Devotional> devotionals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(devotionals.map((d) => d.toJson()).toList()),
    );
  }

  Future<List<Devotional>> _loadCacheOrDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return _defaultDevotionals();
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Devotional.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<Devotional> _defaultDevotionals() {
    final now = DateTime.now();
    return [
      Devotional(
        id: '1',
        title: 'Kasih yang Sempurna',
        content: '''Kasih Allah kepada kita begitu sempurna dan tidak terbatas.

Dalam 1 Yohanes 4:18, Alkitab mengatakan "Di dalam kasih tidak ada ketakutan: kasih yang sempurna melenyapkan ketakutan; sebab ketakutan mengandung hukuman dan barangsiapa takut, ia tidak sempurna di dalam kasih."

Ketika kita mengalami kasih Allah yang sempurna, segala ketakutan dan kekhawatiran akan lenyap. Kita dapat hidup dengan penuh damai sejahtera karena kita tahu bahwa Allah mengasihi kita tanpa syarat.

Mari kita belajar untuk menerima dan membagikan kasih Allah kepada sesama kita hari ini.''',
        verse:
            'Di dalam kasih tidak ada ketakutan: kasih yang sempurna melenyapkan ketakutan; sebab ketakutan mengandung hukuman dan barangsiapa takut, ia tidak sempurna di dalam kasih.',
        verseReference: '1 Yohanes 4:18',
        date: now,
        author: 'Tim Renungan',
      ),
      Devotional(
        id: '2',
        title: 'Bersukacitalah Senantiasa',
        content: 'Bersukacitalah dalam Tuhan adalah perintah yang penuh makna...',
        verse:
            'Bersukacitalah senantiasa dalam Tuhan! Sekali lagi kukatakan: Bersukacitalah!',
        verseReference: 'Filipi 4:4',
        date: now.subtract(const Duration(days: 1)),
        author: 'Tim Renungan',
      ),
      Devotional(
        id: '3',
        title: 'Kekuatan dalam Kelemahan',
        content: 'Ketika kita lemah, saat itulah Allah kuat dalam hidup kita...',
        verse: 'Sebab jika aku lemah, maka aku kuat.',
        verseReference: '2 Korintus 12:10',
        date: now.subtract(const Duration(days: 2)),
        author: 'Tim Renungan',
      ),
    ];
  }
}
