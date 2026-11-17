import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/admin_permission.dart';
import 'package:my_app/providers/admin_access_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class _MockService extends Mock implements SupabaseService {}

Map<String, dynamic> _user(String id, String name, List<String> roles,
        {String status = 'active'}) =>
    {
      'id': id,
      'nama': name,
      'email': '$id@example.com',
      'phone': '',
      'roles': roles,
      'membership_status': status,
    };

void main() {
  late _MockService service;
  late AdminAccessProvider provider;

  setUp(() {
    service = _MockService();
    provider = AdminAccessProvider(service: service);
    when(() => service.getAdminCategories()).thenAnswer((_) async => [
          {'id': 'c1', 'kode': 'umum', 'nama': 'Umum', 'is_active': true},
          {'id': 'c2', 'kode': 'pemuda', 'nama': 'Pemuda', 'is_active': false},
        ]);
    when(() => service.getAllUsers()).thenAnswer((_) async => [
          _user('a1', 'Budi', ['admin', 'jemaat']),
          _user('s1', 'Zakaria', ['super_admin', 'admin']),
          _user('j1', 'Citra', ['jemaat']),
          _user('j2', 'Dodi', ['jemaat'], status: 'pending'),
        ]);
    when(() => service.getAllAdminPermissions()).thenAnswer((_) async => [
          {'user_id': 'a1', 'module': 'event', 'category_id': 'c1', 'can_create': true, 'can_read': true},
          {'user_id': 'a1', 'module': 'users', 'category_id': null, 'can_read': true},
        ]);
  });

  test('load lists admins (Super Admin first) and groups their grants', () async {
    await provider.load();

    expect(provider.error, isNull);
    expect(provider.admins.map((u) => u.id), ['s1', 'a1']);
    expect(provider.permissionsFor('a1'), hasLength(2));
    expect(provider.permissionsFor('s1'), isEmpty);
    expect(provider.activeCategories.map((c) => c.kode), ['umum']);
    expect(provider.categoryName('c1'), 'Umum');
    expect(provider.categoryName(null), 'Semua kategori');
  });

  test('only approved non-admin members can be promoted', () async {
    await provider.load();
    expect(provider.promotableUsers.map((u) => u.id), ['j1']);
  });

  test('missing RBAC tables give a clear "run the migration" message', () async {
    when(() => service.getAdminCategories())
        .thenThrow(Exception('PGRST205 relation admin_categories does not exist'));
    await provider.load();
    expect(provider.error, contains('migration_rbac_v2.sql'));
  });

  test('saving permissions sends only non-empty grants to the RPC', () async {
    when(() => service.setAdminPermissions(any(), any())).thenAnswer((_) async {});

    final ok = await provider.savePermissions('a1', const [
      AdminPermission(userId: 'a1', module: 'event', categoryId: 'c1', canCreate: true, canRead: true),
      AdminPermission(userId: 'a1', module: 'feedback'), // empty → dropped
    ]);

    expect(ok, isTrue);
    final sent = verify(() => service.setAdminPermissions('a1', captureAny())).captured.single
        as List<Map<String, dynamic>>;
    expect(sent, hasLength(1));
    expect(sent.single, {
      'module': 'event',
      'category_id': 'c1',
      'can_create': true,
      'can_read': true,
      'can_approve': false,
    });
  });

  test('promoting adds the admin role without touching other roles', () async {
    when(() => service.updateUserRoles(any(), any())).thenAnswer((_) async {});
    await provider.load();

    final citra = provider.promotableUsers.single;
    expect(await provider.promoteToAdmin(citra), isTrue);

    final roles = verify(() => service.updateUserRoles('j1', captureAny())).captured.single
        as List<String>;
    expect(roles, containsAll(['jemaat', 'admin']));
    expect(provider.admins.map((u) => u.id), contains('j1'));
  });

  test('revoking clears the grants first, then removes only the admin role', () async {
    when(() => service.setAdminPermissions(any(), any())).thenAnswer((_) async {});
    when(() => service.updateUserRoles(any(), any())).thenAnswer((_) async {});
    await provider.load();

    final budi = provider.admins.firstWhere((u) => u.id == 'a1');
    expect(await provider.revokeAdmin(budi), isTrue);

    verify(() => service.setAdminPermissions('a1', [])).called(1);
    verify(() => service.updateUserRoles('a1', ['jemaat'])).called(1);
    expect(provider.permissionsFor('a1'), isEmpty);
  });

  test('a Super Admin cannot be revoked from this screen', () async {
    await provider.load();
    final zakaria = provider.admins.first;

    expect(await provider.revokeAdmin(zakaria), isFalse);
    verifyNever(() => service.updateUserRoles(any(), any()));
  });

  test('adding a category validates the name and rejects duplicates', () async {
    when(() => service.addAdminCategory(kode: any(named: 'kode'), nama: any(named: 'nama')))
        .thenAnswer((_) async {});
    await provider.load();

    expect(await provider.addCategory('   '), isNotNull);
    expect(await provider.addCategory('Umum'), contains('sudah ada'));
    expect(await provider.addCategory('Sekolah Minggu'), isNull);
    verify(() => service.addAdminCategory(kode: 'sekolah_minggu', nama: 'Sekolah Minggu')).called(1);
  });
}
