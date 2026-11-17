/// QR payload encode/decode for the member card check-in flow.
///
/// Format: `CHURCH_MEMBER|UID:<userId>|NAME:<url-encoded name>`. Kept
/// deliberately simple/plain-text (not signed) to match this app's existing
/// QR/schema conventions — anyone with the printed card can be checked in,
/// same trust model as a physical membership card.
class MemberQrPayload {
  final String userId;
  final String name;

  const MemberQrPayload({required this.userId, required this.name});
}

String encodeMemberPayload({required String userId, required String name}) {
  return 'CHURCH_MEMBER|UID:$userId|NAME:${Uri.encodeComponent(name)}';
}

/// Returns null when [raw] isn't a recognizable member payload (e.g. a
/// stray/unrelated QR code was scanned).
MemberQrPayload? decodeMemberPayload(String raw) {
  final segments = raw
      .split('|')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (segments.isEmpty || segments.first != 'CHURCH_MEMBER') {
    return null;
  }

  String? uid;
  String? name;
  for (final segment in segments.skip(1)) {
    final i = segment.indexOf(':');
    if (i <= 0 || i == segment.length - 1) continue;
    final key = segment.substring(0, i).trim().toUpperCase();
    final value = segment.substring(i + 1).trim();
    if (key == 'UID') uid = value;
    if (key == 'NAME') name = Uri.decodeComponent(value);
  }

  if (uid == null || uid.isEmpty) return null;
  return MemberQrPayload(userId: uid, name: name ?? '');
}

/// QR payload encode/decode for the jemaat-side event/ibadah self check-in
/// flow. Format: `CHURCH_SERVICE|SID:<serviceScheduleId>`. Displayed by an
/// admin/pelayan (e.g. projected during the service) and scanned by a jemaat
/// to self-check-in — distinct from [MemberQrPayload], which is scanned the
/// other way around (pelayan scans a jemaat's card).
class ServiceCheckinQrPayload {
  final String scheduleId;

  const ServiceCheckinQrPayload({required this.scheduleId});
}

String encodeServiceCheckinPayload({required String scheduleId}) {
  return 'CHURCH_SERVICE|SID:$scheduleId';
}

/// Returns null when [raw] isn't a recognizable service check-in payload.
ServiceCheckinQrPayload? decodeServiceCheckinPayload(String raw) {
  final segments = raw
      .split('|')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (segments.isEmpty || segments.first != 'CHURCH_SERVICE') {
    return null;
  }

  String? sid;
  for (final segment in segments.skip(1)) {
    final i = segment.indexOf(':');
    if (i <= 0 || i == segment.length - 1) continue;
    final key = segment.substring(0, i).trim().toUpperCase();
    final value = segment.substring(i + 1).trim();
    if (key == 'SID') sid = value;
  }

  if (sid == null || sid.isEmpty) return null;
  return ServiceCheckinQrPayload(scheduleId: sid);
}
