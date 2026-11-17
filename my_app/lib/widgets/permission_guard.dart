import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/permissions.dart';
import 'common/app_empty_state.dart';

/// Shows [child] only when the signed-in account is in admin mode and may
/// open [module] (read, create or approve), or — with [superAdminOnly] — is
/// a Super Admin. Otherwise shows an "access denied" page.
///
/// This is a UI convenience only. The same rules are enforced by Supabase
/// RLS and the permission-checked RPCs, so bypassing the UI gains nothing.
class PermissionGuard extends StatelessWidget {
  final String? module;
  final bool superAdminOnly;
  final String title;
  final Widget child;

  const PermissionGuard({
    super.key,
    this.module,
    this.superAdminOnly = false,
    required this.title,
    required this.child,
  }) : assert(module != null || superAdminOnly,
            'Give a module, or set superAdminOnly');

  static bool allows(AuthProvider auth, {String? module, bool superAdminOnly = false}) {
    if (!auth.isAdminMode) return false;
    if (superAdminOnly) return auth.isSuperAdmin;
    return auth.canAccess(module!);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (allows(auth, module: module, superAdminOnly: superAdminOnly)) {
      return child;
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Akses ditolak',
        description: superAdminOnly
            ? 'Halaman ini hanya untuk Super Admin.'
            : 'Akun Anda belum diberi izin untuk modul '
                '"${AppModule.label(module!)}". Hubungi Super Admin.',
      ),
    );
  }
}
