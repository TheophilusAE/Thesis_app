import 'package:flutter/foundation.dart';

import '../models/attendance_confirmation.dart';
import '../models/feedback.dart';
import '../models/service_schedule.dart';
import '../services/event_service.dart';
import '../services/recommendation_engine.dart';
import '../services/supabase_service.dart';
import '../utils/church_config.dart';

typedef EventLoader = Future<List<EventWithRegistration>> Function(DateTime now);

/// Loads the existing tables the thesis names as decision-support inputs
/// (attendance, schedules, events + registrations, feedback) and runs the
/// rule-based [RecommendationEngine] over them. Admin-only: the reads rely
/// on admin RLS (attendance/feedback/registrations are otherwise own-rows).
class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({
    SupabaseService? service,
    EventLoader? eventLoader,
    int? buildingCapacity = ChurchConfig.buildingCapacity,
  })  : _service = service ?? SupabaseService(),
        _eventLoader = eventLoader ?? _loadEventsFromSupabase,
        _capacity = buildingCapacity;

  final SupabaseService _service;
  final EventLoader _eventLoader;
  final int? _capacity;

  RecommendationResult? _result;
  bool _isLoading = false;
  String? _error;
  DateTime? _generatedAt;

  RecommendationResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get generatedAt => _generatedAt;
  int? get buildingCapacity => _capacity;

  Future<void> generate({DateTime? now}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final at = now ?? DateTime.now();
    try {
      final responses = await Future.wait([
        _service.getSchedules(),
        _service.getAllAttendance(),
        _service.getAllFeedback(),
      ]);
      final events = await _eventLoader(at);

      _result = RecommendationEngine.generate(RecommendationInput(
        schedules: responses[0].map(ServiceSchedule.fromJson).toList(),
        attendance: responses[1].map(AttendanceConfirmation.fromJson).toList(),
        feedback: responses[2].map(UserFeedback.fromJson).toList(),
        events: events,
        now: at,
        buildingCapacity: _capacity,
      ));
      _generatedAt = at;
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      _error = 'Gagal memuat data untuk rekomendasi. Periksa koneksi lalu coba lagi.';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// All events (past ones are needed to name event-linked feedback), with
  /// a live headcount for upcoming active ones only — past headcounts are
  /// never used by the rules, so they aren't fetched.
  static Future<List<EventWithRegistration>> _loadEventsFromSupabase(DateTime now) async {
    final service = EventService();
    final events = await service.getAllEvents();
    return Future.wait(events.map((e) async {
      final upcoming = e.isActive && !e.date.isBefore(now);
      final count = upcoming ? await service.getRegisteredCount(e.id) : 0;
      return EventWithRegistration(e, count);
    }));
  }
}
