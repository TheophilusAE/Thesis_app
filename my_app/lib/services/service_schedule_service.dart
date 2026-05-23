import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_schedule.dart';
import 'package:uuid/uuid.dart';

class ServiceScheduleService {
  static const String _serviceScheduleKey = '_serviceScheduleKey';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all service schedules
  Future<List<ServiceSchedule>> getAllServiceSchedules() async {
    final jsonString = _prefs.getString(_serviceScheduleKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => ServiceSchedule.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Get service schedule by ID
  Future<ServiceSchedule?> getServiceScheduleById(String id) async {
    final allSchedules = await getAllServiceSchedules();
    try {
      return allSchedules.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get schedules by Pelayan ID
  Future<List<ServiceSchedule>> getSchedulesByPelayaniId(String pelayaniId) async {
    final allSchedules = await getAllServiceSchedules();
    return allSchedules.where((s) => s.pelayaniId == pelayaniId).toList();
  }

  /// Get upcoming schedules for a Pelayan (next 30 days)
  Future<List<ServiceSchedule>> getUpcomingSchedules(String pelayaniId) async {
    final schedules = await getSchedulesByPelayaniId(pelayaniId);
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(Duration(days: 30));

    return schedules
        .where((s) => s.serviceDate.isAfter(now) && s.serviceDate.isBefore(thirtyDaysFromNow))
        .toList()
      ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
  }

  /// Get schedules by date range
  Future<List<ServiceSchedule>> getSchedulesByDateRange(DateTime startDate, DateTime endDate) async {
    final allSchedules = await getAllServiceSchedules();
    return allSchedules
        .where((s) => s.serviceDate.isAfter(startDate) && s.serviceDate.isBefore(endDate))
        .toList()
      ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
  }

  /// Get schedules for specific date
  Future<List<ServiceSchedule>> getSchedulesByDate(DateTime date) async {
    final allSchedules = await getAllServiceSchedules();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return allSchedules
        .where((s) => s.serviceDate.isAfter(startOfDay) && s.serviceDate.isBefore(endOfDay))
        .toList();
  }

  /// Add new service schedule
  Future<ServiceSchedule> addServiceSchedule({
    required String pelayaniId,
    required String pelayaniName,
    required String pelayaniPosition,
    required DateTime serviceDate,
    required String startTime,
    required String endTime,
    required String serviceType,
    required bool isRecurring,
    required String recurringPattern,
    String? notes,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final schedule = ServiceSchedule(
      id: id,
      pelayaniId: pelayaniId,
      pelayaniName: pelayaniName,
      pelayaniPosition: pelayaniPosition,
      serviceDate: serviceDate,
      startTime: startTime,
      endTime: endTime,
      serviceType: serviceType,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final allSchedules = await getAllServiceSchedules();
    allSchedules.add(schedule);
    await _saveServiceSchedules(allSchedules);

    return schedule;
  }

  /// Update service schedule
  Future<ServiceSchedule?> updateServiceSchedule(
    String id, {
    DateTime? serviceDate,
    String? startTime,
    String? endTime,
    String? serviceType,
    bool? isRecurring,
    String? recurringPattern,
    String? notes,
  }) async {
    final allSchedules = await getAllServiceSchedules();
    int index = allSchedules.indexWhere((s) => s.id == id);

    if (index == -1) return null;

    final updated = allSchedules[index].copyWith(
      serviceDate: serviceDate,
      startTime: startTime,
      endTime: endTime,
      serviceType: serviceType,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      notes: notes,
      updatedAt: DateTime.now(),
    );

    allSchedules[index] = updated;
    await _saveServiceSchedules(allSchedules);

    return updated;
  }

  /// Delete service schedule
  Future<bool> deleteServiceSchedule(String id) async {
    final allSchedules = await getAllServiceSchedules();
    allSchedules.removeWhere((s) => s.id == id);
    await _saveServiceSchedules(allSchedules);
    return true;
  }

  /// Get today's service schedules
  Future<List<ServiceSchedule>> getTodayServiceSchedules() async {
    return getSchedulesByDate(DateTime.now());
  }

  /// Get schedules count by Pelayan
  Future<int> getScheduleCountByPelayani(String pelayaniId) async {
    final schedules = await getSchedulesByPelayaniId(pelayaniId);
    return schedules.length;
  }

  /// Save all schedules to SharedPreferences
  Future<void> _saveServiceSchedules(List<ServiceSchedule> schedules) async {
    final jsonList = schedules.map((s) => s.toJson()).toList();
    await _prefs.setString(_serviceScheduleKey, jsonEncode(jsonList));
  }
}
