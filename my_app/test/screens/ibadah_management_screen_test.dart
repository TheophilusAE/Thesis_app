import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/providers/ibadah_provider.dart';
import 'package:my_app/screens/ibadah_management_screen.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockService extends Mock implements SupabaseService {}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> openScreen(WidgetTester tester, List<Map<String, dynamic>> rows) async {
    final service = _MockService();
    when(() => service.getCurrentUser()).thenReturn(const sb.User(
      id: 'u1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ));
    when(() => service.getUserProfile('u1')).thenAnswer((_) async => {
          'id': 'u1',
          'nama': 'Super',
          'email': 's@example.com',
          'phone': '0813',
          'roles': ['super_admin', 'admin', 'jemaat'],
          'membership_status': 'active',
        });
    // Slow network: the first load finishes while the page is still sliding in.
    when(() => service.getIbadahOccurrences(any(), any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return rows;
    });
    when(() => service.getIbadahSeries()).thenAnswer((_) async => []);

    final auth = AuthProvider(service: service);
    await auth.checkAuthStatus();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => IbadahProvider(service: service)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IbadahManagementScreen()),
                ),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('first open with no schedules shows the empty state without errors', (tester) async {
    await openScreen(tester, const []);

    expect(tester.takeException(), isNull);
    expect(find.text('Belum ada jadwal ibadah'), findsOneWidget);
    expect(find.text('Tambah Jadwal'), findsOneWidget);
  });

  testWidgets('first open with schedules lists them with their actions', (tester) async {
    final today = DateTime.now();
    final d = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await openScreen(tester, [
      {
        'occurrence_id': 'o1',
        'series_id': 's1',
        'tanggal': d,
        'start_time': '07:00',
        'end_time': '09:00',
        'nama': 'Ibadah Raya',
        'jenis': 'Ibadah Umum',
        'lokasi': 'Gedung Utama',
        'pola': 'weekly',
        'status': 'scheduled',
        'is_active': true,
      },
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Ibadah Raya'), findsOneWidget);
    expect(find.text('QR Presensi'), findsOneWidget);
    expect(find.text('Tugaskan Pelayan'), findsOneWidget);
  });
}
