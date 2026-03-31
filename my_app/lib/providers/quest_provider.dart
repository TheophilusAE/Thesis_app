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

  List<ReadingQuest> get readingPlan => _readingPlan;
  List<int> get completedDays => _completedDays;
  double get progress => _progress;
  int get streak => _streak;
  bool get isLoading => _isLoading;
  int get dailyTarget => _dailyTarget;

  Future<void> loadReadingPlan() async {
    _isLoading = true;
    notifyListeners();

    _readingPlan = await _questService.getYearlyReadingPlan();
    _completedDays = await _questService.getCompletedDays();
    _dailyTarget = await _questService.getDailyReadingTarget();
    
    // Mark completed days in the plan
    for (var quest in _readingPlan) {
      quest.isCompleted = _completedDays.contains(quest.day);
    }

    _progress = await _questService.getProgress();
    _streak = await _questService.getCurrentStreak();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markDayCompleted(int day) async {
    await _questService.markDayCompleted(day);
    
    // Update local state
    final quest = _readingPlan.firstWhere((q) => q.day == day);
    quest.isCompleted = true;
    
    _completedDays = await _questService.getCompletedDays();
    _progress = await _questService.getProgress();
    _streak = await _questService.getCurrentStreak();

    notifyListeners();
  }

  Future<void> updateDailyTarget(int value) async {
    await _questService.updateDailyReadingTarget(value);
    await loadReadingPlan();
  }
}
