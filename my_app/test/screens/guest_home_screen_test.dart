import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/models/public_service.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/screens/guest_home_screen.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/services/supabase_service.dart';

class _MockService extends Mock implements SupabaseService {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> pumpGuest(
    WidgetTester tester, {
    required Future<List<PublicServiceSlot>> Function(DateTime, DateTime) loader,
  }) async {
    SharedPreferences.setMockInitialValues({});
    // Tall phone-width viewport so the whole home page is laid out and no
    // tap lands on the bottom navigation bar by accident.
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: AuthProvider(service: _MockService()),
        child: MaterialApp(home: GuestHomeScreen(scheduleLoader: loader)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('guest home shows public content and a way to sign in', (tester) async {
    final today = DateTime.now();
    await pumpGuest(tester, loader: (_, _) async => [
          PublicServiceSlot(
            serviceType: 'Ibadah Raya',
            date: DateTime(today.year, today.month, today.day).add(const Duration(days: 1)),
            startTime: '07:00',
            endTime: '09:00',
          ),
        ]);

    expect(find.text('GPdI Persadamas Banjarmasin'), findsOneWidget);
    expect(find.text('Renungan Harian'), findsOneWidget);
    expect(find.text('Event Gereja'), findsOneWidget);
    expect(find.text('Ibadah Raya'), findsOneWidget);
    // No pelayan names are ever part of the public slot.
    expect(find.textContaining('Pelayan:'), findsNothing);
  });

  testWidgets('personal features ask the guest to sign in', (tester) async {
    await pumpGuest(tester, loader: (_, _) async => []);

    await tester.tap(find.text('Kartu Jemaat & QR Kehadiran'));
    await tester.pumpAndSettle();

    expect(find.text('Perlu Akun Jemaat'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Masuk'),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    // Opened from guest mode, so the login screen offers a way back.
    expect(find.byTooltip('Kembali sebagai tamu'), findsOneWidget);
  });

  testWidgets('a failed schedule load shows a message, not a crash', (tester) async {
    await pumpGuest(tester, loader: (_, _) async => throw Exception('offline'));

    expect(find.textContaining('belum dapat dimuat'), findsOneWidget);
  });

  testWidgets('the Jadwal tab lists the next services grouped by day', (tester) async {
    final day = DateTime.now().add(const Duration(days: 3));
    await pumpGuest(tester, loader: (_, _) async => [
          PublicServiceSlot(
            serviceType: 'Ibadah Pemuda',
            date: DateTime(day.year, day.month, day.day),
            startTime: '18:00',
            endTime: '20:00',
          ),
        ]);

    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Ibadah'), findsOneWidget);
    expect(find.text('Ibadah Pemuda'), findsOneWidget);
    expect(find.text('18:00 – 20:00'), findsOneWidget);
  });
}
