import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/admin_permission.dart';
import 'package:my_app/utils/permissions.dart';

/// PermissionSet.can() must mirror public.has_permission() in
/// migration_rbac_v2.sql. These cases are the same matrix as the SQL
/// tests in rls_tests_checkpoint1.sql.
void main() {
  const umum = 'cat-umum';
  const pemuda = 'cat-pemuda';

  AdminPermission grant(String module,
          {String? category, bool c = false, bool r = false, bool a = false}) =>
      AdminPermission(
        userId: 'admin-1',
        module: module,
        categoryId: category,
        canCreate: c,
        canRead: r,
        canApprove: a,
      );

  group('Super Admin', () {
    const set = PermissionSet(isSuperAdmin: true, isAdmin: true);

    test('can do every action on every module, including finance', () {
      for (final m in AppModule.all) {
        for (final a in PermissionAction.values) {
          expect(set.can(m, a), isTrue, reason: '$m/$a');
        }
      }
      expect(set.canModifyExisting, isTrue);
    });
  });

  group('non-admin (jemaat / pelayan)', () {
    test('has no administrative permission at all', () {
      for (final a in PermissionAction.values) {
        expect(PermissionSet.none.can(AppModule.event, a), isFalse);
      }
      expect(PermissionSet.none.canAccess(AppModule.users), isFalse);
      expect(PermissionSet.none.canModifyExisting, isFalse);
    });
  });

  group('Admin', () {
    final set = PermissionSet(
      isSuperAdmin: false,
      isAdmin: true,
      grants: [
        grant(AppModule.event, category: umum, c: true, r: true),
        grant(AppModule.users, r: true, a: true), // all categories
      ],
    );

    test('gets exactly the granted create/read/approve actions', () {
      expect(set.can(AppModule.event, PermissionAction.create), isTrue);
      expect(set.can(AppModule.event, PermissionAction.read), isTrue);
      expect(set.can(AppModule.event, PermissionAction.approve), isFalse);
      expect(set.can(AppModule.users, PermissionAction.approve), isTrue);
      expect(set.can(AppModule.users, PermissionAction.create), isFalse);
    });

    test('never gets update or delete, even with every flag granted', () {
      final full = PermissionSet(
        isSuperAdmin: false,
        isAdmin: true,
        grants: [grant(AppModule.event, c: true, r: true, a: true)],
      );
      expect(full.can(AppModule.event, PermissionAction.update), isFalse);
      expect(full.can(AppModule.event, PermissionAction.delete), isFalse);
      expect(full.canModifyExisting, isFalse);
    });

    test('has no access to modules that were not granted (e.g. finance)', () {
      expect(set.can(AppModule.kas, PermissionAction.read), isFalse);
      expect(set.canAccess(AppModule.kas), isFalse);
      expect(set.canAccess(AppModule.pelayan), isFalse);
    });

    test('a category-scoped grant only covers data of that category', () {
      expect(set.can(AppModule.event, PermissionAction.read, categoryId: umum), isTrue);
      expect(set.can(AppModule.event, PermissionAction.read, categoryId: pemuda), isFalse);
      // Uncategorized data (no category passed) is covered by any grant.
      expect(set.can(AppModule.event, PermissionAction.read), isTrue);
    });

    test('an all-categories grant (null category) covers every category', () {
      expect(set.can(AppModule.users, PermissionAction.read, categoryId: pemuda), isTrue);
      expect(set.can(AppModule.users, PermissionAction.read, categoryId: umum), isTrue);
    });

    test('canAccess is true when any of read/create/approve is granted', () {
      final approveOnly = PermissionSet(
        isSuperAdmin: false,
        isAdmin: true,
        grants: [grant(AppModule.prayer, a: true)],
      );
      expect(approveOnly.canAccess(AppModule.prayer), isTrue);
    });
  });

  group('legacy mode (RBAC v2 migration not run yet)', () {
    const set = PermissionSet(isSuperAdmin: false, isAdmin: true, legacyMode: true);

    test('keeps the previous full admin behaviour', () {
      expect(set.can(AppModule.event, PermissionAction.delete), isTrue);
      expect(set.canModifyExisting, isTrue);
    });

    test('does not turn a non-admin into an admin', () {
      const notAdmin = PermissionSet(isSuperAdmin: false, isAdmin: false, legacyMode: true);
      expect(notAdmin.can(AppModule.event, PermissionAction.read), isFalse);
    });
  });

  test('module list matches the database CHECK constraint (17 modules)', () {
    expect(AppModule.all.toSet(), hasLength(17));
    expect(AppModule.financial, containsAll([AppModule.kas, AppModule.rekening]));
    for (final m in AppModule.all) {
      expect(AppModule.label(m), isNot(m), reason: 'missing label for $m');
    }
  });
}
