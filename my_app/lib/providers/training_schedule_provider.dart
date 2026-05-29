import 'package:flutter/material.dart';
import '../models/training_schedule.dart';
import '../services/supabase_service.dart';

class TrainingScheduleProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<TrainingSchedule> _allSchedules = [];
  List<TrainingSchedule> _filteredSchedules = [];
  bool _isLoading = false;
  String? _error;

  List<TrainingSchedule> get allSchedules => _allSchedules;
  List<TrainingSchedule> get filteredSchedules => _filteredSchedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getTrainingSchedules();
      _allSchedules = data.map((e) => TrainingSchedule.fromJson(e)).toList();
      _filteredSchedules = List.from(_allSchedules);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading training schedules: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTrainingSchedulesForPelayani(String pelayaniId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getTrainingSchedulesForPelayan(pelayaniId);
      _filteredSchedules = data.map((e) => TrainingSchedule.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading training schedules for pelayani: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUpcomingTrainingSchedules(String pelayaniId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getUpcomingTrainingSchedules(pelayaniId);
      _filteredSchedules = data.map((e) => TrainingSchedule.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading upcoming training schedules: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

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
      final schedule = TrainingSchedule(
        id: '',
        nama: nama,
        trainingDate: trainingDate,
        startTime: startTime,
        endTime: endTime,
        deskripsi: deskripsi,
        pelayaniIds: pelayaniIds,
        lokasi: lokasi,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _service.addTrainingSchedule(schedule.toSupabaseJson());
      _allSchedules.add(TrainingSchedule.fromJson(result));
      _filteredSchedules = List.from(_allSchedules);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding training schedule: $e');
      return false;
    }
  }

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
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (nama != null) updates['nama'] = nama;
      if (trainingDate != null) updates['training_date'] = trainingDate.toIso8601String();
      if (startTime != null) updates['start_time'] = startTime;
      if (endTime != null) updates['end_time'] = endTime;
      if (deskripsi != null) updates['deskripsi'] = deskripsi;
      if (pelayaniIds != null) updates['pelayan_ids'] = pelayaniIds;
      if (lokasi != null) updates['lokasi'] = lokasi;
      if (notes != null) updates['notes'] = notes;

      await _service.updateTrainingSchedule(id, updates);

      final idx = _allSchedules.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _allSchedules[idx] = _allSchedules[idx].copyWith(
          nama: nama,
          trainingDate: trainingDate,
          startTime: startTime,
          endTime: endTime,
          deskripsi: deskripsi,
          pelayaniIds: pelayaniIds,
          lokasi: lokasi,
          notes: notes,
          updatedAt: DateTime.now(),
        );
        _filteredSchedules = List.from(_allSchedules);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating training schedule: $e');
      return false;
    }
  }

  Future<bool> deleteTrainingSchedule(String id) async {
    try {
      await _service.deleteTrainingSchedule(id);
      _allSchedules.removeWhere((t) => t.id == id);
      _filteredSchedules = List.from(_allSchedules);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting training schedule: $e');
      return false;
    }
  }

  Future<bool> addPelayaniToTraining(String trainingId, String pelayaniId) async {
    try {
      final idx = _allSchedules.indexWhere((t) => t.id == trainingId);
      if (idx == -1) return false;
      final updated = List<String>.from(_allSchedules[idx].pelayaniIds)..add(pelayaniId);
      await _service.updateTrainingSchedule(trainingId, {'pelayan_ids': updated});
      _allSchedules[idx] = _allSchedules[idx].copyWith(pelayaniIds: updated);
      _filteredSchedules = List.from(_allSchedules);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> removePelayaniFromTraining(String trainingId, String pelayaniId) async {
    try {
      final idx = _allSchedules.indexWhere((t) => t.id == trainingId);
      if (idx == -1) return false;
      final updated = List<String>.from(_allSchedules[idx].pelayaniIds)
        ..remove(pelayaniId);
      await _service.updateTrainingSchedule(trainingId, {'pelayan_ids': updated});
      _allSchedules[idx] = _allSchedules[idx].copyWith(pelayaniIds: updated);
      _filteredSchedules = List.from(_allSchedules);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
