import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;
import '../services/supabase_service.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<app_notification.AppNotification> _allNotifications = [];
  List<app_notification.AppNotification> _unreadNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _subscription;

  List<app_notification.AppNotification> get allNotifications => _allNotifications;
  List<app_notification.AppNotification> get unreadNotifications => _unreadNotifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getNotifications(userId);
      _allNotifications =
          data.map((e) => app_notification.AppNotification.fromJson(e)).toList();
      _unreadNotifications = _allNotifications.where((n) => !n.isRead).toList();
      _unreadCount = _unreadNotifications.length;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> getUnreadCount(String userId) async {
    try {
      _unreadCount = await _service.getUnreadNotificationCount(userId);
    } catch (e) {
      debugPrint('Error getting unread count: $e');
    }
    notifyListeners();
  }

  Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedScheduleId,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_schedule_id': relatedScheduleId,
        'is_read': false,
      };
      final result = await _service.addNotification(data);
      _allNotifications.insert(0, app_notification.AppNotification.fromJson(result));
      _unreadNotifications = _allNotifications.where((n) => !n.isRead).toList();
      _unreadCount = _unreadNotifications.length;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating notification: $e');
      return false;
    }
  }

  Future<bool> createServiceReminderNotification({
    required String userId,
    required String pelayaniName,
    required String serviceType,
    required String timeInfo,
    required String relatedScheduleId,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Pengingat Jadwal Ibadah',
      message: '$pelayaniName, Anda dijadwalkan bertugas dalam $serviceType $timeInfo.',
      type: 'service_reminder',
      relatedScheduleId: relatedScheduleId,
    );
  }

  Future<bool> createTrainingReminderNotification({
    required String userId,
    required String trainingName,
    required String timeInfo,
    required String relatedScheduleId,
  }) async {
    return createNotification(
      userId: userId,
      title: 'Pengingat Latihan',
      message: 'Jadwal latihan "$trainingName" $timeInfo.',
      type: 'training_reminder',
      relatedScheduleId: relatedScheduleId,
    );
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _service.markNotificationAsRead(notificationId);
      final idx = _allNotifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _allNotifications[idx] = _allNotifications[idx].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadNotifications = _allNotifications.where((n) => !n.isRead).toList();
        _unreadCount = _unreadNotifications.length;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(String userId) async {
    try {
      await _service.markAllNotificationsAsRead(userId);
      _allNotifications = _allNotifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
      _unreadNotifications = [];
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _service.deleteNotification(notificationId);
      _allNotifications.removeWhere((n) => n.id == notificationId);
      _unreadNotifications = _allNotifications.where((n) => !n.isRead).toList();
      _unreadCount = _unreadNotifications.length;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  Future<bool> deleteAllNotifications(String userId) async {
    try {
      await _service.deleteAllNotifications(userId);
      _allNotifications = [];
      _unreadNotifications = [];
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting all notifications: $e');
      return false;
    }
  }

  void subscribeToRealtime(String userId) {
    _subscription = _service.subscribeToNotifications(userId, (_) => loadNotifications(userId));
  }

  void unsubscribeFromRealtime() {
    if (_subscription != null) {
      _service.unsubscribeChannel(_subscription!);
      _subscription = null;
    }
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    super.dispose();
  }
}
