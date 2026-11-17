import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:my_app/utils/permissions.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockService extends Mock implements SupabaseService {}

sb.User _authUser() => const sb.User(
      id: 'u1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    );

Map<String, dynamic> _profile({
  List<String> roles = const ['jemaat'],
  String status = 'active',
  String? membershipType,
}) =>
    {
      'id': 'u1',
      'nama': 'Rina',
      'email': 'rina@example.com',
      'phone': '0813',
      'roles': roles,
      'membership_status': status,
      'membership_type': membershipType,
    };

void main() {
  late _MockService service;
  late AuthProvider auth;

  setUp(() {
    service = _MockService();
    auth = AuthProvider(service: service);
    when(() => service.getCurrentUser()).thenReturn(_authUser());
    when(() => service.signOut()).thenAnswer((_) async {});
  });

  Future<void> signInAs(Map<String, dynamic> profile) async {
    when(() => service.getUserProfile('u1')).thenAnswer((_) async => profile);
    await auth.checkAuthStatus();
  }

  test('an admin loads only the granted permissions (create/read, no edit)', () async {
    when(() => service.getMyAdminPermissions('u1')).thenAnswer((_) async => [
          {
            'id': 'p1',
            'user_id': 'u1',
            'module': 'event',
            'category_id': null,
            'can_create': true,
            'can_read': true,
            'can_approve': false,
          },
        ]);
    await signInAs(_profile(roles: ['admin', 'jemaat']));

    expect(auth.isAdminMode, isTrue);
    expect(auth.isSuperAdmin, isFalse);
    expect(auth.can(AppModule.event, PermissionAction.create), isTrue);
    expect(auth.can(AppModule.event, PermissionAction.approve), isFalse);
    expect(auth.canAccess(AppModule.users), isFalse);
    expect(auth.canModifyExisting, isFalse);
  });

  test('a Super Admin gets full access without reading the grants table', () async {
    await signInAs(_profile(roles: ['super_admin', 'admin', 'jemaat']));

    expect(auth.isSuperAdmin, isTrue);
    expect(auth.isAdminMode, isTrue);
    expect(auth.can(AppModule.kas, PermissionAction.delete), isTrue);
    expect(auth.canModifyExisting, isTrue);
    verifyNever(() => service.getMyAdminPermissions(any()));
  });

  test('before the migration (no permissions table) an admin keeps legacy access', () async {
    when(() => service.getMyAdminPermissions('u1')).thenAnswer((_) async => null);
    await signInAs(_profile(roles: ['admin']));

    expect(auth.permissions.legacyMode, isTrue);
    expect(auth.canAccess(AppModule.users), isTrue);
  });

  test('if the grants cannot be read, the admin sees no admin modules (fail closed)', () async {
    when(() => service.getMyAdminPermissions('u1')).thenThrow(Exception('network'));
    await signInAs(_profile(roles: ['admin']));

    expect(auth.isLoggedIn, isTrue);
    expect(auth.canAccess(AppModule.users), isFalse);
    expect(auth.permissions.legacyMode, isFalse);
  });

  test('permissions only apply in the admin view, not after switching to Jemaat', () async {
    await signInAs(_profile(roles: ['super_admin', 'admin', 'jemaat']));
    auth.switchRole('jemaat');

    expect(auth.isAdminMode, isFalse);
    expect(auth.can(AppModule.event, PermissionAction.read), isFalse);
  });

  test('an admin account is no longer let in while pending (no role bypass)', () async {
    when(() => service.getMyAdminPermissions(any())).thenAnswer((_) async => []);
    await signInAs(_profile(roles: ['admin'], status: 'pending'));

    expect(auth.isLoggedIn, isFalse);
    expect(auth.blockedStatus, 'pending');
  });

  test('a deactivated account is blocked with its own message at login', () async {
    when(() => service.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => sb.AuthResponse(user: _authUser()));
    when(() => service.getUserProfile('u1'))
        .thenAnswer((_) async => _profile(status: 'inactive'));

    expect(await auth.login('rina@example.com', 'secret1'), isFalse);
    expect(auth.lastMessage, contains('dinonaktifkan'));
    expect(auth.isGuest, isTrue);
  });

  test('logout clears permissions and returns to guest', () async {
    await signInAs(_profile(roles: ['super_admin', 'admin']));
    await auth.logout();

    expect(auth.isGuest, isTrue);
    expect(auth.isSuperAdmin, isFalse);
    expect(auth.permissions.isAdmin, isFalse);
  });

  test('membership_type is read from the profile (no longer wiped on admin edits)', () {
    final user = AuthProvider.userFromRow(_profile(membershipType: 'Tetap'));
    expect(user.membershipType, 'Tetap');
  });

  test('approving a member goes through the set_member_status RPC', () async {
    when(() => service.setMemberStatus(any(), any())).thenAnswer((_) async {});

    expect(await auth.verifyUser(userId: 'u2', approved: true), isTrue);
    expect(await auth.verifyUser(userId: 'u3', approved: false), isTrue);
    expect(await auth.deactivateUser('u4'), isTrue);

    verify(() => service.setMemberStatus('u2', 'active')).called(1);
    verify(() => service.setMemberStatus('u3', 'rejected')).called(1);
    verify(() => service.setMemberStatus('u4', 'inactive')).called(1);
    verifyNever(() => service.updateUserProfile(any(), any()));
  });

  test('a refused approval reports failure with the database message', () async {
    when(() => service.setMemberStatus(any(), any())).thenThrow(
      const sb.PostgrestException(
        message: 'Anda tidak memiliki izin menyetujui anggota.',
        code: '42501',
      ),
    );

    expect(await auth.verifyUser(userId: 'u2', approved: true), isFalse);
    expect(auth.lastMessage, 'Anda tidak memiliki izin menyetujui anggota.');
  });

  test('changing roles writes only the roles column', () async {
    when(() => service.updateUserRoles(any(), any())).thenAnswer((_) async {});

    expect(await auth.updateUserRoles('u2', ['admin', 'jemaat']), isTrue);

    verify(() => service.updateUserRoles('u2', ['admin', 'jemaat'])).called(1);
    verifyNever(() => service.updateUserProfile(any(), any()));
  });
}
