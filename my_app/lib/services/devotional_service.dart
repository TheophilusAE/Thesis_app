import '../models/devotional.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DevotionalService {
  static const _devotionalsKey = 'devotionals_data';

  Future<List<Devotional>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_devotionalsKey);
    if (raw == null || raw.isEmpty) {
      return _defaultDevotionals();
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Devotional.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<Devotional> _sortDevotionals(List<Devotional> devotionals) {
    final sorted = List<Devotional>.from(devotionals);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  Future<void> _saveAll(List<Devotional> devotionals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _devotionalsKey,
      jsonEncode(devotionals.map((d) => d.toJson()).toList()),
    );
  }

  Future<Devotional> getTodaysDevotional() async {
    final all = await getAllDevotionals();
    return all.first;
  }

  Future<List<Devotional>> getDevotionalHistory() async {
    final all = await getAllDevotionals();
    return all.skip(1).toList();
  }

  Future<List<Devotional>> getAllDevotionals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_devotionalsKey);

    if (raw == null || raw.isEmpty) {
      return _defaultDevotionals();
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final devotionals = decoded
        .map((item) => Devotional.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return _sortDevotionals(devotionals);
  }

  Future<void> addDevotional({
    required String title,
    required String content,
    required String verse,
    required String verseReference,
    required DateTime date,
    required String author,
  }) async {
    final all = await _loadAll();
    all.add(
      Devotional(
        id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        verse: verse,
        verseReference: verseReference,
        date: date,
        author: author,
      ),
    );
    await _saveAll(_sortDevotionals(all));
  }

  Future<bool> updateDevotional(Devotional updatedDevotional) async {
    final all = await _loadAll();
    final index = all.indexWhere((devotional) => devotional.id == updatedDevotional.id);
    if (index == -1) {
      return false;
    }

    all[index] = updatedDevotional;
    await _saveAll(_sortDevotionals(all));
    return true;
  }

  Future<bool> deleteDevotional(String devotionalId) async {
    final all = await _loadAll();
    final before = all.length;
    all.removeWhere((devotional) => devotional.id == devotionalId);
    final removed = all.length < before;
    if (!removed) {
      return false;
    }

    await _saveAll(_sortDevotionals(all));
    return true;
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
