import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_schedule.dart';
import '../models/training_schedule.dart';
import '../services/service_schedule_service.dart';
import '../services/training_schedule_service.dart';
import '../services/notification_service.dart';

class NotificationScheduler {
  final ServiceScheduleService _serviceScheduleService;
  final TrainingScheduleService _trainingScheduleService;
  final NotificationService _notificationService;

  static const String _scheduledNotificationsKey = '_scheduledNotificationsKey';
  late SharedPreferences _prefs;

  // Default notification timings (in hours before event)
  static const List<int> defaultServiceReminderHours = [1, 3, 24]; // 1 hour, 3 hours, 1 day

  NotificationScheduler({
    required ServiceScheduleService serviceScheduleService,
    required TrainingScheduleService trainingScheduleService,
    required NotificationService notificationService,
  })  : _serviceScheduleService = serviceScheduleService,
        _trainingScheduleService = trainingScheduleService,
        _notificationService = notificationService;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check and create service schedule reminders
  Future<void> checkServiceScheduleReminders({
    List<int>? notificationHours,
    required List<String> pelayaniIds, // IDs of Pelayan to check
  }) async {
    final hours = notificationHours ?? defaultServiceReminderHours;
    final now = DateTime.now();

    // Check each Pelayan's schedule
    for (String pelayaniId in pelayaniIds) {
      try {
        final upcomingSchedules =
            await _serviceScheduleService.getUpcomingSchedules(pelayaniId);

        for (final schedule in upcomingSchedules) {
          // Check each reminder hour
          for (int hour in hours) {
            final reminderTime = schedule.serviceDate.subtract(Duration(hours: hour));
            final notificationId =
                _generateNotificationId('service', schedule.id, hour);

            // Check if notification already exists
            if (!await _notificationExists(notificationId)) {
              // Only create notification if reminder time has passed
              if (now.isAfter(reminderTime) && now.isBefore(schedule.serviceDate)) {
                final timeInfo = _formatTimeInfo(hour);

                // Get Pelayan user ID to send notification
                // Note: In real scenario, you'd fetch this from database
                // For now, we'll use pelayaniId as userId
                await _notificationService.createServiceReminderNotification(
                  userId: pelayaniId,
                  pelayaniName: schedule.pelayaniName,
                  serviceType: schedule.serviceType,
                  timeInfo: timeInfo,
                  relatedScheduleId: schedule.id,
                );

                // Mark notification as created
                await _markNotificationAsCreated(notificationId);
              }
            }
          }
        }
      } catch (e) {
        print('Error checking service reminders for Pelayan $pelayaniId: $e');
      }
    }
  }

  /// Check and create training schedule reminders
  Future<void> checkTrainingScheduleReminders({
    List<int>? notificationHours,
    required List<String> pelayaniIds,
  }) async {
    final hours = notificationHours ?? defaultServiceReminderHours;
    final now = DateTime.now();

    for (String pelayaniId in pelayaniIds) {
      try {
        final upcomingTrainings =
            await _trainingScheduleService.getUpcomingTrainingSchedules(pelayaniId);

        for (final training in upcomingTrainings) {
          // Check each reminder hour
          for (int hour in hours) {
            final reminderTime = training.trainingDate.subtract(Duration(hours: hour));
            final notificationId =
                _generateNotificationId('training', training.id, hour);

            // Check if notification already exists
            if (!await _notificationExists(notificationId)) {
              // Only create notification if reminder time has passed
              if (now.isAfter(reminderTime) && now.isBefore(training.trainingDate)) {
                final timeInfo = _formatTimeInfo(hour);

                await _notificationService.createTrainingReminderNotification(
                  userId: pelayaniId,
                  trainingName: training.nama,
                  timeInfo: timeInfo,
                  relatedScheduleId: training.id,
                );

                // Mark notification as created
                await _markNotificationAsCreated(notificationId);
              }
            }
          }
        }
      } catch (e) {
        print('Error checking training reminders for Pelayan $pelayaniId: $e');
      }
    }
  }

  /// Check all reminders (both service and training)
  Future<void> checkAllReminders({
    List<int>? notificationHours,
    required List<String> pelayaniIds,
  }) async {
    await checkServiceScheduleReminders(
      notificationHours: notificationHours,
      pelayaniIds: pelayaniIds,
    );
    await checkTrainingScheduleReminders(
      notificationHours: notificationHours,
      pelayaniIds: pelayaniIds,
    );
  }

  /// Mark notification as created to avoid duplicates
  Future<void> _markNotificationAsCreated(String notificationId) async {
    final scheduledNotifications = _getScheduledNotifications();
    scheduledNotifications.add(notificationId);
    await _prefs.setStringList(_scheduledNotificationsKey, scheduledNotifications.toList());
  }

  /// Check if notification was already created
  Future<bool> _notificationExists(String notificationId) async {
    final scheduled = _getScheduledNotifications();
    return scheduled.contains(notificationId);
  }

  /// Get list of scheduled notifications from cache
  Set<String> _getScheduledNotifications() {
    final cached = _prefs.getStringList(_scheduledNotificationsKey) ?? [];
    return cached.toSet();
  }

  /// Clear old notification tracking (older than 7 days)
  Future<void> clearOldNotificationTracking() async {
    // In a real app, you'd want to implement a more sophisticated tracking system
    // For now, we'll keep it simple
  }

  /// Generate unique notification ID
  String _generateNotificationId(String type, String scheduleId, int hoursBefore) {
    return '${type}_${scheduleId}_h${hoursBefore}';
  }

  /// Format time info for notification message
  String _formatTimeInfo(int hours) {
    if (hours == 1) return '1 jam';
    if (hours >= 24) return '${(hours / 24).toStringAsFixed(0)} hari';
    return '$hours jam';
  }
}
