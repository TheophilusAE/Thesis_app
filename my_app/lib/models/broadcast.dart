import 'notification.dart';

/// Who receives an announcement (DB CHECK in migration_notifications_v2.sql).
class BroadcastAudience {
  static const semua = 'semua';
  static const jemaat = 'jemaat';
  static const pelayan = 'pelayan';
  static const admin = 'admin';
  static const all = [semua, jemaat, pelayan, admin];

  static String label(String a) => switch (a) {
        jemaat => 'Jemaat',
        pelayan => 'Pelayan',
        admin => 'Admin',
        _ => 'Semua anggota',
      };
}

/// An editable announcement ("Pengumuman") sent to members' inboxes.
class Broadcast {
  final String id;
  final String title;
  final String message;
  final String category;
  final String audience;
  final String? route;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Broadcast({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.audience,
    this.route,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Broadcast.fromJson(Map<String, dynamic> j) => Broadcast(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        message: (j['message'] ?? '') as String,
        category: (j['category'] ?? NotificationCategory.khusus) as String,
        audience: (j['audience'] ?? BroadcastAudience.semua) as String,
        route: j['route'] as String?,
        isActive: (j['is_active'] ?? true) as bool,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: j['updated_at'] == null ? null : DateTime.parse(j['updated_at'] as String),
      );

  bool get wasEdited => updatedAt != null && updatedAt!.difference(createdAt).inSeconds > 5;
}

/// A member whose birthday is today (from `birthdays_today()`).
class BirthdayPerson {
  final String userId;
  final String nama;
  final bool alreadyGreeted;

  const BirthdayPerson(this.userId, this.nama, this.alreadyGreeted);

  factory BirthdayPerson.fromJson(Map<String, dynamic> j) =>
      BirthdayPerson(j['user_id'] as String, (j['nama'] ?? '') as String, (j['already_greeted'] ?? false) as bool);
}
