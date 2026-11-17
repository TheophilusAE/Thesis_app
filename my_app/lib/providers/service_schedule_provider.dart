import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_schedule.dart';
import '../services/supabase_service.dart';
import '../utils/recurrence.dart';

/// Outcome of creating a (possibly recurring) schedule: [created] holds the
/// rows actually saved, [requested] how many occurrences were attempted, and
/// [skippedDuplicates] how many were skipped because an identical duty
/// already existed.
class ScheduleCreateResult {
  final List<ServiceSchedule> created;
  final int requested;
  final int skippedDuplicates;

  const ScheduleCreateResult({
    required this.created,
    required this.requested,
    required this.skippedDuplicates,
  });

  bool get allSaved => created.length + skippedDuplicates == requested;
  bool get anySaved => created.isNotEmpty;
}

class ServiceScheduleProvider extends ChangeNotifier {
  ServiceScheduleProvider({SupabaseService? service})
      : _service = service ?? SupabaseService();

  final SupabaseService _service;

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

  /// True if an identical duty (same pelayan, service type, day and start
  /// time) is already loaded — prevents duplicate occurrences.
  bool _isDuplicate(String pelayaniId, String serviceType, DateTime date, String startTime) {
    return _allSchedules.any((s) =>
        s.pelayaniId == pelayaniId &&
        s.serviceType == serviceType &&
        s.startTime == startTime &&
        s.serviceDate.year == date.year &&
        s.serviceDate.month == date.month &&
        s.serviceDate.day == date.day);
  }

  /// Creates a schedule. When [isRecurring] is true, one row is created per
  /// occurrence (see [generateRecurrenceDates]); otherwise exactly one row.
  /// Occurrences that duplicate an already-loaded duty are skipped.
  Future<ScheduleCreateResult> addServiceSchedule({
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
    final dates = isRecurring
        ? generateRecurrenceDates(serviceDate, recurringPattern)
        : [DateTime(serviceDate.year, serviceDate.month, serviceDate.day)];

    final created = <ServiceSchedule>[];
    var skipped = 0;
    _error = null;

    for (final date in dates) {
      if (_isDuplicate(pelayaniId, serviceType, date, startTime)) {
        skipped++;
        continue;
      }
      try {
        final schedule = ServiceSchedule(
          id: '',
          pelayaniId: pelayaniId,
          pelayaniName: pelayaniName,
          pelayaniPosition: pelayaniPosition,
          serviceDate: date,
          startTime: startTime,
          endTime: endTime,
          serviceType: serviceType,
          isRecurring: isRecurring,
          recurringPattern: isRecurring ? recurringPattern : '',
          notes: notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final result = await _service.addSchedule(schedule.toSupabaseJson());
        final saved = ServiceSchedule.fromJson(result);
        _allSchedules.add(saved);
        created.add(saved);
      } catch (e) {
        _error = e.toString();
        debugPrint('Error adding schedule for $date: $e');
        // Stop at the first failure (usually RLS/network); later rows would
        // fail the same way and partial results are reported to the caller.
        break;
      }
    }

    _filteredSchedules = List.from(_allSchedules);
    notifyListeners();
    return ScheduleCreateResult(
      created: created,
      requested: dates.length,
      skippedDuplicates: skipped,
    );
  }

  // Substitution approval no longer reassigns the duty from the client: the
  // `review_substitution` RPC moves it and approves the request in one
  // database transaction (see SubstitutionRequestProvider.approveRequest).

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
