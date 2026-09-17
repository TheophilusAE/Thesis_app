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
}
