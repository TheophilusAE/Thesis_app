import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_confirmation.dart';

class AttendanceConfirmationService {
  static const String _storageKey = 'attendance_confirmations';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all attendance confirmations
  Future<List<AttendanceConfirmation>> getAllAttendanceConfirmations() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AttendanceConfirmation.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  /// Get attendance confirmations for specific user
  Future<List<AttendanceConfirmation>> getAttendanceByUserId(
    String userId,
  ) async {
    final all = await getAllAttendanceConfirmations();
    return all.where((ac) => ac.userId == userId).toList();
  }

  /// Get pending confirmations (not yet confirmed)
  Future<List<AttendanceConfirmation>> getPendingConfirmations() async {
    final all = await getAllAttendanceConfirmations();
    final now = DateTime.now();
    return all
        .where((ac) =>
            !ac.confirmed &&
            ac.scheduleDate.isBefore(now.add(Duration(days: 1))))
        .toList();
  }

  /// Get pending confirmations for specific user
  Future<List<AttendanceConfirmation>> getPendingConfirmationsByUserId(
    String userId,
  ) async {
    final all = await getAllAttendanceConfirmations();
    final now = DateTime.now();
    return all
        .where((ac) =>
            ac.userId == userId &&
            !ac.confirmed &&
            ac.scheduleDate.isBefore(now.add(Duration(days: 1))))
        .toList();
  }

  /// Add or update attendance confirmation
  Future<AttendanceConfirmation> addOrUpdateAttendanceConfirmation(
    AttendanceConfirmation confirmation,
  ) async {
    final all = await getAllAttendanceConfirmations();
    final existingIndex =
        all.indexWhere((ac) => ac.serviceScheduleId == confirmation.serviceScheduleId &&
            ac.userId == confirmation.userId);

    final now = DateTime.now();
    final id = confirmation.id.isEmpty
        ? const Uuid().v4()
        : confirmation.id;

    if (existingIndex != -1) {
      // Update existing
      final updated = confirmation.copyWith(
        id: id,
        updatedAt: now,
      );
      all[existingIndex] = updated;
      await _saveConfirmations(all);
      return updated;
    } else {
      // Add new
      final newConfirmation = confirmation.copyWith(
        id: id,
        createdAt: now,
        updatedAt: now,
      );
      all.add(newConfirmation);
      await _saveConfirmations(all);
      return newConfirmation;
    }
  }

  /// Confirm attendance
  Future<bool> confirmAttendance(
    String confirmationId,
    String? notes,
  ) async {
    final all = await getAllAttendanceConfirmations();
    final index = all.indexWhere((ac) => ac.id == confirmationId);

    if (index == -1) {
      return false;
    }

    final updated = all[index].copyWith(
      confirmed: true,
      confirmedAt: DateTime.now(),
      notes: notes,
      updatedAt: DateTime.now(),
    );

    all[index] = updated;
    await _saveConfirmations(all);
    return true;
  }

  /// Cancel attendance confirmation
  Future<bool> cancelConfirmation(String confirmationId) async {
    final all = await getAllAttendanceConfirmations();
    final index = all.indexWhere((ac) => ac.id == confirmationId);

    if (index == -1) {
      return false;
    }

    final updated = all[index].copyWith(
      confirmed: false,
      confirmedAt: null,
      notes: null,
      updatedAt: DateTime.now(),
    );

    all[index] = updated;
    await _saveConfirmations(all);
    return true;
  }

  /// Delete attendance confirmation
  Future<bool> deleteAttendanceConfirmation(String confirmationId) async {
    final all = await getAllAttendanceConfirmations();
    final initialLength = all.length;

    all.removeWhere((ac) => ac.id == confirmationId);

    if (all.length < initialLength) {
      await _saveConfirmations(all);
      return true;
    }
    return false;
  }

  /// Get unconfirmed count for user
  Future<int> getUnconfirmedCount(String userId) async {
    final pending = await getPendingConfirmationsByUserId(userId);
    return pending.length;
  }

  /// Save confirmations to storage
  Future<void> _saveConfirmations(
    List<AttendanceConfirmation> confirmations,
  ) async {
    final encoded = jsonEncode(confirmations.map((ac) => ac.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
