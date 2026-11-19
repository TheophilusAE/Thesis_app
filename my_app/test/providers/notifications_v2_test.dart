import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_app/models/broadcast.dart';
import 'package:my_app/models/notification.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/providers/broadcast_provider.dart';
import 'package:my_app/providers/notification_provider.dart';
import 'package:my_app/services/notification_router.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:my_app/widgets/notification_inbox.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class _MockService extends Mock implements SupabaseService {}

Map<String, dynamic> _row(String id, String type, {String? category, bool read = false}) => {
      'id': id,
      'user_id': 'u1',
      'title': 'Judul $id',
      'message': 'Isi $id',
      'type': type,
      'is_read': read,
      'created_at': '2026-11-18T01:00:00Z',
      'category': ?category,
    };

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('AppNotification', () {
    test('rows from before the migration get a category and page from their type', () {
      final duty = AppNotification.fromJson(_row('1', 'schedule'));
      expect(duty.category, NotificationCategory.pelayanan);
      expect(duty.route, NotificationRoute.jadwalPelayan);

      final event = AppNotification.fromJson(_row('2', 'event'));
      expect(event.category, NotificationCategory.khusus);
      expect(event.route, NotificationRoute.event);

      expect(AppNotification.fromJson(_row('3', 'general')).category, NotificationCategory.umum);
    });

    test('stored category and route win over the type', () {
      final n = AppNotification.fromJson({
        ..._row('4', 'broadcast', category: 'ibadah'),
        'route': 'jadwal_ibadah',
        'route_params': {'id': 'b1'},
        'broadcast_id': 'b1',
      });
      expect(n.category, 'ibadah');
      expect(n.route, 'jadwal_ibadah');
      expect(n.routeParams, {'id': 'b1'});
      expect(n.broadcastId, 'b1');
      expect(n.copyWith(isRead: true).category, 'ibadah');
    });
  });

  group('NotificationRouter payload', () {
    test('round-trips route, params and text', () {
      final p = NotificationRouter.decodePayload(NotificationRouter.encodePayload(
        NotificationRoute.event,
        params: {'id': 'e1'},
        title: 'T',
        body: 'B',
      ));
      expect(p.route, 'event');
      expect(p.params, {'id': 'e1'});
      expect(p.title, 'T');
      expect(p.body, 'B');
    });

    test('empty or plain payloads are handled', () {
      expect(NotificationRouter.decodePayload(null).route, isNull);
      expect(NotificationRouter.decodePayload('quest').route, 'quest');
    });

    test('known routes map to a page, announcements show their text', () {
      expect(NotificationRouter.screenFor(NotificationRoute.event), isNotNull);
      expect(NotificationRouter.screenFor(NotificationRoute.jadwalPelayan), isNotNull);
      expect(NotificationRouter.screenFor(NotificationRoute.pengumuman), isNull);
      expect(NotificationRouter.screenFor(null), isNull);
    });
  });

  group('NotificationProvider.notifyUsers', () {
    late _MockService service;
    late NotificationProvider provider;

    setUp(() {
      service = _MockService();
      provider = NotificationProvider(service: service);
      registerFallbackValue(<Map<String, dynamic>>[]);
    });

    test('sends category and page with each row', () async {
      when(() => service.addNotifications(any())).thenAnswer((_) async {});

      final ok = await provider.notifyUsers(userIds: ['a', 'b', ''], title: 'T', message: 'M', type: 'event');

      expect(ok, isTrue);
      final rows = verify(() => service.addNotifications(captureAny())).captured.single as List<Map<String, dynamic>>;
      expect(rows.map((r) => r['user_id']), ['a', 'b']);
      expect(rows.first['category'], 'khusus');
      expect(rows.first['route'], 'event');
    });

    test('before migration_notifications_v2 it retries without the new columns', () async {
      var calls = 0;
      when(() => service.addNotifications(any())).thenAnswer((inv) async {
        calls++;
        final rows = inv.positionalArguments.first as List<Map<String, dynamic>>;
        if (rows.first.containsKey('category')) {
          throw const PostgrestException(message: "Could not find the 'category' column", code: 'PGRST204');
        }
      });

      final ok = await provider.notifyUsers(userIds: ['a'], title: 'T', message: 'M', type: 'schedule');

      expect(ok, isTrue);
      expect(calls, 2);
    });
  });

  group('BroadcastProvider', () {
    late _MockService service;
    late BroadcastProvider provider;

    setUp(() {
      service = _MockService();
      provider = BroadcastProvider(service: service);
      registerFallbackValue(<String, dynamic>{});
    });

    test('validation runs before calling the server', () async {
      final (error, _) = await provider.create(title: ' ', message: 'x', category: 'khusus', audience: 'semua');
      expect(error, isNotNull);
      verifyNever(() => service.createBroadcast(any()));
    });

    test('create sends the announcement and reports recipients', () async {
      when(() => service.createBroadcast(any())).thenAnswer((_) async => {'id': 'b1', 'recipients': 42});
      when(() => service.getBroadcasts(activeOnly: any(named: 'activeOnly'))).thenAnswer((_) async => [
            {'id': 'b1', 'title': 'Retreat', 'message': 'Info', 'category': 'khusus', 'audience': 'semua',
             'is_active': true, 'created_at': '2026-11-18T01:00:00Z'},
          ]);

      final (error, recipients) = await provider.create(
          title: ' Retreat ', message: 'Info', category: 'khusus', audience: BroadcastAudience.jemaat, route: 'event');

      expect(error, isNull);
      expect(recipients, 42);
      final sent = verify(() => service.createBroadcast(captureAny())).captured.single as Map<String, dynamic>;
      expect(sent, {'title': 'Retreat', 'message': 'Info', 'category': 'khusus', 'audience': 'jemaat', 'route': 'event'});
      expect(provider.items.single.title, 'Retreat');
    });

    test('a missing table is reported as "feature not active", not as an error', () async {
      when(() => service.getBroadcasts(activeOnly: any(named: 'activeOnly')))
          .thenThrow(const PostgrestException(message: 'not found', code: 'PGRST205'));

      await provider.load();

      expect(provider.featureMissing, isTrue);
      expect(provider.error, isNull);
      expect(provider.active, isEmpty);
    });

    test('clean-up refuses less than 30 days without calling the server', () async {
      final (error, _) = await provider.purgeOlderThan(7);
      expect(error, isNotNull);
      verifyNever(() => service.purgeOldNotifications(any()));
    });

    test('birthday greetings report who was greeted', () async {
      when(() => service.sendBirthdayGreetings()).thenAnswer((_) async => {'sent': 2, 'names': ['Ani', 'Budi']});
      when(() => service.getBirthdaysToday()).thenAnswer((_) async => [
            {'user_id': 'a', 'nama': 'Ani', 'already_greeted': true},
          ]);

      final (error, names) = await provider.sendBirthdayGreetings();

      expect(error, isNull);
      expect(names, ['Ani', 'Budi']);
      expect(provider.birthdays.single.alreadyGreeted, isTrue);
    });
  });

  testWidgets('inbox filters by category', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _MockService();
    when(() => service.getNotifications('u1')).thenAnswer((_) async => [
          _row('1', 'schedule'),
          _row('2', 'event'),
          _row('3', 'broadcast', category: 'ibadah', read: true),
        ]);
    final np = NotificationProvider(service: service);
    await np.loadNotifications('u1');

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: np),
        ChangeNotifierProvider(create: (_) => AuthProvider(service: service)),
      ],
      child: const MaterialApp(home: Scaffold(body: NotificationInbox(userId: 'u1'))),
    ));
    await tester.pump();

    expect(find.text('Judul 1'), findsOneWidget);
    expect(find.text('Judul 2'), findsOneWidget);
    expect(find.text('Judul 3'), findsOneWidget);

    await tester.ensureVisible(find.text('Pelayanan (1)'));
    await tester.tap(find.text('Pelayanan (1)'));
    await tester.pump();
    expect(find.text('Judul 1'), findsOneWidget);
    expect(find.text('Judul 2'), findsNothing);

    await tester.ensureVisible(find.text('Umum'));
    await tester.tap(find.text('Umum'));
    await tester.pump();
    expect(find.text('Belum ada notifikasi Umum'), findsOneWidget);
  });
}
