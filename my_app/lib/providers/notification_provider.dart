import 'package:flutter/material.dart';
import '../models/notification.dart' as app_notification;
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  List<app_notification.AppNotification> _allNotifications = [];
  List<app_notification.AppNotification> _unreadNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _currentUserId;

  NotificationProvider({required NotificationService notificationService})
      : _notificationService = notificationService;

  // Getters
  List<app_notification.AppNotification> get allNotifications => _allNotifications;
  List<app_notification.AppNotification> get unreadNotifications => _unreadNotifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  /// Load notifications for user
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _currentUserId = userId;
    notifyListeners();

    try {
      _allNotifications = await _notificationService.getNotificationsByUserId(userId);
      _unreadNotifications = _allNotifications.where((n) => !n.isRead).toList();
      _unreadCount = _unreadNotifications.length;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get unread count
  Future<void> getUnreadCount(String userId) async {
    try {
      _unreadCount = await _notificationService.getUnreadCount(userId);
    } catch (e) {
      debugPrint('Error getting unread count: $e');
    }
    notifyListeners();
  }

  /// Create notification
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedScheduleId,
  }) async {
    try {
      final notification = await _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedScheduleId: relatedScheduleId,
      );

      if (_currentUserId == userId) {
        _allNotifications.insert(0, notification);
        _unreadNotifications.insert(0, notification);
        _unreadCount++;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return false;
    }
  }

  /// Create service reminder notification
  Future<bool> createServiceReminderNotification({
    required String userId,
    required String pelayaniName,
    required String serviceType,
    required String timeInfo,
    required String relatedScheduleId,
  }) async {
    try {
      await _notificationService.createServiceReminderNotification(
        userId: userId,
        pelayaniName: pelayaniName,
        serviceType: serviceType,
        timeInfo: timeInfo,
        relatedScheduleId: relatedScheduleId,
      );

      if (_currentUserId == userId) {
        await loadNotifications(userId);
      }

      return true;
    } catch (e) {
      debugPrint('Error creating service reminder: $e');
      return false;
    }
  }

  /// Create training reminder notification
  Future<bool> createTrainingReminderNotification({
    required String userId,
    required String trainingName,
    required String timeInfo,
    required String relatedScheduleId,
  }) async {
    try {
      await _notificationService.createTrainingReminderNotification(
        userId: userId,
        trainingName: trainingName,
        timeInfo: timeInfo,
        relatedScheduleId: relatedScheduleId,
      );

      if (_currentUserId == userId) {
        await loadNotifications(userId);
      }

      return true;
    } catch (e) {
      debugPrint('Error creating training reminder: $e');
      return false;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      if (success) {
        int index = _allNotifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _allNotifications[index] = _allNotifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );

          _unreadNotifications.removeWhere((n) => n.id == notificationId);
          _unreadCount = _unreadNotifications.length;
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint('Error marking as read: $e');
      return false;
    }
  }

  /// Mark all as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      final success = await _notificationService.markAllAsRead(userId);
      if (success) {
        for (int i = 0; i < _allNotifications.length; i++) {
          if (!_allNotifications[i].isRead) {
            _allNotifications[i] = _allNotifications[i].copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
        }
        _unreadNotifications.clear();
        _unreadCount = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await _notificationService.deleteNotification(notificationId);
      if (success) {
        _allNotifications.removeWhere((n) => n.id == notificationId);
        _unreadNotifications.removeWhere((n) => n.id == notificationId);
        _unreadCount = _unreadNotifications.length;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications(String userId) async {
    try {
      final success = await _notificationService.deleteAllNotifications(userId);
      if (success) {
        _allNotifications.clear();
        _unreadNotifications.clear();
        _unreadCount = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      return false;
    }
  }

  /// Get notifications by type
  Future<void> loadNotificationsByType(String userId, String type) async {
    try {
      final notifications = await _notificationService.getNotificationsByType(userId, type);
      _allNotifications = notifications;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications by type: $e');
    }
  }
}
