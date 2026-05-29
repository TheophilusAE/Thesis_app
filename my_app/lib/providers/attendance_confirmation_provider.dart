import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_confirmation.dart';
import '../services/supabase_service.dart';

class AttendanceConfirmationProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<AttendanceConfirmation> _allConfirmations = [];
  List<AttendanceConfirmation> _userConfirmations = [];
  List<AttendanceConfirmation> _pendingConfirmations = [];
  int _unconfirmedCount = 0;
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _subscription;

  List<AttendanceConfirmation> get allConfirmations => _allConfirmations;
  List<AttendanceConfirmation> get userConfirmations => _userConfirmations;
  List<AttendanceConfirmation> get pendingConfirmations => _pendingConfirmations;
  int get unconfirmedCount => _unconfirmedCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllConfirmations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getAllAttendance();
      _allConfirmations = data.map((e) => AttendanceConfirmation.fromJson(e)).toList();
      _pendingConfirmations = _allConfirmations.where((a) => !a.confirmed).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading all confirmations: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUserConfirmations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getAttendanceByUser(userId);
      _userConfirmations = data.map((e) => AttendanceConfirmation.fromJson(e)).toList();
      _pendingConfirmations = _userConfirmations.where((a) => !a.confirmed).toList();
      _unconfirmedCount = _pendingConfirmations.length;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user confirmations: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUnconfirmedCount(String userId) async {
    try {
      final data = await _service.getAttendanceByUser(userId);
      final confirmations = data.map((e) => AttendanceConfirmation.fromJson(e)).toList();
      _unconfirmedCount = confirmations.where((a) => !a.confirmed).length;
    } catch (e) {
      debugPrint('Error loading unconfirmed count: $e');
    }
    notifyListeners();
  }

  Future<bool> createOrUpdateConfirmation(AttendanceConfirmation confirmation) async {
    try {
      final data = confirmation.toSupabaseJson();
      final result = await _service.upsertAttendance(data);
      final updated = AttendanceConfirmation.fromJson(result);

      final allIdx = _allConfirmations.indexWhere((a) => a.id == updated.id);
      if (allIdx != -1) {
        _allConfirmations[allIdx] = updated;
      } else {
        _allConfirmations.insert(0, updated);
      }

      final userIdx = _userConfirmations.indexWhere((a) => a.id == updated.id);
      if (userIdx != -1) {
        _userConfirmations[userIdx] = updated;
      } else {
        _userConfirmations.insert(0, updated);
      }

      _pendingConfirmations = _userConfirmations.where((a) => !a.confirmed).toList();
      _unconfirmedCount = _pendingConfirmations.length;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating/updating confirmation: $e');
      return false;
    }
  }

  Future<bool> confirmAttendance(String confirmationId, String? notes) async {
    try {
      final now = DateTime.now();
      await _service.updateAttendance(confirmationId, {
        'confirmed': true,
        'confirmed_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'notes': notes,
      });
      _updateLocalConfirmation(confirmationId, confirmed: true, confirmedAt: now, notes: notes);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error confirming attendance: $e');
      return false;
    }
  }

  Future<bool> cancelConfirmation(String confirmationId) async {
    try {
      final now = DateTime.now();
      await _service.updateAttendance(confirmationId, {
        'confirmed': false,
        'confirmed_at': null,
        'updated_at': now.toIso8601String(),
      });
      _updateLocalConfirmation(confirmationId, confirmed: false);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error cancelling confirmation: $e');
      return false;
    }
  }

  Future<bool> deleteConfirmation(String confirmationId) async {
    try {
      await _service.deleteAttendance(confirmationId);
      _allConfirmations.removeWhere((a) => a.id == confirmationId);
      _userConfirmations.removeWhere((a) => a.id == confirmationId);
      _pendingConfirmations.removeWhere((a) => a.id == confirmationId);
      _unconfirmedCount = _pendingConfirmations.length;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting confirmation: $e');
      return false;
    }
  }

  void _updateLocalConfirmation(
    String id, {
    bool? confirmed,
    DateTime? confirmedAt,
    String? notes,
  }) {
    AttendanceConfirmation update(AttendanceConfirmation a) => a.copyWith(
          confirmed: confirmed,
          confirmedAt: confirmedAt,
          notes: notes,
          updatedAt: DateTime.now(),
        );

    final allIdx = _allConfirmations.indexWhere((a) => a.id == id);
    if (allIdx != -1) _allConfirmations[allIdx] = update(_allConfirmations[allIdx]);

    final userIdx = _userConfirmations.indexWhere((a) => a.id == id);
    if (userIdx != -1) _userConfirmations[userIdx] = update(_userConfirmations[userIdx]);

    _pendingConfirmations = _userConfirmations.where((a) => !a.confirmed).toList();
    _unconfirmedCount = _pendingConfirmations.length;
    notifyListeners();
  }

  void subscribeToRealtime() {
    _subscription = _service.subscribeToAttendance((_) => loadAllConfirmations());
  }

  void unsubscribeFromRealtime() {
    if (_subscription != null) {
      _service.unsubscribeChannel(_subscription!);
      _subscription = null;
    }
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    super.dispose();
  }
}
