import 'package:flutter/material.dart';

/// Notification categories (DB CHECK in migration_notifications_v2.sql).
class NotificationCategory {
  static const ibadah = 'ibadah';
  static const pelayanan = 'pelayanan';
  static const khusus = 'khusus';
  static const umum = 'umum';

  /// Order of the filter chips in the inbox.
  static const all = [ibadah, pelayanan, khusus, umum];

  static String label(String c) => switch (c) {
        ibadah => 'Ibadah',
        pelayanan => 'Pelayanan',
        khusus => 'Khusus',
        _ => 'Umum',
      };

  static IconData icon(String c) => switch (c) {
        ibadah => Icons.church_rounded,
        pelayanan => Icons.volunteer_activism_rounded,
        khusus => Icons.campaign_rounded,
        _ => Icons.notifications_rounded,
      };

  /// Category for rows written before the category column existed.
  static String fromType(String type) => switch (type) {
        'schedule' || 'training' || 'substitution' || 'service_reminder' || 'training_reminder' => pelayanan,
        'event' || 'birthday' || 'broadcast' => khusus,
        _ => umum,
      };
}

/// Pages a notification can open (see NotificationRouter).
class NotificationRoute {
  static const jadwalPelayan = 'jadwal_pelayan';
  static const penggantian = 'penggantian';
  static const event = 'event';
  static const jadwalIbadah = 'jadwal_ibadah';
  static const pengumuman = 'pengumuman';
  static const profil = 'profil';
  static const renungan = 'renungan';
  static const quest = 'quest';

  static String? fromType(String type) => switch (type) {
        'schedule' || 'training' || 'service_reminder' || 'training_reminder' => jadwalPelayan,
        'substitution' => penggantian,
        'event' => event,
        _ => null,
      };
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? relatedScheduleId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String category;
  final String? route;
  final Map<String, dynamic>? routeParams;
  final String? broadcastId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedScheduleId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    String? category,
    this.route,
    this.routeParams,
    this.broadcastId,
  }) : category = category ?? NotificationCategory.fromType(type);

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? 'general') as String;
    final params = json['route_params'];
    return AppNotification(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      type: type,
      relatedScheduleId: (json['related_schedule_id'] ?? json['relatedScheduleId']) as String?,
      isRead: (json['is_read'] ?? json['isRead'] ?? false) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      readAt: (json['read_at'] ?? json['readAt']) != null
          ? DateTime.parse((json['read_at'] ?? json['readAt']) as String)
          : null,
      // Before migration_notifications_v2 these columns don't exist: derive them.
      category: json['category'] as String? ?? NotificationCategory.fromType(type),
      route: json['route'] as String? ?? NotificationRoute.fromType(type),
      routeParams: params is Map ? Map<String, dynamic>.from(params) : null,
      broadcastId: json['broadcast_id'] as String?,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_schedule_id': relatedScheduleId,
      'is_read': isRead,
      'category': category,
      'route': route,
      'route_params': routeParams,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_schedule_id': relatedScheduleId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'category': category,
      'route': route,
      'route_params': routeParams,
      'broadcast_id': broadcastId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? relatedScheduleId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedScheduleId: relatedScheduleId ?? this.relatedScheduleId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      category: category,
      route: route,
      routeParams: routeParams,
      broadcastId: broadcastId,
    );
  }
}
