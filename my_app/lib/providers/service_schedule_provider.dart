import 'package:flutter/material.dart';
import '../models/service_schedule.dart';
import '../services/service_schedule_service.dart';

class ServiceScheduleProvider extends ChangeNotifier {
  final ServiceScheduleService _serviceScheduleService;

  List<ServiceSchedule> _allSchedules = [];
  List<ServiceSchedule> _filteredSchedules = [];
  bool _isLoading = false;

  ServiceScheduleProvider({required ServiceScheduleService serviceScheduleService})
      : _serviceScheduleService = serviceScheduleService;

  // Getters
  List<ServiceSchedule> get allSchedules => _allSchedules;
  List<ServiceSchedule> get filteredSchedules => _filteredSchedules;
  bool get isLoading => _isLoading;

  /// Load all service schedules
  Future<void> loadAllSchedules() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allSchedules = await _serviceScheduleService.getAllServiceSchedules();
      _filteredSchedules = _allSchedules;
    } catch (e) {
      debugPrint('Error loading service schedules: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load schedules for a Pelayan
  Future<void> loadSchedulesByPelayani(String pelayaniId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredSchedules = await _serviceScheduleService.getSchedulesByPelayaniId(pelayaniId);
    } catch (e) {
      debugPrint('Error loading schedules by Pelayan: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load upcoming schedules for a Pelayan
  Future<void> loadUpcomingSchedules(String pelayaniId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredSchedules = await _serviceScheduleService.getUpcomingSchedules(pelayaniId);
    } catch (e) {
      debugPrint('Error loading upcoming schedules: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add new service schedule
  Future<bool> addServiceSchedule({
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
    try {
      final newSchedule = await _serviceScheduleService.addServiceSchedule(
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
      );

      _allSchedules.add(newSchedule);
      _filteredSchedules = _allSchedules;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding service schedule: $e');
      return false;
    }
  }

  /// Update service schedule
  Future<bool> updateServiceSchedule(
    String id, {
    DateTime? serviceDate,
    String? startTime,
    String? endTime,
    String? serviceType,
    bool? isRecurring,
    String? recurringPattern,
    String? notes,
  }) async {
    try {
      final updated = await _serviceScheduleService.updateServiceSchedule(
        id,
        serviceDate: serviceDate,
        startTime: startTime,
        endTime: endTime,
        serviceType: serviceType,
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
        notes: notes,
      );

      if (updated != null) {
        int index = _allSchedules.indexWhere((s) => s.id == id);
        if (index != -1) {
          _allSchedules[index] = updated;
          _filteredSchedules = _allSchedules;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating service schedule: $e');
      return false;
    }
  }

  /// Delete service schedule
  Future<bool> deleteServiceSchedule(String id) async {
    try {
      final success = await _serviceScheduleService.deleteServiceSchedule(id);
      if (success) {
        _allSchedules.removeWhere((s) => s.id == id);
        _filteredSchedules = _allSchedules;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting service schedule: $e');
      return false;
    }
  }

  /// Get schedules for date range
  Future<void> loadSchedulesByDateRange(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredSchedules =
          await _serviceScheduleService.getSchedulesByDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('Error loading schedules by date range: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get schedules for specific date
  Future<void> loadSchedulesByDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredSchedules = await _serviceScheduleService.getSchedulesByDate(date);
    } catch (e) {
      debugPrint('Error loading schedules by date: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Filter schedules by service type
  void filterByServiceType(String serviceType) {
    if (serviceType.isEmpty) {
      _filteredSchedules = _allSchedules;
    } else {
      _filteredSchedules =
          _allSchedules.where((s) => s.serviceType.toLowerCase() == serviceType.toLowerCase()).toList();
    }
    notifyListeners();
  }
}
