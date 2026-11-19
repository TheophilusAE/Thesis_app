import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../models/broadcast.dart';
import '../services/supabase_service.dart';

/// Announcements (Pengumuman), manual birthday greetings and the Super
/// Admin's manual notification clean-up.
class BroadcastProvider extends ChangeNotifier {
  BroadcastProvider({SupabaseService? service}) : _service = service ?? SupabaseService();

  final SupabaseService _service;

  List<Broadcast> _items = [];
  List<BirthdayPerson> _birthdays = [];
  bool _isLoading = false;
  String? _error;
  bool _featureMissing = false;

  List<Broadcast> get items => _items;
  List<Broadcast> get active => _items.where((b) => b.isActive).toList();
  List<BirthdayPerson> get birthdays => _birthdays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True before migration_notifications_v2.sql has run.
  bool get featureMissing => _featureMissing;

  static String messageFor(Object e) {
    if (SupabaseService.isMissingRelation(e)) {
      return 'Fitur pengumuman belum aktif. Jalankan migration_notifications_v2.sql.';
    }
    if (e is PostgrestException) {
      if (e.code == '42501' || e.code == '22023' || e.code == 'P0002') return e.message;
      return 'Gagal: ${e.message}';
    }
    return 'Terjadi kesalahan. Periksa koneksi lalu coba lagi.';
  }

  /// [activeOnly]: members see active ones; the management screen loads all.
  Future<void> load({bool activeOnly = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _service.getBroadcasts(activeOnly: activeOnly);
      _items = rows.map(Broadcast.fromJson).toList();
      _featureMissing = false;
    } catch (e) {
      _featureMissing = SupabaseService.isMissingRelation(e);
      _error = _featureMissing ? null : messageFor(e);
      _items = [];
      debugPrint('BroadcastProvider.load: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  static String? validate({required String title, required String message}) {
    if (title.trim().isEmpty) return 'Judul wajib diisi.';
    if (title.trim().length > 120) return 'Judul maksimal 120 karakter.';
    if (message.trim().isEmpty) return 'Isi pengumuman wajib diisi.';
    return null;
  }

  /// Returns (error, recipients). error is null on success.
  Future<(String?, int)> create({
    required String title,
    required String message,
    required String category,
    required String audience,
    String? route,
  }) async {
    final invalid = validate(title: title, message: message);
    if (invalid != null) return (invalid, 0);
    try {
      final r = await _service.createBroadcast({
        'title': title.trim(),
        'message': message.trim(),
        'category': category,
        'audience': audience,
        'route': ?route,
      });
      await load(activeOnly: false);
      return (null, (r['recipients'] as num?)?.toInt() ?? 0);
    } catch (e) {
      return (messageFor(e), 0);
    }
  }

  /// Super Admin only (enforced by the database).
  Future<String?> update(String id, {String? title, String? message, String? category, bool? isActive}) async {
    if (title != null || message != null) {
      final invalid = validate(title: title ?? 'x', message: message ?? 'x');
      if (invalid != null) return invalid;
    }
    try {
      await _service.updateBroadcast(id, {
        if (title != null) 'title': title.trim(),
        if (message != null) 'message': message.trim(),
        'category': ?category,
        'is_active': ?isActive,
      });
      await load(activeOnly: false);
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  Future<void> loadBirthdays() async {
    try {
      final rows = await _service.getBirthdaysToday();
      _birthdays = rows.map(BirthdayPerson.fromJson).toList();
    } catch (e) {
      _birthdays = [];
      debugPrint('BroadcastProvider.loadBirthdays: $e');
    }
    notifyListeners();
  }

  /// Returns (error, names greeted now).
  Future<(String?, List<String>)> sendBirthdayGreetings() async {
    try {
      final r = await _service.sendBirthdayGreetings();
      final names = ((r['names'] as List?) ?? const []).map((e) => e.toString()).toList();
      await loadBirthdays();
      return (null, names);
    } catch (e) {
      return (messageFor(e), const <String>[]);
    }
  }

  /// Super Admin: returns (error, deleted count).
  Future<(String?, int)> purgeOlderThan(int days) async {
    if (days < 30) return ('Batas minimal 30 hari.', 0);
    try {
      return (null, await _service.purgeOldNotifications(days));
    } catch (e) {
      return (messageFor(e), 0);
    }
  }
}
