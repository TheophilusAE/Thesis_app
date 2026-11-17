/// Recurring service-schedule expansion (KF-05).
///
/// The `schedules` table stores `is_recurring` + `recurring_pattern` per row
/// but has no series/rule table, so a recurring schedule is materialized as
/// one real row per occurrence (attendance and substitution requests need a
/// concrete `schedules.id` to point at). This file only computes the dates.
library;

const String recurrenceWeekly = 'WEEKLY';
const String recurrenceBiWeekly = 'BI_WEEKLY';
const String recurrenceMonthly = 'MONTHLY';

const List<String> recurrencePatterns = [
  recurrenceWeekly,
  recurrenceBiWeekly,
  recurrenceMonthly,
];

/// How far ahead occurrences are generated when an admin creates a
/// recurring schedule. Kept short so a mistake is easy to clean up.
const int defaultRecurrenceHorizonDays = 90;

String recurrencePatternLabel(String pattern) {
  switch (pattern) {
    case recurrenceWeekly:
      return 'Mingguan';
    case recurrenceBiWeekly:
      return 'Dua Mingguan';
    case recurrenceMonthly:
      return 'Bulanan';
    default:
      return 'Sekali';
  }
}

/// Dates (midnight, local) of every occurrence from [start] up to and
/// including `start + horizonDays`. An unknown/empty [pattern] yields just
/// [start]. Monthly occurrences keep the original day of month, clamped to
/// the last day of shorter months (Jan 31 → Feb 28/29 → Mar 31).
List<DateTime> generateRecurrenceDates(
  DateTime start,
  String pattern, {
  int horizonDays = defaultRecurrenceHorizonDays,
}) {
  final first = DateTime(start.year, start.month, start.day);
  if (!recurrencePatterns.contains(pattern)) return [first];

  final last = DateTime(first.year, first.month, first.day + horizonDays);
  final dates = <DateTime>[];

  if (pattern == recurrenceMonthly) {
    for (var i = 0;; i++) {
      final month = first.month + i;
      final daysInMonth = DateTime(first.year, month + 1, 0).day;
      final day = first.day <= daysInMonth ? first.day : daysInMonth;
      final date = DateTime(first.year, month, day);
      if (date.isAfter(last)) break;
      dates.add(date);
    }
    return dates;
  }

  final stepDays = pattern == recurrenceWeekly ? 7 : 14;
  // Calendar-day arithmetic (not Duration) so a DST shift can never move an
  // occurrence to the wrong date.
  for (var i = 0;; i++) {
    final date = DateTime(first.year, first.month, first.day + i * stepDays);
    if (date.isAfter(last)) break;
    dates.add(date);
  }
  return dates;
}
