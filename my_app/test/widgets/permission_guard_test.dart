import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:my_app/utils/permissions.dart';
import 'package:my_app/widgets/permission_guard.dart';

class _MockService extends Mock implements SupabaseService {}

Future<AuthProvider> _signedIn(List<String> roles, {List<Map<String, dynamic>> grants = const []}) async {
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
        'nama': 'Tester',
        'email': 't@example.com',
        'phone': '',
        'roles': roles,
        'membership_status': 'active',
      });
  when(() => service.getMyAdminPermissions('u1')).thenAnswer((_) async => grants);
  final auth = AuthProvider(service: service);
  await auth.checkAuthStatus();
  return auth;
}

Widget _app(AuthProvider auth, Widget child) => ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(home: child),
    );

void main() {
  const secret = Text('ISI RAHASIA');

  testWidgets('blocks a jemaat', (tester) async {
    final auth = await _signedIn(['jemaat']);
    await tester.pumpWidget(_app(auth, const PermissionGuard(
      module: AppModule.pelayan, title: 'Pelayan', child: secret)));

    expect(find.text('ISI RAHASIA'), findsNothing);
    expect(find.text('Akses ditolak'), findsOneWidget);
  });

  testWidgets('blocks an admin without a grant for the module', (tester) async {
    final auth = await _signedIn(['admin'], grants: [
      {'user_id': 'u1', 'module': 'event', 'can_read': true},
    ]);
    await tester.pumpWidget(_app(auth, const PermissionGuard(
      module: AppModule.pelayan, title: 'Pelayan', child: secret)));

    expect(find.text('ISI RAHASIA'), findsNothing);
    expect(find.textContaining('Data Pelayan'), findsOneWidget);
  });

  testWidgets('lets an admin with a grant through', (tester) async {
    final auth = await _signedIn(['admin'], grants: [
      {'user_id': 'u1', 'module': 'pelayan', 'can_read': true},
    ]);
    await tester.pumpWidget(_app(auth, const PermissionGuard(
      module: AppModule.pelayan, title: 'Pelayan', child: secret)));

    expect(find.text('ISI RAHASIA'), findsOneWidget);
  });

  testWidgets('Super-Admin-only pages reject a regular admin', (tester) async {
    final auth = await _signedIn(['admin'], grants: [
      {'user_id': 'u1', 'module': 'users', 'can_read': true, 'can_create': true},
    ]);
    await tester.pumpWidget(_app(auth, const PermissionGuard(
      superAdminOnly: true, title: 'Izin', child: secret)));

    expect(find.text('ISI RAHASIA'), findsNothing);
    expect(find.text('Halaman ini hanya untuk Super Admin.'), findsOneWidget);
  });

  testWidgets('Super Admin passes every guard', (tester) async {
    final auth = await _signedIn(['super_admin', 'admin']);
    await tester.pumpWidget(_app(auth, const PermissionGuard(
      superAdminOnly: true, title: 'Izin', child: secret)));

    expect(find.text('ISI RAHASIA'), findsOneWidget);
  });
}
