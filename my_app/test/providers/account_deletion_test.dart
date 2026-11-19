import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:my_app/widgets/delete_account_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockService extends Mock implements SupabaseService {}

Future<AuthProvider> _signedIn(_MockService service, {List<String> roles = const ['jemaat']}) async {
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
        'tanggal_lahir': '1990-05-17',
      });
  when(() => service.getMyAdminPermissions('u1')).thenAnswer((_) async => []);
  when(() => service.signOut()).thenAnswer((_) async {});
  final auth = AuthProvider(service: service);
  await auth.checkAuthStatus();
  return auth;
}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  group('deleteAccount', () {
    test('deletes server-side, then clears the session', () async {
      final service = _MockService();
      final auth = await _signedIn(service);
      when(() => service.deleteMyAccount()).thenAnswer((_) async {});

      expect(await auth.deleteAccount(), isTrue);
      verify(() => service.deleteMyAccount()).called(1);
      verify(() => service.signOut()).called(1);
      expect(auth.currentUser, isNull);
      expect(auth.isLoggedIn, isFalse);
    });

    test('keeps the session and shows the server reason when deletion fails', () async {
      final service = _MockService();
      final auth = await _signedIn(service);
      when(() => service.deleteMyAccount())
          .thenThrow(const AccountDeletionException('Layanan hapus akun belum aktif. Hubungi admin gereja.'));

      expect(await auth.deleteAccount(), isFalse);
      expect(auth.lastMessage, contains('belum aktif'));
      expect(auth.currentUser, isNotNull);
      verifyNever(() => service.signOut());
    });

    test('a Super Admin cannot delete their own account', () async {
      final service = _MockService();
      final auth = await _signedIn(service, roles: ['super_admin', 'admin', 'jemaat']);

      expect(await auth.deleteAccount(), isFalse);
      expect(auth.lastMessage, contains('Super Admin'));
      verifyNever(() => service.deleteMyAccount());
    });
  });

  group('updateProfile', () {
    test('sends only the changed fields', () async {
      final service = _MockService();
      final auth = await _signedIn(service);
      when(() => service.updateUserProfile(any(), any())).thenAnswer((_) async {});

      final me = auth.currentUser!;
      final ok = await auth.updateProfile(me.copyWith(birthDate: DateTime(1991, 2, 3)));

      expect(ok, isTrue);
      final sent = verify(() => service.updateUserProfile('u1', captureAny())).captured.single as Map;
      expect(sent, {'tanggal_lahir': '1991-02-03'});
      expect(auth.currentUser!.birthDate, DateTime(1991, 2, 3));
    });

    test('saving without changes makes no request', () async {
      final service = _MockService();
      final auth = await _signedIn(service);

      expect(await auth.updateProfile(auth.currentUser!), isTrue);
      verifyNever(() => service.updateUserProfile(any(), any()));
    });
  });

  testWidgets('the delete button stays disabled until HAPUS is typed', (tester) async {
    final service = _MockService();
    final auth = await _signedIn(service);
    when(() => service.deleteMyAccount()).thenAnswer((_) async {});

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: auth,
      child: const MaterialApp(home: Scaffold(body: DeleteAccountDialog())),
    ));

    FilledButton button() => tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button().onPressed, isNull);

    await tester.enterText(find.byKey(const ValueKey('delete-confirm-field')), 'hapus');
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });
}
