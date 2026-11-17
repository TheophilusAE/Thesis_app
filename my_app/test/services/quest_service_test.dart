import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/quest_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late QuestService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = QuestService();
  });

  test('progress is isolated per account on the same device', () async {
    await service.markDayCompleted('alice', 1);
    await service.markDayCompleted('alice', 2);
    await service.markDayCompleted('bob', 5);

    expect(await service.getCompletedDays('alice'), [1, 2]);
    expect(await service.getCompletedDays('bob'), [5]);
    expect(await service.getProgress('alice'), closeTo(2 / 365, 1e-9));
  });

  test('marking the same day twice does not duplicate it', () async {
    await service.markDayCompleted('alice', 3);
    await service.markDayCompleted('alice', 3);
    expect(await service.getCompletedDays('alice'), [3]);
  });

  test('legacy device-wide progress migrates once into the first account, then is removed', () async {
    SharedPreferences.setMockInitialValues({QuestService.legacyProgressKey: '[1,2,3]'});

    expect(await service.getCompletedDays('alice'), [1, 2, 3]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(QuestService.legacyProgressKey), isNull);
    // A second account on the device does not inherit it.
    expect(await service.getCompletedDays('bob'), isEmpty);
  });

  test('migration never overwrites progress an account already has', () async {
    SharedPreferences.setMockInitialValues({
      QuestService.legacyProgressKey: '[1,2,3]',
      QuestService.progressKeyFor('alice'): '[9]',
    });

    expect(await service.getCompletedDays('alice'), [9]);
  });

  group('calendarStreak', () {
    final today = DateTime(2026, 6, 30, 20);

    test('counts consecutive calendar days ending today', () {
      final streak = QuestService.calendarStreak([
        DateTime(2026, 6, 28, 7),
        DateTime(2026, 6, 29, 21),
        DateTime(2026, 6, 30, 6),
      ], today);
      expect(streak, 3);
    });

    test('a streak is still alive if the last reading was yesterday', () {
      final streak = QuestService.calendarStreak([
        DateTime(2026, 6, 28),
        DateTime(2026, 6, 29),
      ], today);
      expect(streak, 2);
    });

    test('a gap of two days resets the streak to 0', () {
      expect(QuestService.calendarStreak([DateTime(2026, 6, 27)], today), 0);
    });

    test('several readings on one day count as a single streak day', () {
      final streak = QuestService.calendarStreak([
        DateTime(2026, 6, 30, 6),
        DateTime(2026, 6, 30, 9),
        DateTime(2026, 6, 30, 12),
      ], today);
      expect(streak, 1);
    });

    test('completing plan days out of order does not inflate the streak', () async {
      // Old behaviour counted contiguous *plan day numbers*; marking days
      // 1..5 in one sitting is one calendar day, i.e. a streak of 1.
      for (var day = 1; day <= 5; day++) {
        await service.markDayCompleted('alice', day, completedOn: DateTime(2026, 6, 30, 8));
      }
      expect(await service.getCurrentStreak('alice', today: today), 1);
    });
  });
}
