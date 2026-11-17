import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_quest.dart';
import 'bible_service.dart';

/// Annual Bible reading plan + per-user progress (KF-12).
///
/// There is no reading-progress table in the database (and the schema must
/// not change), so progress is stored on the device — but scoped per
/// account, so two people sharing a phone never see each other's progress.
/// The daily target and the admin-edited plan are device-level settings.
class QuestService {
  /// Pre-per-user storage key; migrated once into the first account that
  /// loads progress on this device.
  static const String legacyProgressKey = 'reading_quest_progress';
  static const String _targetKey = 'reading_daily_target';
  static const String _customPlanKey = 'reading_quest_custom_plan';

  static String progressKeyFor(String userId) => 'reading_quest_progress_$userId';
  static String datesKeyFor(String userId) => 'reading_quest_dates_$userId';

  Future<List<ReadingQuest>?> _loadCustomPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customPlanKey);
    if (raw == null) {
      return null;
    }

    if (raw.isEmpty) {
      return <ReadingQuest>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final plan = decoded
        .map((item) => ReadingQuest.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    plan.sort((a, b) => a.day.compareTo(b.day));
    return plan;
  }

  Future<void> _saveCustomPlan(List<ReadingQuest> plan) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = plan
        .map(
          (quest) => ReadingQuest(
            day: quest.day,
            readings: quest.readings,
            isCompleted: false,
          ),
        )
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    await prefs.setString(
      _customPlanKey,
      jsonEncode(cleaned.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<ReadingQuest>> _loadEditablePlan() async {
    final custom = await _loadCustomPlan();
    if (custom != null) {
      return custom;
    }

    return _generateYearPlan(await getDailyReadingTarget());
  }

  Future<List<ReadingQuest>> getYearlyReadingPlan() async {
    final custom = await _loadCustomPlan();
    if (custom != null) {
      return custom;
    }

    final target = await getDailyReadingTarget();
    return _generateYearPlan(target);
  }

  Future<List<ReadingQuest>> getManagedPlan() async {
    return _loadEditablePlan();
  }

  List<ReadingQuest> _generateYearPlan(int dailyTarget) {
    final books = BibleService().getBibleBooks();
    final quests = <ReadingQuest>[];

    var bookIndex = 0;
    var chapter = 1;

    for (int day = 1; day <= 365; day++) {
      final readings = <ReadingPlan>[];
      var chaptersLeft = dailyTarget;

      while (chaptersLeft > 0) {
        final currentBook = books[bookIndex];
        final available = currentBook.chapters - chapter + 1;
        final take = available >= chaptersLeft ? chaptersLeft : available;
        final endChapter = chapter + take - 1;

        readings.add(
          ReadingPlan(
            book: currentBook.name,
            startChapter: chapter,
            endChapter: endChapter,
          ),
        );

        chaptersLeft -= take;
        if (endChapter >= currentBook.chapters) {
          bookIndex = (bookIndex + 1) % books.length;
          chapter = 1;
        } else {
          chapter = endChapter + 1;
        }
      }

      quests.add(ReadingQuest(day: day, readings: readings));
    }

    return quests;
  }

  /// Moves pre-per-user progress into [userId]'s key, once. Runs only when
  /// that user has no progress yet, so existing per-user data is never
  /// overwritten.
  Future<void> _migrateLegacyProgress(SharedPreferences prefs, String userId) async {
    final legacy = prefs.getString(legacyProgressKey);
    if (legacy == null) return;
    if (prefs.getString(progressKeyFor(userId)) == null) {
      await prefs.setString(progressKeyFor(userId), legacy);
    }
    await prefs.remove(legacyProgressKey);
  }

  /// Marks [day] of the plan done for [userId], recording [completedOn]
  /// (defaults to now) so the streak reflects real calendar days.
  Future<void> markDayCompleted(String userId, int day, {DateTime? completedOn}) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedDays(userId);
    if (completed.contains(day)) return;
    completed.add(day);
    await prefs.setString(progressKeyFor(userId), jsonEncode(completed));

    final dates = await _loadCompletionDates(prefs, userId);
    dates['$day'] = (completedOn ?? DateTime.now()).toIso8601String();
    await prefs.setString(datesKeyFor(userId), jsonEncode(dates));
  }

  Future<List<int>> getCompletedDays(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyProgress(prefs, userId);
    final jsonStr = prefs.getString(progressKeyFor(userId));
    if (jsonStr != null) {
      return List<int>.from(jsonDecode(jsonStr));
    }
    return [];
  }

  Future<Map<String, String>> _loadCompletionDates(SharedPreferences prefs, String userId) async {
    final raw = prefs.getString(datesKeyFor(userId));
    if (raw == null || raw.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<double> getProgress(String userId) async {
    final completed = await getCompletedDays(userId);
    return completed.length / 365.0;
  }

  /// Consecutive calendar days (ending today or yesterday) on which the user
  /// completed at least one reading. Progress saved before completion dates
  /// were recorded has no dates, so it can't count toward a streak.
  Future<int> getCurrentStreak(String userId, {DateTime? today}) async {
    final prefs = await SharedPreferences.getInstance();
    final dates = await _loadCompletionDates(prefs, userId);
    return calendarStreak(
      dates.values.map(DateTime.parse),
      today ?? DateTime.now(),
    );
  }

  /// Pure streak calculation, exposed for tests.
  static int calendarStreak(Iterable<DateTime> completionTimes, DateTime today) {
    final days = completionTimes
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    if (days.isEmpty) return 0;
    var cursor = DateTime(today.year, today.month, today.day);
    // A streak is still alive if the last reading was yesterday.
    if (!days.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  Future<int> getDailyReadingTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_targetKey) ?? 4;
  }

  Future<void> updateDailyReadingTarget(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetKey, target.clamp(1, 10));
  }

  Future<void> saveManagedPlan(List<ReadingQuest> plan) async {
    await _saveCustomPlan(plan);
  }

  Future<bool> addReadingQuest(ReadingQuest quest) async {
    final plan = await _loadEditablePlan();
    if (plan.any((entry) => entry.day == quest.day)) {
      return false;
    }

    plan.add(quest);
    await _saveCustomPlan(plan);
    return true;
  }

  Future<bool> updateReadingQuest(int originalDay, ReadingQuest updatedQuest) async {
    final plan = await _loadEditablePlan();
    final index = plan.indexWhere((entry) => entry.day == originalDay);
    if (index == -1) {
      return false;
    }

    final normalizedQuest = ReadingQuest(
      day: updatedQuest.day,
      readings: updatedQuest.readings,
      isCompleted: false,
    );

    plan[index] = normalizedQuest;
    plan.sort((a, b) => a.day.compareTo(b.day));
    await _saveCustomPlan(plan);
    return true;
  }

  Future<bool> deleteReadingQuest(int day) async {
    final plan = await _loadEditablePlan();
    final before = plan.length;
    plan.removeWhere((entry) => entry.day == day);
    if (plan.length == before) {
      return false;
    }

    await _saveCustomPlan(plan);
    return true;
  }

  Future<void> resetManagedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customPlanKey);
  }
}
