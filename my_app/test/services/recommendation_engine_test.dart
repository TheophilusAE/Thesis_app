import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/attendance_confirmation.dart';
import 'package:my_app/models/event.dart';
import 'package:my_app/models/feedback.dart';
import 'package:my_app/models/service_schedule.dart';
import 'package:my_app/services/recommendation_engine.dart';

final _now = DateTime(2026, 6, 30, 12);

ServiceSchedule _schedule(String id, DateTime date, {String type = 'Ibadah Minggu'}) =>
    ServiceSchedule(
      id: id,
      pelayaniId: 'p1',
      pelayaniName: 'Pelayan',
      pelayaniPosition: 'Usher',
      serviceDate: date,
      startTime: '08:00',
      endTime: '10:00',
      serviceType: type,
      isRecurring: false,
      recurringPattern: '',
      createdAt: date,
      updatedAt: date,
    );

/// [count] distinct confirmed attendees for [scheduleId].
List<AttendanceConfirmation> _attendees(String scheduleId, int count, DateTime date) => [
      for (var i = 0; i < count; i++)
        AttendanceConfirmation(
          id: '$scheduleId-$i',
          userId: 'u$i',
          userName: 'User $i',
          serviceScheduleId: scheduleId,
          scheduleDate: date,
          confirmed: true,
          confirmedAt: date,
          checkInMethod: 'qr',
          createdAt: date,
        ),
    ];

/// Weekly past services with the given attendance counts (oldest first).
({List<ServiceSchedule> schedules, List<AttendanceConfirmation> attendance}) _history(
  List<int> counts, {
  String type = 'Ibadah Minggu',
}) {
  final schedules = <ServiceSchedule>[];
  final attendance = <AttendanceConfirmation>[];
  for (var i = 0; i < counts.length; i++) {
    final date = DateTime(2026, 6, 28 - 7 * (counts.length - 1 - i));
    final id = '$type-$i';
    schedules.add(_schedule(id, date, type: type));
    attendance.addAll(_attendees(id, counts[i], date));
  }
  return (schedules: schedules, attendance: attendance);
}

UserFeedback _feedback(String type, int rating, {String? eventId, int daysAgo = 5}) =>
    UserFeedback(
      id: '$type-$rating-$daysAgo-${eventId ?? ''}',
      userId: 'u',
      userName: 'U',
      feedbackType: type,
      eventId: eventId,
      eventName: eventId == null ? null : 'Acara $eventId',
      rating: rating,
      message: 'm',
      createdAt: _now.subtract(Duration(days: daysAgo)),
    );

ChurchEvent _event(String id, DateTime date, {int? max}) => ChurchEvent(
      id: id,
      title: 'Acara $id',
      description: '',
      date: date,
      location: '',
      maxCapacity: max,
      isActive: true,
      createdAt: _now,
    );

RecommendationResult _run({
  List<ServiceSchedule> schedules = const [],
  List<AttendanceConfirmation> attendance = const [],
  List<UserFeedback> feedback = const [],
  List<EventWithRegistration> events = const [],
  int? capacity = 100,
}) =>
    RecommendationEngine.generate(RecommendationInput(
      schedules: schedules,
      attendance: attendance,
      feedback: feedback,
      events: events,
      now: _now,
      buildingCapacity: capacity,
    ));

Iterable<String> _titles(RecommendationResult r) => r.recommendations.map((e) => e.title);

void main() {
  group('service occurrences', () {
    test('several pelayan rows on the same day count as one service with distinct attendees', () {
      final day = DateTime(2026, 6, 28);
      final result = RecommendationEngine.serviceOccurrences(RecommendationInput(
        schedules: [_schedule('a', day), _schedule('b', day)],
        attendance: [..._attendees('a', 3, day), ..._attendees('b', 3, day)], // same u0..u2
        feedback: const [],
        events: const [],
        now: _now,
        buildingCapacity: null,
      ));
      expect(result['Ibadah Minggu'], hasLength(1));
      expect(result['Ibadah Minggu']!.single.attendees, 3);
    });

    test('future services and unconfirmed rows are ignored', () {
      final future = DateTime(2026, 7, 5);
      final result = RecommendationEngine.serviceOccurrences(RecommendationInput(
        schedules: [_schedule('f', future)],
        attendance: _attendees('f', 5, future),
        feedback: const [],
        events: const [],
        now: _now,
        buildingCapacity: null,
      ));
      expect(result, isEmpty);
    });
  });

  group('attendance rules', () {
    test('reports missing data instead of guessing', () {
      final r = _run();
      expect(_titles(r), contains('Belum ada data kehadiran ibadah'));
    });

    test('fewer than 3 services is "data belum cukup"', () {
      final h = _history([50, 50]);
      final r = _run(schedules: h.schedules, attendance: h.attendance);
      expect(_titles(r), contains('Data kehadiran belum cukup'));
    });

    test('≥90% of building capacity is a high-priority capacity warning', () {
      final h = _history([90, 92, 95, 94]);
      final r = _run(schedules: h.schedules, attendance: h.attendance, capacity: 100);
      final rec = r.recommendations.firstWhere((e) => e.category == RecommendationCategory.kapasitas);
      expect(rec.severity, RecommendationSeverity.warning);
      expect(rec.title, contains('hampir penuh'));
      expect(rec.dataBasis, contains('100 kursi'));
    });

    test('≤40% of building capacity suggests reviewing the service', () {
      final h = _history([30, 35, 30, 32]);
      final r = _run(schedules: h.schedules, attendance: h.attendance, capacity: 100);
      expect(_titles(r).any((t) => t.contains('Keterisian Ibadah Minggu rendah')), isTrue);
    });

    test('unconfigured capacity skips utilization but still analyses trends', () {
      final h = _history([50, 50, 50, 30, 30, 30]);
      final r = _run(schedules: h.schedules, attendance: h.attendance, capacity: null);
      expect(_titles(r), contains('Kapasitas gedung belum dikonfigurasi'));
      expect(r.recommendations.where((e) => e.category == RecommendationCategory.kapasitas), isEmpty);
      expect(_titles(r).any((t) => t.contains('menurun 40%')), isTrue);
    });

    test('a ≥20% increase is reported as positive', () {
      final h = _history([40, 40, 40, 60, 60, 60]);
      final r = _run(schedules: h.schedules, attendance: h.attendance, capacity: null);
      final rec = r.recommendations.firstWhere((e) => e.category == RecommendationCategory.kehadiran);
      expect(rec.severity, RecommendationSeverity.positive);
      expect(rec.title, contains('meningkat 50%'));
    });

    test('a stable trend produces no trend recommendation', () {
      final h = _history([50, 50, 50, 52, 51, 50]);
      final r = _run(schedules: h.schedules, attendance: h.attendance, capacity: null);
      expect(r.recommendations.where((e) => e.category == RecommendationCategory.kehadiran), isEmpty);
    });
  });

  group('event rules', () {
    test('an upcoming event at ≥90% of its quota is flagged', () {
      final r = _run(events: [EventWithRegistration(_event('e1', DateTime(2026, 7, 20), max: 50), 46)]);
      expect(_titles(r).any((t) => t.contains('hampir penuh (92%)')), isTrue);
    });

    test('low registration within 7 days suggests re-announcing', () {
      final r = _run(events: [EventWithRegistration(_event('e1', DateTime(2026, 7, 3), max: 100), 10)]);
      expect(_titles(r).any((t) => t.contains('masih rendah')), isTrue);
    });

    test('low registration far in advance is not flagged yet', () {
      final r = _run(events: [EventWithRegistration(_event('e1', DateTime(2026, 8, 30), max: 100), 10)]);
      expect(r.recommendations.where((e) => e.category == RecommendationCategory.kegiatan), isEmpty);
    });

    test('an event quota larger than the building is a capacity warning', () {
      final r = _run(
        events: [EventWithRegistration(_event('e1', DateTime(2026, 8, 30), max: 300), 0)],
        capacity: 200,
      );
      expect(_titles(r).any((t) => t.contains('melebihi kapasitas gedung')), isTrue);
    });

    test('past events are not evaluated for fill rate', () {
      final r = _run(events: [EventWithRegistration(_event('e1', DateTime(2026, 6, 1), max: 50), 50)]);
      expect(r.recommendations.where((e) => e.category == RecommendationCategory.kegiatan), isEmpty);
    });
  });

  group('feedback rules', () {
    test('average below 3.0 with ≥3 entries is a warning for that area', () {
      final r = _run(feedback: [
        _feedback('facility', 2),
        _feedback('facility', 3),
        _feedback('facility', 2),
      ]);
      final rec = r.recommendations.firstWhere((e) => e.category == RecommendationCategory.feedback);
      expect(rec.severity, RecommendationSeverity.warning);
      expect(rec.title, contains('Fasilitas'));
      expect(rec.title, contains('2.3/5'));
    });

    test('average ≥4.5 is positive', () {
      final r = _run(feedback: [
        _feedback('hospitality', 5),
        _feedback('hospitality', 5),
        _feedback('hospitality', 4),
      ]);
      expect(r.recommendations.any((e) =>
          e.category == RecommendationCategory.feedback &&
          e.severity == RecommendationSeverity.positive), isTrue);
    });

    test('fewer than 3 entries or entries older than 90 days are ignored', () {
      final r = _run(feedback: [
        _feedback('facility', 1),
        _feedback('facility', 1),
        _feedback('facility', 1, daysAgo: 120),
      ]);
      expect(r.recommendations.where((e) => e.category == RecommendationCategory.feedback), isEmpty);
      expect(r.summary.feedbackConsidered, 2);
    });

    test('a past event with poor linked feedback is flagged for evaluation', () {
      final past = _event('e9', DateTime(2026, 6, 10), max: 50);
      final r = _run(
        events: [EventWithRegistration(past, 0)],
        feedback: [
          _feedback('event', 2, eventId: 'e9'),
          _feedback('event', 2, eventId: 'e9'),
          _feedback('event', 3, eventId: 'e9'),
        ],
      );
      expect(_titles(r), contains('Evaluasi kegiatan "Acara e9"'));
    });
  });

  test('recommendations are ordered by severity, warnings first', () {
    final h = _history([95, 95, 95, 95]);
    final r = _run(
      schedules: h.schedules,
      attendance: h.attendance,
      feedback: [_feedback('general', 5), _feedback('general', 5), _feedback('general', 5)],
    );
    final severities = r.recommendations.map((e) => e.severity.index).toList();
    expect(severities, orderedEquals([...severities]..sort()));
    expect(r.recommendations.first.severity, RecommendationSeverity.warning);
  });

  test('output is aggregate only — no attendee names leak into recommendations', () {
    final h = _history([95, 95, 95, 95]);
    final r = _run(schedules: h.schedules, attendance: h.attendance);
    for (final rec in r.recommendations) {
      expect('${rec.title} ${rec.reason} ${rec.dataBasis}', isNot(contains('User ')));
    }
  });
}
