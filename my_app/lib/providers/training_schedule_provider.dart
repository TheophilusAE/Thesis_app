import 'package:flutter/material.dart';
import '../models/training_schedule.dart';
import '../services/training_schedule_service.dart';

class TrainingScheduleProvider extends ChangeNotifier {
  final TrainingScheduleService _trainingScheduleService;

  List<TrainingSchedule> _allSchedules = [];
  List<TrainingSchedule> _filteredSchedules = [];
  bool _isLoading = false;

  TrainingScheduleProvider({required TrainingScheduleService trainingScheduleService})
      : _trainingScheduleService = trainingScheduleService;

  // Getters
  List<TrainingSchedule> get allSchedules => _allSchedules;
  List<TrainingSchedule> get filteredSchedules => _filteredSchedules;
  bool get isLoading => _isLoading;

  /// Load all training schedules
  Future<void> loadAllSchedules() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allSchedules = await _trainingScheduleService.getAllTrainingSchedules();
      _filteredSchedules = _allSchedules;
    } catch (e) {
      debugPrint('Error loading training schedules: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load training schedules for a Pelayan
  Future<void> loadTrainingSchedulesForPelayani(String pelayaniId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredSchedules =
          await _trainingScheduleService.getTrainingSchedulesForPelayani(pelayaniId);
    } catch (e) {
      debugPrint('Error loading training schedules for Pelayan: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load upcoming training schedules for a Pelayan
  Future<void> loadUpcomingTrainingSchedules(String pelayaniId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredSchedules =
          await _trainingScheduleService.getUpcomingTrainingSchedules(pelayaniId);
    } catch (e) {
      debugPrint('Error loading upcoming training schedules: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add new training schedule
  Future<bool> addTrainingSchedule({
    required String nama,
    required DateTime trainingDate,
    required String startTime,
    required String endTime,
    required String deskripsi,
    required List<String> pelayaniIds,
    required String lokasi,
    String? notes,
  }) async {
    try {
      final newSchedule = await _trainingScheduleService.addTrainingSchedule(
        nama: nama,
        trainingDate: trainingDate,
        startTime: startTime,
        endTime: endTime,
        deskripsi: deskripsi,
        pelayaniIds: pelayaniIds,
        lokasi: lokasi,
        notes: notes,
      );

      _allSchedules.add(newSchedule);
      _filteredSchedules = _allSchedules;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding training schedule: $e');
      return false;
    }
  }

  /// Update training schedule
  Future<bool> updateTrainingSchedule(
    String id, {
    String? nama,
    DateTime? trainingDate,
    String? startTime,
    String? endTime,
    String? deskripsi,
    List<String>? pelayaniIds,
    String? lokasi,
    String? notes,
  }) async {
    try {
      final updated = await _trainingScheduleService.updateTrainingSchedule(
        id,
        nama: nama,
        trainingDate: trainingDate,
        startTime: startTime,
        endTime: endTime,
        deskripsi: deskripsi,
        pelayaniIds: pelayaniIds,
        lokasi: lokasi,
        notes: notes,
      );

      if (updated != null) {
        int index = _allSchedules.indexWhere((t) => t.id == id);
        if (index != -1) {
          _allSchedules[index] = updated;
          _filteredSchedules = _allSchedules;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating training schedule: $e');
      return false;
    }
  }

  /// Delete training schedule
  Future<bool> deleteTrainingSchedule(String id) async {
    try {
      final success = await _trainingScheduleService.deleteTrainingSchedule(id);
      if (success) {
        _allSchedules.removeWhere((t) => t.id == id);
        _filteredSchedules = _allSchedules;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting training schedule: $e');
      return false;
    }
  }

  /// Add Pelayan to training schedule
  Future<bool> addPelayaniToTraining(String trainingId, String pelayaniId) async {
    try {
      final updated = await _trainingScheduleService.addPelayaniToTraining(trainingId, pelayaniId);
      if (updated != null) {
        int index = _allSchedules.indexWhere((t) => t.id == trainingId);
        if (index != -1) {
          _allSchedules[index] = updated;
          _filteredSchedules = _allSchedules;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding Pelayan to training: $e');
      return false;
    }
  }

  /// Remove Pelayan from training schedule
  Future<bool> removePelayaniFromTraining(String trainingId, String pelayaniId) async {
    try {
      final updated =
          await _trainingScheduleService.removePelayaniFromTraining(trainingId, pelayaniId);
      if (updated != null) {
        int index = _allSchedules.indexWhere((t) => t.id == trainingId);
        if (index != -1) {
          _allSchedules[index] = updated;
          _filteredSchedules = _allSchedules;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing Pelayan from training: $e');
      return false;
    }
  }

  /// Get schedules by date range
  Future<void> loadSchedulesByDateRange(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredSchedules =
          await _trainingScheduleService.getTrainingSchedulesByDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('Error loading schedules by date range: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
