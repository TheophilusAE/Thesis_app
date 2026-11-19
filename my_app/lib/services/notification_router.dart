import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification.dart';
import '../screens/devotional_screen.dart';
import '../screens/event_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/public_schedule_screen.dart';
import '../screens/quest_screen.dart';
import '../screens/service_schedule_management_screen.dart';
import '../screens/substitution_request_screen.dart';

/// Navigator of the whole app, so a tap on a notification (in-app inbox,
/// local reminder or push) can open a page from anywhere.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Opens the page a notification points to ([NotificationRoute] names).
class NotificationRouter {
  /// Payload stored in local/push notifications: {"route": ..., "params": ...}.
  static String encodePayload(String route, {Map<String, dynamic>? params, String? title, String? body}) =>
      jsonEncode({
        'route': route,
        'params': ?params,
        'title': ?title,
        'body': ?body,
      });

  static ({String? route, Map<String, dynamic>? params, String? title, String? body}) decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return (route: null, params: null, title: null, body: null);
    try {
      final m = jsonDecode(payload);
      if (m is! Map) return (route: null, params: null, title: null, body: null);
      final p = m['params'];
      return (
        route: m['route'] as String?,
        params: p is Map ? Map<String, dynamic>.from(p) : null,
        title: m['title'] as String?,
        body: m['body'] as String?,
      );
    } catch (_) {
      // Older reminders had no payload or a plain route name.
      return (route: payload, params: null, title: null, body: null);
    }
  }

  /// Screen for [route], or null when the route is unknown / informational.
  static Widget? screenFor(String? route) => switch (route) {
        NotificationRoute.jadwalPelayan => const ServiceScheduleManagementScreen(),
        NotificationRoute.penggantian => const SubstitutionRequestScreen(),
        NotificationRoute.event => const EventListScreen(),
        NotificationRoute.jadwalIbadah => const PublicScheduleScreen(),
        NotificationRoute.profil => const ProfileScreen(),
        NotificationRoute.renungan => const DevotionalScreen(),
        NotificationRoute.quest => const QuestScreen(),
        _ => null,
      };

  /// Opens a notification from the inbox: its page, or (for announcements
  /// and anything without a page) a detail view with the full text.
  static Future<void> openNotification(AppNotification n, {NavigatorState? navigator}) async {
    final nav = navigator ?? appNavigatorKey.currentState;
    if (nav == null) return;
    final screen = screenFor(n.route);
    await nav.push(MaterialPageRoute(
      builder: (_) => screen ?? NotificationDetailScreen(title: n.title, message: n.message, createdAt: n.createdAt, category: n.category),
    ));
  }

  /// Opens a local/push notification payload (app in front or launched by the tap).
  static Future<void> openPayload(String? payload, {NavigatorState? navigator}) async {
    final nav = navigator ?? appNavigatorKey.currentState;
    final p = decodePayload(payload);
    if (nav == null || (p.route == null && p.title == null)) return;
    final screen = screenFor(p.route);
    if (screen == null && p.title == null) return;
    await nav.push(MaterialPageRoute(
      builder: (_) => screen ?? NotificationDetailScreen(title: p.title!, message: p.body ?? ''),
    ));
  }
}

/// Full text of an announcement or other notification without its own page.
class NotificationDetailScreen extends StatelessWidget {
  final String title;
  final String message;
  final DateTime? createdAt;
  final String? category;

  const NotificationDetailScreen({
    super.key,
    required this.title,
    required this.message,
    this.createdAt,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(category == null ? 'Notifikasi' : NotificationCategory.label(category!))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (createdAt != null) ...[
            const SizedBox(height: 6),
            Text(DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(createdAt!.toLocal()),
                style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          SelectableText(message, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
