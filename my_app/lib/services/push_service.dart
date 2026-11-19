import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notification_service.dart';
import 'notification_router.dart';
import 'supabase_service.dart';

/// Push notifications via Firebase Cloud Messaging (Android).
///
/// The app only *receives* pushes and registers this phone's token in
/// `device_tokens` (own rows, RLS). Sending happens server-side: every new
/// row in `notifications` triggers the `send-push` Edge Function, which holds
/// the Firebase service-account key — the app never does.
///
/// Uses the classic FCM registration token (getToken/onTokenRefresh), which
/// the FCM HTTP v1 send API targets. firebase_messaging 17 marks it
/// deprecated in favour of the new FID direct-send API; switch once the
/// server side supports FIDs.
///
/// iOS is not configured (no GoogleService-Info.plist / APNs key), so push is
/// skipped there; in-app notifications and local reminders keep working.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _initialized = false;
  String? _registeredUserId;
  StreamSubscription<String>? _tokenRefresh;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Called once from main(). Never throws: without Firebase the app runs
  /// exactly as before.
  Future<void> init() async {
    if (_initialized || !_supported) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => NotificationRouter.openPayload(_payloadOf(m)));
      _initialized = true;
    } catch (e) {
      debugPrint('PushService.init: Firebase unavailable ($e)');
    }
  }

  /// Payload format shared with local notifications (NotificationRouter).
  static String _payloadOf(RemoteMessage m) => NotificationRouter.encodePayload(
        m.data['route'] as String? ?? '',
        title: m.notification?.title ?? m.data['title'] as String?,
        body: m.notification?.body ?? m.data['body'] as String?,
      );

  /// Android does not show pushes while the app is open: show it ourselves.
  void _showForeground(RemoteMessage m) {
    final title = m.notification?.title ?? m.data['title'] as String?;
    if (title == null) return;
    LocalNotificationService().showNow(
      id: m.messageId.hashCode & 0x7fffffff,
      title: title,
      body: m.notification?.body ?? m.data['body'] as String? ?? '',
      payload: _payloadOf(m),
    );
  }

  /// A push that launched the app from a closed state (opened on the home screen).
  Future<String?> launchPayload() async {
    if (!_initialized) return null;
    try {
      final m = await FirebaseMessaging.instance.getInitialMessage();
      return m == null ? null : _payloadOf(m);
    } catch (e) {
      debugPrint('PushService.launchPayload: $e');
      return null;
    }
  }

  /// Registers this phone for [userId] after sign-in. Safe to call often.
  Future<void> registerFor(String userId, {SupabaseService? service}) async {
    if (!_initialized || _registeredUserId == userId) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token == null) return;
      final db = service ?? SupabaseService();
      await db.saveDeviceToken(token, platform: 'android');
      _registeredUserId = userId;
      await _tokenRefresh?.cancel();
      // ignore: deprecated_member_use
      _tokenRefresh = messaging.onTokenRefresh.listen((t) => db.saveDeviceToken(t, platform: 'android'));
    } catch (e) {
      // e.g. migration_push_fcm.sql not run yet: pushes simply don't arrive.
      debugPrint('PushService.registerFor: $e');
    }
  }

  /// On sign-out: this phone must stop receiving the previous account's pushes.
  Future<void> unregister({SupabaseService? service}) async {
    if (!_initialized) return;
    try {
      await _tokenRefresh?.cancel();
      _tokenRefresh = null;
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await (service ?? SupabaseService()).deleteDeviceToken(token);
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('PushService.unregister: $e');
    }
    _registeredUserId = null;
  }
}
