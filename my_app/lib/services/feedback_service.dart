import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feedback.dart' as fb;

class FeedbackService {
  static const _feedbackKey = 'app_feedback';

  // Get all feedback
  Future<List<fb.UserFeedback>> getAllFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final feedbackJson = prefs.getString(_feedbackKey);

    if (feedbackJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(feedbackJson);
      return decoded
          .map((item) => fb.UserFeedback.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading feedback: $e');
      return [];
    }
  }

  // Get feedback by type
  Future<List<fb.UserFeedback>> getFeedbackByType(String feedbackType) async {
    final allFeedback = await getAllFeedback();
    return allFeedback
        .where((f) => f.feedbackType == feedbackType)
        .toList();
  }

  // Get feedback for a specific event
  Future<List<fb.UserFeedback>> getEventFeedback(String eventId) async {
    final allFeedback = await getAllFeedback();
    return allFeedback
        .where((f) => f.feedbackType == 'event' && f.eventId == eventId)
        .toList();
  }

  // Get facility/hospitality feedback
  Future<List<fb.UserFeedback>> getFacilityFeedback() async {
    final allFeedback = await getAllFeedback();
    return allFeedback
        .where((f) => f.feedbackType == 'facility' || f.feedbackType == 'hospitality')
        .toList();
  }

  // Get average rating for an event
  Future<double> getEventAverageRating(String eventId) async {
    final eventFeedback = await getEventFeedback(eventId);
    if (eventFeedback.isEmpty) return 0.0;

    final totalRating = eventFeedback.fold<int>(
      0,
      (sum, feedback) => sum + feedback.rating,
    );

    return totalRating / eventFeedback.length;
  }

  // Get feedback by user
  Future<List<fb.UserFeedback>> getUserFeedback(String userId) async {
    final allFeedback = await getAllFeedback();
    return allFeedback
        .where((f) => f.userId == userId)
        .toList();
  }

  // Submit new feedback
  Future<bool> submitFeedback(fb.UserFeedback feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allFeedback = await getAllFeedback();

      allFeedback.add(feedback);

      final feedbackJson = jsonEncode(
        allFeedback.map((f) => f.toJson()).toList(),
      );

      await prefs.setString(_feedbackKey, feedbackJson);
      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  // Update feedback
  Future<bool> updateFeedback(fb.UserFeedback updatedFeedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allFeedback = await getAllFeedback();

      final index = allFeedback.indexWhere((f) => f.id == updatedFeedback.id);
      if (index == -1) return false;

      allFeedback[index] = updatedFeedback;

      final feedbackJson = jsonEncode(
        allFeedback.map((f) => f.toJson()).toList(),
      );

      await prefs.setString(_feedbackKey, feedbackJson);
      return true;
    } catch (e) {
      print('Error updating feedback: $e');
      return false;
    }
  }

  // Delete feedback
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allFeedback = await getAllFeedback();

      allFeedback.removeWhere((f) => f.id == feedbackId);

      final feedbackJson = jsonEncode(
        allFeedback.map((f) => f.toJson()).toList(),
      );

      await prefs.setString(_feedbackKey, feedbackJson);
      return true;
    } catch (e) {
      print('Error deleting feedback: $e');
      return false;
    }
  }

  // Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStatistics(String feedbackType) async {
    final feedback = await getFeedbackByType(feedbackType);
    if (feedback.isEmpty) {
      return {
        'total': 0,
        'averageRating': 0.0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }

    final totalRating = feedback.fold<int>(0, (sum, f) => sum + f.rating);
    final averageRating = totalRating / feedback.length;

    final ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var f in feedback) {
      ratingDistribution[f.rating] = (ratingDistribution[f.rating] ?? 0) + 1;
    }

    return {
      'total': feedback.length,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
    };
  }
}
