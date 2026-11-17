import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/recurrence.dart';

void main() {
  group('generateRecurrenceDates', () {
    test('a non-recurring / unknown pattern yields only the start date (time stripped)', () {
      final dates = generateRecurrenceDates(DateTime(2026, 1, 4, 9, 30), '');
      expect(dates, [DateTime(2026, 1, 4)]);
    });

    test('weekly within 90 days gives 13 Sundays, 7 days apart', () {
      final dates = generateRecurrenceDates(DateTime(2026, 1, 4), recurrenceWeekly);
      expect(dates, hasLength(13)); // day 0, 7, …, 84
      expect(dates.first, DateTime(2026, 1, 4));
      expect(dates.last, DateTime(2026, 3, 29));
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].difference(dates[i - 1]).inDays, 7);
        expect(dates[i].weekday, DateTime.sunday);
      }
    });

    test('bi-weekly within 90 days gives 7 dates, 14 days apart', () {
      final dates = generateRecurrenceDates(DateTime(2026, 1, 4), recurrenceBiWeekly);
      expect(dates, hasLength(7)); // day 0, 14, …, 84
      expect(dates[1], DateTime(2026, 1, 18));
    });

    test('monthly keeps the day of month and includes the boundary date', () {
      // Jan 1 + 90 days = Apr 1 (inclusive).
      final dates = generateRecurrenceDates(DateTime(2026, 1, 1), recurrenceMonthly);
      expect(dates, [
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 1),
        DateTime(2026, 3, 1),
        DateTime(2026, 4, 1),
      ]);
    });

    test('monthly clamps day 31 to the end of shorter months', () {
      final dates = generateRecurrenceDates(DateTime(2026, 1, 31), recurrenceMonthly);
      expect(dates[0], DateTime(2026, 1, 31));
      expect(dates[1], DateTime(2026, 2, 28));
      expect(dates[2], DateTime(2026, 3, 31));
    });

    test('monthly crosses the year boundary', () {
      final dates = generateRecurrenceDates(DateTime(2026, 12, 15), recurrenceMonthly);
      expect(dates[1], DateTime(2027, 1, 15));
    });

    test('custom horizon is respected', () {
      final dates =
          generateRecurrenceDates(DateTime(2026, 1, 4), recurrenceWeekly, horizonDays: 14);
      expect(dates, [DateTime(2026, 1, 4), DateTime(2026, 1, 11), DateTime(2026, 1, 18)]);
    });
  });

  test('recurrencePatternLabel maps every pattern to Indonesian', () {
    expect(recurrencePatternLabel(recurrenceWeekly), 'Mingguan');
    expect(recurrencePatternLabel(recurrenceBiWeekly), 'Dua Mingguan');
    expect(recurrencePatternLabel(recurrenceMonthly), 'Bulanan');
    expect(recurrencePatternLabel(''), 'Sekali');
  });
}
