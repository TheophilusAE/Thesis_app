import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/providers/checkin_provider.dart';
import 'package:my_app/screens/qr_shortcut_screen.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockService extends Mock implements SupabaseService {}

Future<AuthProvider> _signedIn(_MockService service, List<String> roles) async {
  when(() => service.getCurrentUser()).thenReturn(const sb.User(
    id: 'u1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  ));
  when(() => service.getUserProfile('u1')).thenAnswer((_) async => {
        'id': 'u1',
        'nama': 'Rina',
        'email': 'rina@example.com',
        'phone': '0813',
        'roles': roles,
        'membership_status': 'active',
      });
  when(() => service.getMyAdminPermissions('u1')).thenAnswer((_) async => []);
  final auth = AuthProvider(service: service);
  await auth.checkAuthStatus();
  return auth;
}

void main() {
  test('jemaat scans service/event codes; staff scan member cards', () async {
    final jemaat = await _signedIn(_MockService(), ['jemaat']);
    expect(qrScanModeFor(jemaat), QrScanMode.selfCheckIn);

    final superAdmin = await _signedIn(_MockService(), ['super_admin', 'admin', 'jemaat']);
    superAdmin.switchRole('admin');
    expect(qrScanModeFor(superAdmin), QrScanMode.staff);

    final pelayan = await _signedIn(_MockService(), ['pelayan', 'jemaat']);
    pelayan.switchRole('pelayan');
    expect(qrScanModeFor(pelayan), QrScanMode.staff);

    // An admin without the attendance permission cannot scan members.
    final admin = await _signedIn(_MockService(), ['admin', 'jemaat']);
    admin.switchRole('admin');
    expect(qrScanModeFor(admin), QrScanMode.selfCheckIn);
  });

  testWidgets('the sheet shows the member QR large with a Scan QR button', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = _MockService();
    final auth = await _signedIn(service, ['jemaat']);
    when(() => service.getMyMemberQrSecret()).thenAnswer((_) async => 'sec');

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => CheckinProvider(service: service)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () => showQrAccessSheet(context), child: const Text('qr')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('qr'));
    await tester.pumpAndSettle();

    expect(find.text('QR Saya'), findsOneWidget);
    expect(find.text('Kode QR Anda'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.getSize(find.byType(QrImageView)).width, greaterThanOrEqualTo(200));

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('QR Saya'), findsNothing);
  });
}
