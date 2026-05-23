import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_schedule.dart';
import 'package:uuid/uuid.dart';

class TrainingScheduleService {
  static const String _trainingScheduleKey = '_trainingScheduleKey';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all training schedules
  Future<List<TrainingSchedule>> getAllTrainingSchedules() async {
    final jsonString = _prefs.getString(_trainingScheduleKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => TrainingSchedule.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Get training schedule by ID
  Future<TrainingSchedule?> getTrainingScheduleById(String id) async {
    final allSchedules = await getAllTrainingSchedules();
    try {
      return allSchedules.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get training schedules for a Pelayan
  Future<List<TrainingSchedule>> getTrainingSchedulesForPelayani(String pelayaniId) async {
    final allSchedules = await getAllTrainingSchedules();
    return allSchedules
        .where((t) => t.pelayaniIds.contains(pelayaniId))
        .toList()
      ..sort((a, b) => a.trainingDate.compareTo(b.trainingDate));
  }

  /// Get upcoming training schedules for a Pelayan (next 30 days)
  Future<List<TrainingSchedule>> getUpcomingTrainingSchedules(String pelayaniId) async {
    final schedules = await getTrainingSchedulesForPelayani(pelayaniId);
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(Duration(days: 30));

    return schedules
        .where((t) => t.trainingDate.isAfter(now) && t.trainingDate.isBefore(thirtyDaysFromNow))
        .toList();
  }

  /// Get all training schedules for a date range
  Future<List<TrainingSchedule>> getTrainingSchedulesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allSchedules = await getAllTrainingSchedules();
    return allSchedules
        .where((t) => t.trainingDate.isAfter(startDate) && t.trainingDate.isBefore(endDate))
        .toList()
      ..sort((a, b) => a.trainingDate.compareTo(b.trainingDate));
  }

  /// Get training schedules for specific date
  Future<List<TrainingSchedule>> getTrainingSchedulesByDate(DateTime date) async {
    final allSchedules = await getAllTrainingSchedules();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return allSchedules
        .where((t) => t.trainingDate.isAfter(startOfDay) && t.trainingDate.isBefore(endOfDay))
        .toList();
  }

  /// Add new training schedule
  Future<TrainingSchedule> addTrainingSchedule({
    required String nama,
    required DateTime trainingDate,
    required String startTime,
    required String endTime,
    required String deskripsi,
    required List<String> pelayaniIds,
    required String lokasi,
    String? notes,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final schedule = TrainingSchedule(
      id: id,
      nama: nama,
      trainingDate: trainingDate,
      startTime: startTime,
      endTime: endTime,
      deskripsi: deskripsi,
      pelayaniIds: pelayaniIds,
      lokasi: lokasi,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final allSchedules = await getAllTrainingSchedules();
    allSchedules.add(schedule);
    await _saveTrainingSchedules(allSchedules);

    return schedule;
  }

  /// Update training schedule
  Future<TrainingSchedule?> updateTrainingSchedule(
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
    final allSchedules = await getAllTrainingSchedules();
    int index = allSchedules.indexWhere((t) => t.id == id);

    if (index == -1) return null;

    final updated = allSchedules[index].copyWith(
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

    allSchedules[index] = updated;
    await _saveTrainingSchedules(allSchedules);

    return updated;
  }

  /// Delete training schedule
  Future<bool> deleteTrainingSchedule(String id) async {
    final allSchedules = await getAllTrainingSchedules();
    allSchedules.removeWhere((t) => t.id == id);
    await _saveTrainingSchedules(allSchedules);
    return true;
  }

  /// Add Pelayan to training schedule
  Future<TrainingSchedule?> addPelayaniToTraining(String trainingId, String pelayaniId) async {
    final schedule = await getTrainingScheduleById(trainingId);
    if (schedule == null) return null;

    if (schedule.pelayaniIds.contains(pelayaniId)) {
      return schedule; // Already added
    }

    final updatedPelayaniIds = [...schedule.pelayaniIds, pelayaniId];
    return updateTrainingSchedule(trainingId, pelayaniIds: updatedPelayaniIds);
  }

  /// Remove Pelayan from training schedule
  Future<TrainingSchedule?> removePelayaniFromTraining(String trainingId, String pelayaniId) async {
    final schedule = await getTrainingScheduleById(trainingId);
    if (schedule == null) return null;

    final updatedPelayaniIds = schedule.pelayaniIds.where((id) => id != pelayaniId).toList();
    return updateTrainingSchedule(trainingId, pelayaniIds: updatedPelayaniIds);
  }

  /// Get today's training schedules
  Future<List<TrainingSchedule>> getTodayTrainingSchedules() async {
    return getTrainingSchedulesByDate(DateTime.now());
  }

  /// Get count of training schedules
  Future<int> getTrainingScheduleCount() async {
    final schedules = await getAllTrainingSchedules();
    return schedules.length;
  }

  /// Save all training schedules to SharedPreferences
  Future<void> _saveTrainingSchedules(List<TrainingSchedule> schedules) async {
    final jsonList = schedules.map((t) => t.toJson()).toList();
    await _prefs.setString(_trainingScheduleKey, jsonEncode(jsonList));
  }
}
