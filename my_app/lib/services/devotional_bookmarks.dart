import 'package:shared_preferences/shared_preferences.dart';

/// Saved ("Simpan") devotionals (KF-13). There is no bookmarks table in the
/// database (and the schema must not change), so bookmarks are stored on
/// this device, scoped per account. The UI says so explicitly.
class DevotionalBookmarks {
  static String keyFor(String userId) => 'saved_devotionals_$userId';

  Future<Set<String>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(keyFor(userId)) ?? const <String>[]).toSet();
  }

  /// Toggles [devotionalId] and returns the new saved state. Throws if the
  /// write fails, so the caller never shows "saved" for a failed save.
  Future<bool> toggle(String userId, String devotionalId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getStringList(keyFor(userId)) ?? const <String>[]).toSet();
    final nowSaved = !saved.remove(devotionalId);
    if (nowSaved) saved.add(devotionalId);
    final ok = await prefs.setStringList(keyFor(userId), saved.toList());
    if (!ok) throw StateError('Failed to persist devotional bookmark');
    return nowSaved;
  }
}
