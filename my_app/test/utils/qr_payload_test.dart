import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/qr_payload.dart';

void main() {
  group('encodeMemberPayload / decodeMemberPayload', () {
    test('round trips a simple name', () {
      final raw = encodeMemberPayload(userId: 'user-123', name: 'Budi Santoso');
      final decoded = decodeMemberPayload(raw);

      expect(decoded, isNotNull);
      expect(decoded!.userId, 'user-123');
      expect(decoded.name, 'Budi Santoso');
    });

    test('round trips a name containing the "|" delimiter and unicode', () {
      final raw = encodeMemberPayload(userId: 'user-456', name: 'Siti | Ösé');
      final decoded = decodeMemberPayload(raw);

      expect(decoded, isNotNull);
      expect(decoded!.userId, 'user-456');
      expect(decoded.name, 'Siti | Ösé');
    });

    test('returns null for a malformed payload', () {
      expect(decodeMemberPayload('not a church qr'), isNull);
      expect(decodeMemberPayload(''), isNull);
      expect(decodeMemberPayload('CHURCH_EVENT|EID:1|EVENT:x'), isNull);
    });

    test('returns null when UID segment is missing', () {
      expect(decodeMemberPayload('CHURCH_MEMBER|NAME:Budi'), isNull);
    });

    test('defaults name to empty string when NAME segment is missing', () {
      final decoded = decodeMemberPayload('CHURCH_MEMBER|UID:abc');
      expect(decoded, isNotNull);
      expect(decoded!.userId, 'abc');
      expect(decoded.name, '');
    });
  });

  group('encodeServiceCheckinPayload / decodeServiceCheckinPayload', () {
    test('round trips a schedule id', () {
      final raw = encodeServiceCheckinPayload(scheduleId: 'sched-42');
      expect(raw, 'CHURCH_SERVICE|SID:sched-42');
      expect(decodeServiceCheckinPayload(raw)!.scheduleId, 'sched-42');
    });

    test('ignores whitespace and key case', () {
      expect(decodeServiceCheckinPayload(' CHURCH_SERVICE | sid: abc ')!.scheduleId, 'abc');
    });

    test('rejects a member-card payload (different QR direction)', () {
      expect(decodeServiceCheckinPayload('CHURCH_MEMBER|UID:u1|NAME:Budi'), isNull);
    });

    test('rejects malformed or empty payloads', () {
      expect(decodeServiceCheckinPayload(''), isNull);
      expect(decodeServiceCheckinPayload('CHURCH_SERVICE'), isNull);
      expect(decodeServiceCheckinPayload('CHURCH_SERVICE|SID:'), isNull);
    });
  });
}
