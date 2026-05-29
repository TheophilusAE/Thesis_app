import 'package:flutter/material.dart';
import '../models/feedback.dart' as fb;
import '../services/supabase_service.dart';

class FeedbackProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<fb.UserFeedback> _allFeedback = [];
  List<fb.UserFeedback> _filteredFeedback = [];
  bool _isLoading = false;
  String? _error;

  List<fb.UserFeedback> get allFeedback => _allFeedback;
  List<fb.UserFeedback> get filteredFeedback => _filteredFeedback;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getAllFeedback();
      _allFeedback = data.map((e) => fb.UserFeedback.fromJson(e)).toList();
      _filteredFeedback = List.from(_allFeedback);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading feedback: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitFeedback({
    required String userId,
    required String userName,
    required String feedbackType,
    required int rating,
    required String message,
    String? eventId,
    String? eventName,
    bool isAnonymous = false,
  }) async {
    try {
      final data = fb.UserFeedback(
        id: '',
        userId: userId,
        userName: isAnonymous ? 'Anonim' : userName,
        feedbackType: feedbackType,
        eventId: eventId,
        eventName: eventName,
        rating: rating,
        message: message,
        createdAt: DateTime.now(),
        isAnonymous: isAnonymous,
      ).toSupabaseJson();
      final result = await _service.addFeedback(data);
      final created = fb.UserFeedback.fromJson(result);
      _allFeedback.insert(0, created);
      _filteredFeedback = List.from(_allFeedback);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }

  Future<List<fb.UserFeedback>> getEventFeedback(String eventId) async {
    try {
      final data = await _service.getFeedbackByType('event');
      return data
          .map((e) => fb.UserFeedback.fromJson(e))
          .where((f) => f.eventId == eventId)
          .toList();
    } catch (e) {
      debugPrint('Error getting event feedback: $e');
      return [];
    }
  }

  Future<List<fb.UserFeedback>> getFacilityFeedback() async {
    try {
      final data = await _service.getFeedbackByType('facility');
      return data.map((e) => fb.UserFeedback.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting facility feedback: $e');
      return [];
    }
  }

  Future<double> getEventAverageRating(String eventId) async {
    final feedbacks = await getEventFeedback(eventId);
    if (feedbacks.isEmpty) return 0.0;
    final total = feedbacks.fold<int>(0, (sum, f) => sum + f.rating);
    return total / feedbacks.length;
  }

  Future<Map<String, dynamic>> getFeedbackStatistics(String feedbackType) async {
    try {
      final data = await _service.getFeedbackByType(feedbackType);
      final feedbacks = data.map((e) => fb.UserFeedback.fromJson(e)).toList();
      if (feedbacks.isEmpty) return {'count': 0, 'average_rating': 0.0};
      final total = feedbacks.fold<int>(0, (sum, f) => sum + f.rating);
      return {
        'count': feedbacks.length,
        'average_rating': total / feedbacks.length,
      };
    } catch (e) {
      debugPrint('Error getting feedback statistics: $e');
      return {'count': 0, 'average_rating': 0.0};
    }
  }

  void filterByType(String? type) {
    if (type == null || type.isEmpty) {
      _filteredFeedback = List.from(_allFeedback);
    } else {
      _filteredFeedback = _allFeedback.where((f) => f.feedbackType == type).toList();
    }
    notifyListeners();
  }

  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      await _service.deleteFeedback(feedbackId);
      _allFeedback.removeWhere((f) => f.id == feedbackId);
      _filteredFeedback.removeWhere((f) => f.id == feedbackId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting feedback: $e');
      return false;
    }
  }
}
