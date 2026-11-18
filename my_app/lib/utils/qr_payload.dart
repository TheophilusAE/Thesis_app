/// QR payload formats.
///
/// 1. Member card (shown by a jemaat, scanned by a pelayan/admin):
///    `CHURCH_MEMBER|UID:<userId>|K:<secret>|NAME:<url-encoded name>`
///    The per-member secret (`member_qr_secrets`, via
///    `get_my_member_qr_secret()`) means a valid card QR can't be built from
///    a user id alone; the database verifies it in `staff_check_in()`.
///
/// 2. Check-in code (shown by a pelayan/admin, scanned by a jemaat):
///    `CHURCH_CHECKIN|T:<occurrence|event>|ID:<targetId>|K:<token>`
///    The token comes from `issue_checkin_token()` and is only valid for that
///    one worship date / event and inside its time window, so a QR from
///    another service, an old photo after the day, or a hand-made code is
///    rejected by `self_check_in()`.
///
/// The old unsigned service QR (`CHURCH_SERVICE|SID:...`) is still
/// recognized only to tell the user it is no longer accepted.
library;

class MemberQrPayload {
  final String userId;
  final String name;
  /// Null for a legacy card QR made before the secret existed.
  final String? secret;

  const MemberQrPayload({required this.userId, required this.name, this.secret});

  bool get isLegacy => secret == null || secret!.isEmpty;
}

Map<String, String>? _segments(String raw, String prefix) {
  final parts = raw
      .split('|')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty || parts.first != prefix) return null;
  final map = <String, String>{};
  for (final segment in parts.skip(1)) {
    final i = segment.indexOf(':');
    if (i <= 0 || i == segment.length - 1) continue;
    map[segment.substring(0, i).trim().toUpperCase()] = segment.substring(i + 1).trim();
  }
  return map;
}

String encodeMemberPayload({
  required String userId,
  required String name,
  String? secret,
}) {
  final k = (secret == null || secret.isEmpty) ? '' : '|K:$secret';
  return 'CHURCH_MEMBER|UID:$userId$k|NAME:${Uri.encodeComponent(name)}';
}

/// Returns null when [raw] isn't a recognizable member payload (e.g. a
/// stray/unrelated QR code was scanned).
MemberQrPayload? decodeMemberPayload(String raw) {
  final seg = _segments(raw, 'CHURCH_MEMBER');
  if (seg == null) return null;
  final uid = seg['UID'];
  if (uid == null || uid.isEmpty) return null;
  final name = seg['NAME'];
  return MemberQrPayload(
    userId: uid,
    name: name == null ? '' : Uri.decodeComponent(name),
    secret: seg['K'],
  );
}

/// What a check-in code points at.
class CheckinTarget {
  CheckinTarget._();
  static const occurrence = 'occurrence';
  static const event = 'event';
  static const all = {occurrence, event};
}

class CheckinQrPayload {
  final String targetType;
  final String targetId;
  final String token;

  const CheckinQrPayload({
    required this.targetType,
    required this.targetId,
    required this.token,
  });
}

String encodeCheckinPayload({
  required String targetType,
  required String targetId,
  required String token,
}) {
  return 'CHURCH_CHECKIN|T:$targetType|ID:$targetId|K:$token';
}

CheckinQrPayload? decodeCheckinPayload(String raw) {
  final seg = _segments(raw, 'CHURCH_CHECKIN');
  if (seg == null) return null;
  final type = seg['T']?.toLowerCase();
  final id = seg['ID'];
  final token = seg['K'];
  if (type == null || !CheckinTarget.all.contains(type)) return null;
  if (id == null || id.isEmpty || token == null || token.isEmpty) return null;
  return CheckinQrPayload(targetType: type, targetId: id, token: token);
}

/// True for the retired unsigned service QR (`CHURCH_SERVICE|SID:...`).
bool isLegacyServicePayload(String raw) => _segments(raw, 'CHURCH_SERVICE') != null;
