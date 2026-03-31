import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_quest.dart';
import 'bible_service.dart';

class QuestService {
  static const String _progressKey = 'reading_quest_progress';
  static const String _targetKey = 'reading_daily_target';

  Future<List<ReadingQuest>> getYearlyReadingPlan() async {
    final target = await getDailyReadingTarget();
    return _generateYearPlan(target);
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
}
