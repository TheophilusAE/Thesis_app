import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/providers/notification_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService service;
  late NotificationProvider provider;

  setUpAll(() => registerFallbackValue(<Map<String, dynamic>>[]));

  setUp(() {
    service = MockSupabaseService();
    provider = NotificationProvider(service: service);
  });

  test('notifyUsers sends one bulk insert with one row per distinct user', () async {
    when(() => service.addNotifications(any())).thenAnswer((_) async {});

    final ok = await provider.notifyUsers(
      userIds: ['u1', 'u2', 'u1', ''],
      title: 'Jadwal Baru',
      message: 'Anda bertugas',
      type: 'schedule',
      relatedScheduleId: 's1',
    );

    expect(ok, isTrue);
    final rows = verify(() => service.addNotifications(captureAny())).captured.single
        as List<Map<String, dynamic>>;
    expect(rows.map((r) => r['user_id']), unorderedEquals(['u1', 'u2']));
    for (final r in rows) {
      expect(r['title'], 'Jadwal Baru');
      expect(r['type'], 'schedule');
      expect(r['related_schedule_id'], 's1');
      expect(r['is_read'], isFalse);
    }
  });

  test('notifications addressed to other users never appear in this device\'s inbox', () async {
    when(() => service.addNotifications(any())).thenAnswer((_) async {});

    await provider.notifyUsers(userIds: ['other'], title: 't', message: 'm', type: 'event');

    expect(provider.allNotifications, isEmpty);
    expect(provider.unreadCount, 0);
  });

  test('an empty recipient list is a no-op, not an error', () async {
    final ok = await provider.notifyUsers(userIds: const [], title: 't', message: 'm', type: 'event');
    expect(ok, isTrue);
    verifyNever(() => service.addNotifications(any()));
  });

  test('a failed insert is reported as false', () async {
    when(() => service.addNotifications(any())).thenThrow(Exception('rls'));
    final ok = await provider.notifyUsers(userIds: ['u1'], title: 't', message: 'm', type: 'event');
    expect(ok, isFalse);
  });

  test('loading another user\'s inbox discards the previous user\'s notifications', () async {
    when(() => service.getNotifications('a')).thenAnswer((_) async => [
          {
            'id': 'n1',
            'user_id': 'a',
            'title': 'A',
            'message': 'm',
            'is_read': false,
            'created_at': '2026-06-01T00:00:00.000Z',
          },
        ]);
    when(() => service.getNotifications('b')).thenAnswer((_) async => []);

    await provider.loadNotifications('a');
    expect(provider.allNotifications, hasLength(1));
    expect(provider.unreadCount, 1);

    await provider.loadNotifications('b');
    expect(provider.allNotifications, isEmpty);
    expect(provider.unreadCount, 0);
  });
}
