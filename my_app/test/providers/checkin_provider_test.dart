import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/providers/checkin_provider.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:my_app/utils/qr_payload.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class _MockService extends Mock implements SupabaseService {}

void main() {
  late _MockService service;
  late CheckinProvider provider;

  setUp(() {
    service = _MockService();
    provider = CheckinProvider(service: service);
  });

  group('self check-in (jemaat scans the displayed code)', () {
    test('a valid code is sent with its token and the result is reported', () async {
      when(() => service.selfCheckIn(any(), any(), any())).thenAnswer(
          (_) async => {'status': 'checked_in', 'label': 'Ibadah Raya', 'nama': 'Budi'});

      final r = await provider.selfCheckIn(
          encodeCheckinPayload(targetType: CheckinTarget.occurrence, targetId: 'occ-1', token: 'tok'));

      expect(r.ok, isTrue);
      expect(r.alreadyCheckedIn, isFalse);
      expect(r.label, 'Ibadah Raya');
      verify(() => service.selfCheckIn('occurrence', 'occ-1', 'tok')).called(1);
    });

    test('a second scan is reported as already recorded', () async {
      when(() => service.selfCheckIn(any(), any(), any()))
          .thenAnswer((_) async => {'status': 'already', 'label': 'Ibadah Raya'});

      final r = await provider.selfCheckIn('CHURCH_CHECKIN|T:occurrence|ID:occ-1|K:tok');

      expect(r.ok, isTrue);
      expect(r.alreadyCheckedIn, isTrue);
    });

    test('the retired unsigned service QR is refused without calling the server', () async {
      final r = await provider.selfCheckIn('CHURCH_SERVICE|SID:sched-1');
      expect(r.ok, isFalse);
      expect(r.error, contains('model lama'));
      verifyNever(() => service.selfCheckIn(any(), any(), any()));
    });

    test('a member card or random QR is not accepted as a check-in code', () async {
      expect((await provider.selfCheckIn('CHURCH_MEMBER|UID:u|K:s|NAME:x')).ok, isFalse);
      expect((await provider.selfCheckIn('https://example.com')).ok, isFalse);
      verifyNever(() => service.selfCheckIn(any(), any(), any()));
    });

    test('database refusals (wrong event, expired, not booked) are shown as written', () async {
      when(() => service.selfCheckIn(any(), any(), any())).thenThrow(const PostgrestException(
          message: 'Budi belum terdaftar untuk event ini. Daftar terlebih dahulu.', code: '22023'));

      final r = await provider.selfCheckIn('CHURCH_CHECKIN|T:event|ID:ev|K:tok');

      expect(r.ok, isFalse);
      expect(r.error, 'Budi belum terdaftar untuk event ini. Daftar terlebih dahulu.');
    });
  });

  group('staff check-in (pelayan scans a member card)', () {
    test('sends the member id and card secret for the chosen target', () async {
      when(() => service.staffCheckIn(
            targetType: any(named: 'targetType'),
            targetId: any(named: 'targetId'),
            userId: any(named: 'userId'),
            secret: any(named: 'secret'),
          )).thenAnswer((_) async => {'status': 'checked_in', 'nama': 'Siti'});

      final r = await provider.staffCheckIn(
        targetType: CheckinTarget.event,
        targetId: 'ev-1',
        rawQr: encodeMemberPayload(userId: 'u-9', name: 'Siti', secret: 'sec'),
      );

      expect(r.ok, isTrue);
      expect(r.memberName, 'Siti');
      verify(() => service.staffCheckIn(targetType: 'event', targetId: 'ev-1', userId: 'u-9', secret: 'sec'))
          .called(1);
    });

    test('a legacy card without secret is refused (can be forged from an id)', () async {
      final r = await provider.staffCheckIn(
        targetType: CheckinTarget.occurrence,
        targetId: 'occ-1',
        rawQr: 'CHURCH_MEMBER|UID:u-9|NAME:Siti',
      );
      expect(r.ok, isFalse);
      expect(r.error, contains('model lama'));
    });
  });

  test('the member card secret is fetched once and cleared on sign-out', () async {
    when(() => service.getMyMemberQrSecret()).thenAnswer((_) async => 'sec1');

    final a = await provider.memberQrData(userId: 'u1', name: 'Budi');
    await provider.memberQrData(userId: 'u1', name: 'Budi');
    verify(() => service.getMyMemberQrSecret()).called(1);
    expect(decodeMemberPayload(a)!.secret, 'sec1');

    provider.clear();
    await provider.memberQrData(userId: 'u1', name: 'Budi');
    verify(() => service.getMyMemberQrSecret()).called(1);
  });

  test('issued code carries the token and expiry', () async {
    when(() => service.issueCheckinToken(any(), any())).thenAnswer((_) async => {
          'token': 'abc',
          'valid_until': '2026-11-22T16:00:00Z',
          'label': 'Ibadah Raya',
        });

    final code = await provider.issueCode(CheckinTarget.occurrence, 'occ-1');

    expect(decodeCheckinPayload(code.qrData)!.token, 'abc');
    expect(code.label, 'Ibadah Raya');
    expect(code.validUntil.toUtc(), DateTime.utc(2026, 11, 22, 16));
  });
}
