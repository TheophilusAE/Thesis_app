import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/user.dart' as app;
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockService extends Mock implements SupabaseService {}

sb.User _authUser() => const sb.User(
      id: 'u1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    );

Map<String, dynamic> _profile(String status, {List<String> roles = const ['jemaat']}) => {
      'id': 'u1',
      'nama': 'Budi',
      'email': 'budi@example.com',
      'phone': '0813000000',
      'roles': roles,
      'membership_status': status,
      // Extended Jemaat data intentionally NULL: account must still be valid.
      'identity_number': null,
      'family_group': null,
      'baptism_date': null,
      'address': null,
    };

void main() {
  late _MockService service;
  late AuthProvider auth;

  setUp(() {
    service = _MockService();
    auth = AuthProvider(service: service);
    when(() => service.signOut()).thenAnswer((_) async {});
    when(() => service.getCurrentUser()).thenReturn(_authUser());
  });

  void stubLogin(Map<String, dynamic> profile) {
    when(() => service.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => sb.AuthResponse(user: _authUser()));
    when(() => service.getUserProfile('u1')).thenAnswer((_) async => profile);
  }

  test('register sends only name/email/phone/password and signs out', () async {
    when(() => service.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          nama: any(named: 'nama'),
          phone: any(named: 'phone'),
          additionalData: any(named: 'additionalData'),
        )).thenAnswer((_) async => sb.AuthResponse(user: _authUser()));

    final ok = await auth.register(
      name: 'Budi',
      email: 'budi@example.com',
      phone: '0813000000',
      password: 'secret1',
    );

    expect(ok, isTrue);
    expect(auth.isLoggedIn, isFalse);
    verify(() => service.signUp(
          email: 'budi@example.com',
          password: 'secret1',
          nama: 'Budi',
          phone: '0813000000',
          additionalData: null,
        )).called(1);
    verify(() => service.signOut()).called(1);
  });

  test('pending account is blocked at login', () async {
    stubLogin(_profile('pending'));
    expect(await auth.login('budi@example.com', 'secret1'), isFalse);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.lastMessage, contains('belum diverifikasi'));
  });

  test('rejected account is blocked at login', () async {
    stubLogin(_profile('rejected'));
    expect(await auth.login('budi@example.com', 'secret1'), isFalse);
    expect(auth.lastMessage, contains('ditolak'));
  });

  test('approved account with empty Jemaat profile can log in', () async {
    stubLogin(_profile('active'));
    expect(await auth.login('budi@example.com', 'secret1'), isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.currentUser!.identityNumber, isNull);
    expect(auth.blockedStatus, isNull);
  });

  test('persisted pending session is held on the waiting state, not logged in', () async {
    when(() => service.getUserProfile('u1')).thenAnswer((_) async => _profile('pending'));
    await auth.checkAuthStatus();
    expect(auth.isLoggedIn, isFalse);
    expect(auth.blockedStatus, 'pending');
  });

  test('persisted rejected session is blocked', () async {
    when(() => service.getUserProfile('u1')).thenAnswer((_) async => _profile('rejected'));
    await auth.checkAuthStatus();
    expect(auth.isLoggedIn, isFalse);
    expect(auth.blockedStatus, 'rejected');
  });

  test('approval by admin is picked up by refreshApprovalStatus', () async {
    when(() => service.getUserProfile('u1')).thenAnswer((_) async => _profile('pending'));
    await auth.checkAuthStatus();
    when(() => service.getUserProfile('u1')).thenAnswer((_) async => _profile('active'));
    await auth.refreshApprovalStatus();
    expect(auth.isLoggedIn, isTrue);
    expect(auth.blockedStatus, isNull);
  });

  test('updateProfile stores cleared optional fields as null', () async {
    when(() => service.updateUserProfile(any(), any())).thenAnswer((_) async {});
    final user = app.User(id: 'u1', name: 'Budi', email: 'b@x.com', phone: '0813');

    expect(await auth.updateProfile(user), isTrue);

    final data = verify(() => service.updateUserProfile('u1', captureAny())).captured.single
        as Map<String, dynamic>;
    expect(data['identity_number'], isNull);
    expect(data['family_group'], isNull);
    expect(data['baptism_date'], isNull);
    expect(data['address'], isNull);
    expect(data.containsKey('identity_number'), isTrue);
  });
}
