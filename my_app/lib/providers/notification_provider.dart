import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;
import '../services/supabase_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({SupabaseService? service})
      : _service = service ?? SupabaseService();

  final SupabaseService _service;
  String? _subscribedUserId;

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

  String? _loadedUserId;

  /// Loads the inbox once per signed-in user and starts realtime updates.
  /// Switching accounts on the same device discards the previous inbox.
  Future<void> ensureLoadedFor(String userId) async {
    subscribeToRealtime(userId);
    if (_loadedUserId == userId) return;
    await loadNotifications(userId);
  }

  Future<void> loadNotifications(String userId) async {
    if (_loadedUserId != userId) {
      _allNotifications = [];
      _unreadNotifications = [];
      _unreadCount = 0;
    }
    _loadedUserId = userId;
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

  /// Sends the same in-app notification to several other users (e.g. an
  /// admin approving a substitution or publishing a schedule). These rows
  /// belong to other users, so they are never added to this device's list.
  /// Returns false on failure so callers can report it honestly.
  Future<bool> notifyUsers({
    required Iterable<String> userIds,
    required String title,
    required String message,
    required String type,
    String? relatedScheduleId,
    String? category,
    String? route,
    Map<String, dynamic>? routeParams,
  }) async {
    final targets = userIds.where((id) => id.isNotEmpty).toSet();
    if (targets.isEmpty) return true;
    List<Map<String, dynamic>> rows({required bool v2}) => [
          for (final id in targets)
            {
              'user_id': id,
              'title': title,
              'message': message,
              'type': type,
              'related_schedule_id': relatedScheduleId,
              'is_read': false,
              if (v2) 'category': category ?? app_notification.NotificationCategory.fromType(type),
              if (v2) 'route': route ?? app_notification.NotificationRoute.fromType(type),
              if (v2 && routeParams != null) 'route_params': routeParams,
            },
        ];
    try {
      try {
        await _service.addNotifications(rows(v2: true));
      } on PostgrestException catch (e) {
        // Before migration_notifications_v2.sql the new columns don't exist:
        // still deliver the notification (category/route are derived on read).
        if (e.code != 'PGRST204' && e.code != '42703') rethrow;
        await _service.addNotifications(rows(v2: false));
      }
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending notifications: $e');
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

  /// Idempotent: re-subscribing for the same user is a no-op, and switching
  /// users drops the previous channel first.
  void subscribeToRealtime(String userId) {
    if (_subscribedUserId == userId && _subscription != null) return;
    unsubscribeFromRealtime();
    _subscribedUserId = userId;
    _subscription = _service.subscribeToNotifications(userId, (_) => loadNotifications(userId));
  }

  void unsubscribeFromRealtime() {
    if (_subscription != null) {
      _service.unsubscribeChannel(_subscription!);
      _subscription = null;
    }
    _subscribedUserId = null;
  }

  /// Clears the inbox when the signed-in user changes, so one account never
  /// sees another account's notifications on a shared device.
  void clearForSignOut() {
    unsubscribeFromRealtime();
    _loadedUserId = null;
    _allNotifications = [];
    _unreadNotifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeFromRealtime();
    super.dispose();
  }
}
