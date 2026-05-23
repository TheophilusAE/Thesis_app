import 'package:flutter/material.dart';
import '../models/feedback.dart' as fb;
import '../services/feedback_service.dart';

class FeedbackProvider extends ChangeNotifier {
  final FeedbackService _feedbackService = FeedbackService();

  List<fb.UserFeedback> _allFeedback = [];
  List<fb.UserFeedback> _filteredFeedback = [];
  bool _isLoading = false;

  List<fb.UserFeedback> get allFeedback => _allFeedback;
  List<fb.UserFeedback> get filteredFeedback => _filteredFeedback;
  bool get isLoading => _isLoading;

  Future<void> loadAllFeedback() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allFeedback = await _feedbackService.getAllFeedback();
      _filteredFeedback = _allFeedback;
    } catch (e) {
      print('Error loading feedback: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<fb.UserFeedback>> getEventFeedback(String eventId) async {
    return await _feedbackService.getEventFeedback(eventId);
  }

  Future<List<fb.UserFeedback>> getFacilityFeedback() async {
    return await _feedbackService.getFacilityFeedback();
  }

  Future<double> getEventAverageRating(String eventId) async {
    return await _feedbackService.getEventAverageRating(eventId);
  }

  Future<Map<String, dynamic>> getFeedbackStatistics(String feedbackType) async {
    return await _feedbackService.getFeedbackStatistics(feedbackType);
  }

  void filterByType(String? type) {
    if (type == null || type.isEmpty) {
      _filteredFeedback = _allFeedback;
    } else {
      _filteredFeedback = _allFeedback
          .where((f) => f.feedbackType == type)
          .toList();
    }
    notifyListeners();
  }

  Future<bool> deleteFeedback(String feedbackId) async {
    final success = await _feedbackService.deleteFeedback(feedbackId);
    if (success) {
      _allFeedback.removeWhere((f) => f.id == feedbackId);
      _filteredFeedback.removeWhere((f) => f.id == feedbackId);
      notifyListeners();
    }
    return success;
  }
}
