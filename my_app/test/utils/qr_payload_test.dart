import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/qr_payload.dart';

void main() {
  group('member card QR', () {
    test('round trips id, secret and a simple name', () {
      final raw = encodeMemberPayload(userId: 'user-123', name: 'Budi Santoso', secret: 'abc999');
      final decoded = decodeMemberPayload(raw);

      expect(decoded, isNotNull);
      expect(decoded!.userId, 'user-123');
      expect(decoded.name, 'Budi Santoso');
      expect(decoded.secret, 'abc999');
      expect(decoded.isLegacy, isFalse);
    });

    test('round trips a name containing the "|" delimiter and unicode', () {
      final raw = encodeMemberPayload(userId: 'user-456', name: 'Siti | Ösé', secret: 's1');
      final decoded = decodeMemberPayload(raw);

      expect(decoded, isNotNull);
      expect(decoded!.userId, 'user-456');
      expect(decoded.name, 'Siti | Ösé');
    });

    test('a card without secret is decoded but flagged as legacy', () {
      final decoded = decodeMemberPayload('CHURCH_MEMBER|UID:abc|NAME:Budi');
      expect(decoded!.userId, 'abc');
      expect(decoded.isLegacy, isTrue);
    });

    test('returns null for malformed payloads', () {
      expect(decodeMemberPayload('not a church qr'), isNull);
      expect(decodeMemberPayload(''), isNull);
      expect(decodeMemberPayload('CHURCH_CHECKIN|T:event|ID:1|K:x'), isNull);
      expect(decodeMemberPayload('CHURCH_MEMBER|NAME:Budi'), isNull);
    });

    test('defaults name to empty string when NAME segment is missing', () {
      final decoded = decodeMemberPayload('CHURCH_MEMBER|UID:abc|K:z');
      expect(decoded!.name, '');
    });
  });

  group('check-in QR', () {
    test('round trips an occurrence code', () {
      final raw = encodeCheckinPayload(targetType: CheckinTarget.occurrence, targetId: 'occ-1', token: 'tok');
      expect(raw, 'CHURCH_CHECKIN|T:occurrence|ID:occ-1|K:tok');
      final d = decodeCheckinPayload(raw)!;
      expect(d.targetType, 'occurrence');
      expect(d.targetId, 'occ-1');
      expect(d.token, 'tok');
    });

    test('round trips an event code and ignores whitespace / key case', () {
      final d = decodeCheckinPayload(' CHURCH_CHECKIN | t: EVENT | id: ev-9 | k: abc ')!;
      expect(d.targetType, 'event');
      expect(d.targetId, 'ev-9');
      expect(d.token, 'abc');
    });

    test('rejects codes without a token, with an unknown type, or member cards', () {
      expect(decodeCheckinPayload('CHURCH_CHECKIN|T:event|ID:ev-9'), isNull);
      expect(decodeCheckinPayload('CHURCH_CHECKIN|T:party|ID:x|K:y'), isNull);
      expect(decodeCheckinPayload('CHURCH_MEMBER|UID:u1|K:s|NAME:Budi'), isNull);
      expect(decodeCheckinPayload(''), isNull);
    });

    test('the retired unsigned service QR is recognized only as legacy', () {
      expect(isLegacyServicePayload('CHURCH_SERVICE|SID:sched-42'), isTrue);
      expect(decodeCheckinPayload('CHURCH_SERVICE|SID:sched-42'), isNull);
      expect(isLegacyServicePayload('CHURCH_CHECKIN|T:event|ID:x|K:y'), isFalse);
    });
  });
}
