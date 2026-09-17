import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/local_notification_service.dart';

void main() {
  group('reminderFireTimes', () {
    final now = DateTime(2026, 1, 5, 6); // Jan 5, 06:00

    test('computes 1/3/24 hour offsets before the event', () {
      final eventDate = DateTime(2026, 1, 6, 7); // Jan 6, 07:00 (25h out)
      final result = reminderFireTimes(eventDate, now: now);

      expect(result, hasLength(3));
      expect(result.map((r) => r.hoursBefore), containsAll([1, 3, 24]));
      expect(
        result.firstWhere((r) => r.hoursBefore == 24).fireAt,
        DateTime(2026, 1, 5, 7),
      );
      expect(
        result.firstWhere((r) => r.hoursBefore == 1).fireAt,
        DateTime(2026, 1, 6, 6),
      );
    });

    test('drops thresholds whose fire time has already passed', () {
      // Event only 2 hours away: the 3h and 24h thresholds are already past.
      final eventDate = now.add(const Duration(hours: 2));
      final result = reminderFireTimes(eventDate, now: now);

      expect(result, hasLength(1));
      expect(result.single.hoursBefore, 1);
    });

    test('returns an empty list when the event itself is in the past', () {
      final eventDate = now.subtract(const Duration(hours: 5));
      final result = reminderFireTimes(eventDate, now: now);

      expect(result, isEmpty);
    });

    test('supports custom thresholds', () {
      final eventDate = now.add(const Duration(hours: 10));
      final result = reminderFireTimes(eventDate, thresholdsHours: const [2, 8], now: now);

      expect(result, hasLength(2));
      expect(result.map((r) => r.hoursBefore), containsAll([2, 8]));
    });
  });
}
