class FamilyMember {
  final String name;
  final String relationship;

  const FamilyMember({required this.name, required this.relationship});

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
        name: json['name'] as String,
        relationship: json['relationship'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'relationship': relationship};
}

/// Booking lifecycle: a booking reserves seats ([registered]); attendance
/// is only counted after a QR check-in ([attended]). Cancelling keeps the
/// row for history ([cancelled]).
class RegistrationStatus {
  RegistrationStatus._();
  static const registered = 'registered';
  static const attended = 'attended';
  static const cancelled = 'cancelled';

  static String label(String status) {
    switch (status) {
      case attended:
        return 'Hadir (sudah check-in)';
      case cancelled:
        return 'Dibatalkan';
      default:
        return 'Terdaftar (belum check-in)';
    }
  }
}

class EventRegistration {
  final String id;
  final String eventId;
  final String userId;
  final List<FamilyMember> familyMembers;
  final int totalCount;
  final String? notes;
  final DateTime registeredAt;
  final String status;
  final DateTime? checkedInAt;

  // Populated via join (admin view)
  final String? userName;
  final String? userEmail;

  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.familyMembers,
    required this.totalCount,
    this.notes,
    required this.registeredAt,
    this.status = RegistrationStatus.registered,
    this.checkedInAt,
    this.userName,
    this.userEmail,
  });

  bool get isActive => status != RegistrationStatus.cancelled;
  bool get isAttended => status == RegistrationStatus.attended;

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    final raw = json['family_members'];
    final members = <FamilyMember>[];
    if (raw is List) {
      for (final m in raw) {
        if (m is Map<String, dynamic>) members.add(FamilyMember.fromJson(m));
      }
    }
    final userMap = json['users'];
    return EventRegistration(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      familyMembers: members,
      totalCount: (json['total_count'] as int?) ?? (1 + members.length),
      notes: json['notes'] as String?,
      registeredAt: DateTime.parse(json['registered_at'] as String).toLocal(),
      status: (json['status'] as String?) ?? RegistrationStatus.registered,
      checkedInAt: json['checked_in_at'] == null
          ? null
          : DateTime.parse(json['checked_in_at'] as String).toLocal(),
      userName: userMap is Map ? userMap['nama'] as String? : null,
      userEmail: userMap is Map ? userMap['email'] as String? : null,
    );
  }
}
