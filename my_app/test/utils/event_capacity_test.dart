import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/event_capacity.dart';

void main() {
  group('remainingCapacity', () {
    test('is null when the event has no capacity limit', () {
      expect(remainingCapacity(maxCapacity: null, currentCount: 99), isNull);
    });

    test('subtracts the current headcount', () {
      expect(remainingCapacity(maxCapacity: 50, currentCount: 47), 3);
    });

    test('frees the user\'s own seats when editing an existing registration', () {
      // 50 seats, 50 taken, 4 of them are this user's → 4 available to them.
      expect(remainingCapacity(maxCapacity: 50, currentCount: 50, existingTotal: 4), 4);
    });

    test('never goes negative when already overbooked', () {
      expect(remainingCapacity(maxCapacity: 50, currentCount: 55), 0);
    });
  });

  group('fitsCapacity', () {
    test('always fits when there is no limit', () {
      expect(fitsCapacity(maxCapacity: null, currentCount: 1000, requestedTotal: 10), isTrue);
    });

    test('rejects a group larger than the remaining seats', () {
      expect(fitsCapacity(maxCapacity: 50, currentCount: 48, requestedTotal: 3), isFalse);
      expect(fitsCapacity(maxCapacity: 50, currentCount: 48, requestedTotal: 2), isTrue);
    });

    test('an edit that keeps the same size still fits a full event', () {
      expect(
        fitsCapacity(maxCapacity: 50, currentCount: 50, requestedTotal: 3, existingTotal: 3),
        isTrue,
      );
    });
  });
}
