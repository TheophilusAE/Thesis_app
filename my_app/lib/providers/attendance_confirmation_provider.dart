import 'package:flutter/material.dart';
import '../models/attendance_confirmation.dart';
import '../services/attendance_confirmation_service.dart';

class AttendanceConfirmationProvider extends ChangeNotifier {
  final AttendanceConfirmationService _service;

  List<AttendanceConfirmation> _allConfirmations = [];
  List<AttendanceConfirmation> _userConfirmations = [];
  List<AttendanceConfirmation> _pendingConfirmations = [];
  int _unconfirmedCount = 0;
  bool _isLoading = false;

  AttendanceConfirmationProvider({
    required AttendanceConfirmationService service,
  }) : _service = service;

  // Getters
  List<AttendanceConfirmation> get allConfirmations => _allConfirmations;
  List<AttendanceConfirmation> get userConfirmations => _userConfirmations;
  List<AttendanceConfirmation> get pendingConfirmations => _pendingConfirmations;
  int get unconfirmedCount => _unconfirmedCount;
  bool get isLoading => _isLoading;

  /// Load all attendance confirmations
  Future<void> loadAllConfirmations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allConfirmations =
          await _service.getAllAttendanceConfirmations();
    } catch (e) {
      debugPrint('Error loading all confirmations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load confirmations for specific user
  Future<void> loadUserConfirmations(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userConfirmations = await _service.getAttendanceByUserId(userId);
      _pendingConfirmations =
          await _service.getPendingConfirmationsByUserId(userId);
      _unconfirmedCount = _pendingConfirmations.length;
    } catch (e) {
      debugPrint('Error loading user confirmations: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create or update attendance confirmation
  Future<bool> createOrUpdateConfirmation(
    AttendanceConfirmation confirmation,
  ) async {
    try {
      final newConfirmation =
          await _service.addOrUpdateAttendanceConfirmation(confirmation);
      final index = _allConfirmations.indexWhere(
          (ac) => ac.serviceScheduleId == newConfirmation.serviceScheduleId &&
              ac.userId == newConfirmation.userId);

      if (index != -1) {
        _allConfirmations[index] = newConfirmation;
      } else {
        _allConfirmations.add(newConfirmation);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating/updating confirmation: $e');
      return false;
    }
  }

  /// Confirm attendance
  Future<bool> confirmAttendance(
    String confirmationId,
    String? notes,
  ) async {
    try {
      final success = await _service.confirmAttendance(confirmationId, notes);

      if (success) {
        final index =
            _allConfirmations.indexWhere((ac) => ac.id == confirmationId);
        if (index != -1) {
          _allConfirmations[index] = _allConfirmations[index].copyWith(
            confirmed: true,
            confirmedAt: DateTime.now(),
            notes: notes,
            updatedAt: DateTime.now(),
          );
        }

        _pendingConfirmations
            .removeWhere((ac) => ac.id == confirmationId);
        _unconfirmedCount = _pendingConfirmations.length;
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error confirming attendance: $e');
      return false;
    }
  }

  /// Cancel confirmation
  Future<bool> cancelConfirmation(String confirmationId) async {
    try {
      final success = await _service.cancelConfirmation(confirmationId);

      if (success) {
        final index =
            _allConfirmations.indexWhere((ac) => ac.id == confirmationId);
        if (index != -1) {
          _allConfirmations[index] = _allConfirmations[index].copyWith(
            confirmed: false,
            confirmedAt: null,
            notes: null,
            updatedAt: DateTime.now(),
          );
        }

        final pendingIndex =
            _pendingConfirmations.indexWhere((ac) => ac.id == confirmationId);
        if (pendingIndex == -1) {
          _pendingConfirmations.add(_allConfirmations[index]);
        }
        _unconfirmedCount = _pendingConfirmations.length;
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error canceling confirmation: $e');
      return false;
    }
  }

  /// Delete confirmation
  Future<bool> deleteConfirmation(String confirmationId) async {
    try {
      final success =
          await _service.deleteAttendanceConfirmation(confirmationId);

      if (success) {
        _allConfirmations.removeWhere((ac) => ac.id == confirmationId);
        _userConfirmations.removeWhere((ac) => ac.id == confirmationId);
        _pendingConfirmations.removeWhere((ac) => ac.id == confirmationId);
        _unconfirmedCount = _pendingConfirmations.length;
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting confirmation: $e');
      return false;
    }
  }

  /// Get unconfirmed count
  Future<void> loadUnconfirmedCount(String userId) async {
    try {
      _unconfirmedCount = await _service.getUnconfirmedCount(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unconfirmed count: $e');
    }
  }
}
