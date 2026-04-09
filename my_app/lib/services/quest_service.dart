import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_quest.dart';
import 'bible_service.dart';

class QuestService {
  static const String _progressKey = 'reading_quest_progress';
  static const String _targetKey = 'reading_daily_target';
  static const String _customPlanKey = 'reading_quest_custom_plan';

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

  Future<void> markDayCompleted(int day) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedDays();
    if (!completed.contains(day)) {
      completed.add(day);
      await prefs.setString(_progressKey, jsonEncode(completed));
    }
  }

  Future<List<int>> getCompletedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_progressKey);
    if (jsonStr != null) {
      return List<int>.from(jsonDecode(jsonStr));
    }
    return [];
  }

  Future<double> getProgress() async {
    final completed = await getCompletedDays();
    return completed.length / 365.0;
  }

  Future<int> getCurrentStreak() async {
    final completed = await getCompletedDays();
    if (completed.isEmpty) return 0;

    completed.sort();
    int streak = 1;
    
    for (int i = completed.length - 1; i > 0; i--) {
      if (completed[i] - completed[i - 1] == 1) {
        streak++;
      } else {
        break;
      }
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
