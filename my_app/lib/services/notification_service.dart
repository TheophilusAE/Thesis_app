import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static const String _notificationKey = '_notificationKey';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all notifications for a user
  Future<List<AppNotification>> getNotificationsByUserId(String userId) async {
    final allNotifications = await _getAllNotifications();
    return allNotifications
        .where((n) => n.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get unread notifications count for a user
  Future<int> getUnreadCount(String userId) async {
    final notifications = await getNotificationsByUserId(userId);
    return notifications.where((n) => !n.isRead).length;
  }

  /// Get unread notifications for a user
  Future<List<AppNotification>> getUnreadNotifications(String userId) async {
    final notifications = await getNotificationsByUserId(userId);
    return notifications.where((n) => !n.isRead).toList();
  }

  /// Create a new notification
  Future<AppNotification> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedScheduleId,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final notification = AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedScheduleId: relatedScheduleId,
      isRead: false,
      createdAt: now,
      readAt: null,
    );

    final allNotifications = await _getAllNotifications();
    allNotifications.add(notification);
    await _saveNotifications(allNotifications);

    return notification;
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    final allNotifications = await _getAllNotifications();
    int index = allNotifications.indexWhere((n) => n.id == notificationId);

    if (index == -1) return false;

    final updated = allNotifications[index].copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );

    allNotifications[index] = updated;
    await _saveNotifications(allNotifications);

    return true;
  }

  /// Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    final allNotifications = await _getAllNotifications();
    bool hasChanges = false;

    for (int i = 0; i < allNotifications.length; i++) {
      if (allNotifications[i].userId == userId && !allNotifications[i].isRead) {
        allNotifications[i] = allNotifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveNotifications(allNotifications);
    }

    return hasChanges;
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    final allNotifications = await _getAllNotifications();
    allNotifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications(allNotifications);
    return true;
  }

  /// Delete all notifications for a user
  Future<bool> deleteAllNotifications(String userId) async {
    final allNotifications = await _getAllNotifications();
    allNotifications.removeWhere((n) => n.userId == userId);
    await _saveNotifications(allNotifications);
    return true;
  }

  /// Get notifications by type
  Future<List<AppNotification>> getNotificationsByType(
    String userId,
    String type,
  ) async {
    final notifications = await getNotificationsByUserId(userId);
    return notifications.where((n) => n.type == type).toList();
  }

  /// Create service reminder notification
  Future<AppNotification> createServiceReminderNotification({
    required String userId,
    required String pelayaniName,
    required String serviceType,
    required String timeInfo,
    required String relatedScheduleId,
  }) async {
    final title = 'Pengingat Jadwal Pelayanan';
    final message = '$pelayaniName, Anda memiliki jadwal $serviceType dalam $timeInfo';

    return createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'service_reminder',
      relatedScheduleId: relatedScheduleId,
    );
  }

  /// Create training reminder notification
  Future<AppNotification> createTrainingReminderNotification({
    required String userId,
    required String trainingName,
    required String timeInfo,
    required String relatedScheduleId,
  }) async {
    final title = 'Pengingat Jadwal Latihan';
    final message = 'Ada jadwal latihan $trainingName dalam $timeInfo';

    return createNotification(
      userId: userId,
      title: title,
      message: message,
      type: 'training_reminder',
      relatedScheduleId: relatedScheduleId,
    );
  }

  /// Get all notifications
  Future<List<AppNotification>> _getAllNotifications() async {
    final jsonString = _prefs.getString(_notificationKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Save all notifications
  Future<void> _saveNotifications(List<AppNotification> notifications) async {
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await _prefs.setString(_notificationKey, jsonEncode(jsonList));
  }
}
