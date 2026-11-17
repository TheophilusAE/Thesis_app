import 'package:flutter/foundation.dart';
import '../models/reading_quest.dart';
import '../services/quest_service.dart';

class QuestProvider with ChangeNotifier {
  final QuestService _questService = QuestService();
  List<ReadingQuest> _readingPlan = [];
  List<int> _completedDays = [];
  double _progress = 0.0;
  int _streak = 0;
  bool _isLoading = false;
  int _dailyTarget = 4;

  String? _userId;

  List<ReadingQuest> get readingPlan => _readingPlan;
  List<int> get completedDays => _completedDays;
  double get progress => _progress;
  int get streak => _streak;
  bool get isLoading => _isLoading;
  int get dailyTarget => _dailyTarget;

  /// Loads the plan and [userId]'s progress. Progress is per account; with
  /// no signed-in user the plan is shown without any progress.
  Future<void> loadReadingPlan(String? userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _readingPlan = await _questService.getYearlyReadingPlan();
    _dailyTarget = await _questService.getDailyReadingTarget();
    if (userId == null) {
      _completedDays = [];
      _progress = 0;
      _streak = 0;
    } else {
      _completedDays = await _questService.getCompletedDays(userId);
      _progress = await _questService.getProgress(userId);
      _streak = await _questService.getCurrentStreak(userId);
    }

    for (var quest in _readingPlan) {
      quest.isCompleted = _completedDays.contains(quest.day);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Returns false when nobody is signed in (progress can't be attributed).
  Future<bool> markDayCompleted(int day) async {
    final userId = _userId;
    if (userId == null) return false;
    await _questService.markDayCompleted(userId, day);

    for (final quest in _readingPlan) {
      if (quest.day == day) quest.isCompleted = true;
    }

    _completedDays = await _questService.getCompletedDays(userId);
    _progress = await _questService.getProgress(userId);
    _streak = await _questService.getCurrentStreak(userId);

    notifyListeners();
    return true;
  }

  Future<void> updateDailyTarget(int value) async {
    await _questService.updateDailyReadingTarget(value);
    await loadReadingPlan(_userId);
  }
}
