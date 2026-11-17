import '../models/admin_permission.dart';

/// Administrative modules. These strings MUST match the CHECK constraint on
/// `admin_permissions.module` in `migration_rbac_v2.sql`.
class AppModule {
  AppModule._();

  static const users = 'users';
  static const pelayan = 'pelayan';
  static const jadwalIbadah = 'jadwal_ibadah';
  static const jadwalPelayanan = 'jadwal_pelayanan';
  static const event = 'event';
  static const renungan = 'renungan';
  static const playlist = 'playlist';
  static const quest = 'quest';
  static const group = 'group';
  static const sermon = 'sermon';
  static const prayer = 'prayer';
  static const feedback = 'feedback';
  static const kehadiran = 'kehadiran';
  static const notifikasi = 'notifikasi';
  static const kas = 'kas';
  static const rekening = 'rekening';
  static const rekomendasi = 'rekomendasi';

  static const all = <String>[
    users, pelayan, jadwalIbadah, jadwalPelayanan, event, renungan, playlist,
    quest, group, sermon, prayer, feedback, kehadiran, notifikasi, kas,
    rekening, rekomendasi,
  ];

  /// Modules whose data is financial. Never granted by default.
  static const financial = <String>{kas, rekening};

  /// Modules where an "approve" action exists in the app.
  static const approvable = <String>{users, jadwalPelayanan, prayer};

  static String label(String module) {
    switch (module) {
      case users:
        return 'Pengguna & Anggota';
      case pelayan:
        return 'Data Pelayan';
      case jadwalIbadah:
        return 'Jadwal Ibadah';
      case jadwalPelayanan:
        return 'Jadwal Pelayanan & Latihan';
      case event:
        return 'Event Gereja';
      case renungan:
        return 'Renungan Harian';
      case playlist:
        return 'Playlist Pujian';
      case quest:
        return 'Quest Baca';
      case group:
        return 'Group / Komsel';
      case sermon:
        return 'Khotbah & Media';
      case prayer:
        return 'Pokok Doa';
      case feedback:
        return 'Feedback';
      case kehadiran:
        return 'Kehadiran';
      case notifikasi:
        return 'Notifikasi';
      case kas:
        return 'Kas Keuangan';
      case rekening:
        return 'Rekening Dompet Kas';
      case rekomendasi:
        return 'Rekomendasi Kegiatan';
      default:
        return module;
    }
  }
}

/// Actions checked by [PermissionSet.can]. Update and delete are reserved
/// for Super Admin — Admin permissions never include them.
enum PermissionAction { create, read, approve, update, delete }

/// The permissions of the signed-in account, evaluated client-side for UI
/// decisions (which menus, buttons and screens to show).
///
/// This is a mirror of `public.has_permission()` in the database and is NOT
/// a security boundary: Supabase RLS and the RPCs enforce the same rules
/// server-side. Keep both in sync.
class PermissionSet {
  final bool isSuperAdmin;
  final bool isAdmin;
  final List<AdminPermission> grants;

  /// True when the `admin_permissions` table does not exist yet (database
  /// migration not run). The app then behaves as before RBAC v2: an admin
  /// sees every admin menu, and RLS remains the real enforcement.
  final bool legacyMode;

  const PermissionSet({
    required this.isSuperAdmin,
    required this.isAdmin,
    this.grants = const [],
    this.legacyMode = false,
  });

  static const none = PermissionSet(isSuperAdmin: false, isAdmin: false);

  bool can(String module, PermissionAction action, {String? categoryId}) {
    if (isSuperAdmin) return true;
    if (!isAdmin) return false;
    if (legacyMode) return true;
    if (action == PermissionAction.update || action == PermissionAction.delete) {
      return false;
    }
    return grants.any((g) {
      if (g.module != module) return false;
      if (categoryId != null && g.categoryId != null && g.categoryId != categoryId) {
        return false;
      }
      switch (action) {
        case PermissionAction.create:
          return g.canCreate;
        case PermissionAction.read:
          return g.canRead;
        case PermissionAction.approve:
          return g.canApprove;
        case PermissionAction.update:
        case PermissionAction.delete:
          return false;
      }
    });
  }

  /// True when the account may open the module's admin screen at all.
  bool canAccess(String module) =>
      can(module, PermissionAction.read) ||
      can(module, PermissionAction.create) ||
      can(module, PermissionAction.approve);

  /// Editing or deleting existing records is Super Admin only. In legacy
  /// mode (before the migration) admins keep their previous full access.
  bool get canModifyExisting => isSuperAdmin || (isAdmin && legacyMode);
}
