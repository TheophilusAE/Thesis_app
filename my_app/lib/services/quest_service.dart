import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_quest.dart';

class QuestService {
  static const String _progressKey = 'reading_quest_progress';

  Future<List<ReadingQuest>> getYearlyReadingPlan() async {
    // This is a simplified version. In a real app, you'd load from a JSON file or API
    return _generateSamplePlan();
  }

  List<ReadingQuest> _generateSamplePlan() {
    // Sample 10-day reading plan (expand to 365 days in production)
    return [
      ReadingQuest(
        day: 1,
        readings: [
          ReadingPlan(book: 'Kejadian', startChapter: 1, endChapter: 3),
          ReadingPlan(book: 'Matius', startChapter: 1, endChapter: 1),
        ],
      ),
      ReadingQuest(
        day: 2,
        readings: [
          ReadingPlan(book: 'Kejadian', startChapter: 4, endChapter: 6),
          ReadingPlan(book: 'Matius', startChapter: 2, endChapter: 2),
        ],
      ),
      ReadingQuest(
        day: 3,
        readings: [
          ReadingPlan(book: 'Kejadian', startChapter: 7, endChapter: 9),
          ReadingPlan(book: 'Matius', startChapter: 3, endChapter: 3),
        ],
      ),
      ReadingQuest(
        day: 4,
        readings: [
          ReadingPlan(book: 'Kejadian', startChapter: 10, endChapter: 12),
          ReadingPlan(book: 'Matius', startChapter: 4, endChapter: 4),
        ],
      ),
      ReadingQuest(
        day: 5,
        readings: [
          ReadingPlan(book: 'Kejadian', startChapter: 13, endChapter: 15),
          ReadingPlan(book: 'Matius', startChapter: 5, endChapter: 5),
        ],
      ),
    ];
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
}
