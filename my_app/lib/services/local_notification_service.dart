import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification.dart';
import '../models/service_schedule.dart';
import '../models/training_schedule.dart';
import 'notification_router.dart';

/// One reminder fire time derived from an event date and an hours-before
/// threshold. Kept as its own type (rather than a bare `DateTime`) so the
/// scheduling id can be built deterministically from `hoursBefore`.
class ReminderFireTime {
  final int hoursBefore;
  final DateTime fireAt;

  const ReminderFireTime(this.hoursBefore, this.fireAt);
}

/// Pure, unit-testable: given an event's date/time, returns the reminder
/// fire times that are still in the future (relative to [now]).
List<ReminderFireTime> reminderFireTimes(
  DateTime eventDate, {
  List<int> thresholdsHours = const [1, 3, 24],
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  return thresholdsHours
      .map((hours) => ReminderFireTime(hours, eventDate.subtract(Duration(hours: hours))))
      .where((r) => r.fireAt.isAfter(currentTime))
      .toList();
}

/// OS-level scheduled notifications for upcoming pelayan duties (service +
/// training schedules). No server-side cron involved — the church is in
/// Banjarmasin (WITA, Asia/Makassar), so the timezone is fixed rather than
/// pulling in a device-timezone plugin. Tapping a reminder opens the page
/// in its payload (see NotificationRouter). Uses `inexactAllowWhileIdle` (a few minutes of
/// slop is fine for a 1h/3h/24h reminder) to avoid the exact-alarm
/// permission/Play-policy friction.
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'schedule_reminders';
  static const _channelName = 'Pengingat Jadwal';
  static const pushChannelId = 'church_notifications';

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Makassar'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS: without Darwin settings the plugin throws at initialize(). The
    // permission prompt is deferred to requestPermission() so it isn't shown
    // at every cold start.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) => NotificationRouter.openPayload(response.payload),
    );
    // Channel for pushes and in-app announcements (also used by FCM for
    // pushes that arrive while the app is closed; see AndroidManifest).
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          pushChannelId,
          'Notifikasi Gereja',
          description: 'Pengumuman, jadwal pelayanan, dan info gereja',
          importance: Importance.high,
        ));
    _initialized = true;
  }

  /// Payload of the notification that launched the app from a closed state
  /// (opened once the first screen is shown).
  Future<String?> launchPayload() async {
    try {
      if (!_initialized) await init();
      final details = await _plugin.getNotificationAppLaunchDetails();
      return details?.didNotificationLaunchApp == true ? details?.notificationResponse?.payload : null;
    } catch (e) {
      debugPrint('Error reading launch notification: $e');
      return null;
    }
  }

  /// Shows a notification right away (e.g. a push received while the app
  /// is open). [payload] is a NotificationRouter payload.
  Future<void> showNow({required int id, required String title, required String body, String? payload}) async {
    if (!_initialized) await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          pushChannelId,
          'Notifikasi Gereja',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: payload,
    );
  }

  /// Asks for notification permission (Android 13+ / iOS). Never throws: a
  /// platform failure is logged and treated as "not granted" so the app keeps
  /// working without reminders.
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted || status.isProvisional;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  int _notificationId(String scheduleId, int hoursBefore) {
    return ('${scheduleId}_$hoursBefore').hashCode & 0x7fffffff;
  }

  Future<void> _scheduleOne({
    required String scheduleId,
    required int hoursBefore,
    required DateTime fireAt,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      _notificationId(scheduleId, hoursBefore),
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: NotificationRouter.encodePayload(NotificationRoute.jadwalPelayan),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels every pending reminder, then reschedules from the given
  /// upcoming schedules. Deterministic ids make this idempotent — safe to
  /// call on every app launch/resume, no separate "already notified"
  /// tracking needed.
  Future<void> scheduleReminders({
    required List<ServiceSchedule> schedules,
    required List<TrainingSchedule> trainings,
  }) async {
    if (!_initialized) await init();
    await cancelAll();

    for (final schedule in schedules) {
      for (final reminder in reminderFireTimes(schedule.serviceDate)) {
        try {
          await _scheduleOne(
            scheduleId: schedule.id,
            hoursBefore: reminder.hoursBefore,
            fireAt: reminder.fireAt,
            title: 'Pengingat Jadwal Ibadah',
            body: '${schedule.pelayaniName}, Anda dijadwalkan bertugas dalam '
                '${schedule.serviceType} pada ${schedule.startTime}.',
          );
        } catch (e) {
          debugPrint('Error scheduling service reminder for ${schedule.id}: $e');
        }
      }
    }

    for (final training in trainings) {
      for (final reminder in reminderFireTimes(training.trainingDate)) {
        try {
          await _scheduleOne(
            scheduleId: training.id,
            hoursBefore: reminder.hoursBefore,
            fireAt: reminder.fireAt,
            title: 'Pengingat Latihan',
            body: 'Jadwal latihan "${training.nama}" pada ${training.startTime}.',
          );
        } catch (e) {
          debugPrint('Error scheduling training reminder for ${training.id}: $e');
        }
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
