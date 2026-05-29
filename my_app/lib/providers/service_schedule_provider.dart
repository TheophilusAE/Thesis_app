import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_schedule.dart';
import '../services/supabase_service.dart';

class ServiceScheduleProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<ServiceSchedule> _allSchedules = [];
  List<ServiceSchedule> _filteredSchedules = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _subscription;

  List<ServiceSchedule> get allSchedules => _allSchedules;
  List<ServiceSchedule> get filteredSchedules => _filteredSchedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getSchedules();
      _allSchedules = data.map((e) => ServiceSchedule.fromJson(e)).toList();
      _filteredSchedules = List.from(_allSchedules);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading schedules: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSchedulesByPelayani(String pelayaniId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getSchedulesByPelayan(pelayaniId);
      _filteredSchedules = data.map((e) => ServiceSchedule.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading schedules by pelayani: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUpcomingSchedules(String pelayaniId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getUpcomingSchedulesByPelayan(pelayaniId);
      _filteredSchedules = data.map((e) => ServiceSchedule.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading upcoming schedules: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSchedulesByDateRange(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getSchedulesByDateRange(startDate, endDate);
      _filteredSchedules = data.map((e) => ServiceSchedule.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading schedules by date range: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSchedulesByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    await loadSchedulesByDateRange(start, end);
  }

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
      final schedule = ServiceSchedule(
        id: '',
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _service.addSchedule(schedule.toSupabaseJson());
      _allSchedules.add(ServiceSchedule.fromJson(result));
      _filteredSchedules = List.from(_allSchedules);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding schedule: $e');
      return false;
    }
  }

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
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (serviceDate != null) updates['service_date'] = serviceDate.toIso8601String();
      if (startTime != null) updates['start_time'] = startTime;
      if (endTime != null) updates['end_time'] = endTime;
      if (serviceType != null) updates['service_type'] = serviceType;
      if (isRecurring != null) updates['is_recurring'] = isRecurring;
      if (recurringPattern != null) updates['recurring_pattern'] = recurringPattern;
      if (notes != null) updates['notes'] = notes;

      await _service.updateSchedule(id, updates);

      final idx = _allSchedules.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _allSchedules[idx] = _allSchedules[idx].copyWith(
          serviceDate: serviceDate,
          startTime: startTime,
          endTime: endTime,
          serviceType: serviceType,
          isRecurring: isRecurring,
          recurringPattern: recurringPattern,
          notes: notes,
          updatedAt: DateTime.now(),
        );
        _filteredSchedules = List.from(_allSchedules);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating schedule: $e');
      return false;
    }
  }

  Future<bool> deleteServiceSchedule(String id) async {
    try {
      await _service.deleteSchedule(id);
      _allSchedules.removeWhere((s) => s.id == id);
      _filteredSchedules = List.from(_allSchedules);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting schedule: $e');
      return false;
    }
  }

  void filterByServiceType(String serviceType) {
    if (serviceType.isEmpty) {
      _filteredSchedules = List.from(_allSchedules);
    } else {
      _filteredSchedules = _allSchedules
          .where((s) => s.serviceType.toLowerCase() == serviceType.toLowerCase())
          .toList();
    }
    notifyListeners();
  }

  void subscribeToRealtime() {
    _subscription = _service.subscribeToSchedules((_) => loadAllSchedules());
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
