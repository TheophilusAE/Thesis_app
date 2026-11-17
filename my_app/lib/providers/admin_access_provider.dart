import 'package:flutter/foundation.dart';

import '../models/admin_category.dart';
import '../models/admin_permission.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

/// State for the Super Admin "Kelola Admin & Izin" screens: admin accounts,
/// administrative categories, and each admin's module permissions.
///
/// Every write here is Super Admin only and enforced by the database
/// (`set_admin_permissions` RPC, RLS on admin_categories, the role trigger).
class AdminAccessProvider extends ChangeNotifier {
  AdminAccessProvider({SupabaseService? service})
      : _service = service ?? SupabaseService();

  final SupabaseService _service;

  List<AdminCategory> _categories = [];
  List<User> _users = [];
  Map<String, List<AdminPermission>> _permissionsByUser = {};
  bool _isLoading = false;
  String? _error;

  List<AdminCategory> get categories => _categories;
  List<AdminCategory> get activeCategories =>
      _categories.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Accounts holding the admin or super_admin role, Super Admins first.
  List<User> get admins {
    final list = _users
        .where((u) => u.hasRole('admin') || u.hasRole('super_admin'))
        .toList()
      ..sort((a, b) {
        final sa = a.hasRole('super_admin') ? 0 : 1;
        final sb = b.hasRole('super_admin') ? 0 : 1;
        return sa != sb ? sa - sb : a.name.compareTo(b.name);
      });
    return list;
  }

  /// Approved members who could be promoted to admin.
  List<User> get promotableUsers => _users
      .where((u) =>
          !u.hasRole('admin') &&
          !u.hasRole('super_admin') &&
          AuthProvider.isApprovedStatus(u.membershipStatus))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  List<AdminPermission> permissionsFor(String userId) =>
      _permissionsByUser[userId] ?? const [];

  String categoryName(String? categoryId) {
    if (categoryId == null) return 'Semua kategori';
    for (final c in _categories) {
      if (c.id == categoryId) return c.nama;
    }
    return 'Kategori tidak dikenal';
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getAdminCategories(),
        _service.getAllUsers(),
        _service.getAllAdminPermissions(),
      ]);
      _categories = results[0].map(AdminCategory.fromJson).toList();
      _users = results[1].map((row) => AuthProvider.userFromRow(row)).toList();
      final grouped = <String, List<AdminPermission>>{};
      for (final row in results[2]) {
        final p = AdminPermission.fromJson(row);
        grouped.putIfAbsent(p.userId, () => []).add(p);
      }
      _permissionsByUser = grouped;
    } catch (e) {
      _error = SupabaseService.isMissingRelation(e)
          ? 'Tabel izin admin belum ada. Jalankan migration_rbac_v2.sql terlebih dahulu.'
          : 'Gagal memuat data admin: $e';
      debugPrint('AdminAccessProvider.load: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Replaces all grants of [userId]. Empty grants are dropped.
  Future<bool> savePermissions(String userId, List<AdminPermission> grants) async {
    try {
      final payload = grants.where((g) => !g.isEmpty).map((g) => g.toGrantJson()).toList();
      await _service.setAdminPermissions(userId, payload);
      _permissionsByUser[userId] = grants.where((g) => !g.isEmpty).toList();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal menyimpan izin: $e';
      notifyListeners();
      return false;
    }
  }

  /// Gives [user] the admin role (no module permissions yet — the Super
  /// Admin assigns them next, so a new admin starts with no access).
  Future<bool> promoteToAdmin(User user) async {
    final roles = {...user.roles, 'admin'}.toList();
    return _setRoles(user, roles);
  }

  /// Removes the admin role and all of the account's grants.
  Future<bool> revokeAdmin(User user) async {
    if (user.hasRole('super_admin')) {
      _error = 'Super Admin tidak dapat dicabut dari sini. Gunakan Kelola Role.';
      notifyListeners();
      return false;
    }
    try {
      await _service.setAdminPermissions(user.id, const []);
    } catch (e) {
      debugPrint('revokeAdmin: clearing grants failed: $e');
    }
    final roles = user.roles.where((r) => r != 'admin').toList();
    if (roles.isEmpty) roles.add('jemaat');
    final ok = await _setRoles(user, roles);
    if (ok) _permissionsByUser.remove(user.id);
    return ok;
  }

  Future<bool> _setRoles(User user, List<String> roles) async {
    try {
      await _service.updateUserRoles(user.id, roles);
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx != -1) _users[idx] = _users[idx].copyWith(roles: roles);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal mengubah role: $e';
      notifyListeners();
      return false;
    }
  }

  /// Adds a new administrative category (e.g. "Wanita", "Musik").
  /// Returns an error message, or null on success.
  Future<String?> addCategory(String name) async {
    final nama = name.trim();
    if (nama.isEmpty) return 'Nama kategori wajib diisi.';
    final kode = AdminCategory.codeFromName(nama);
    if (kode.isEmpty) return 'Nama kategori harus mengandung huruf atau angka.';
    if (_categories.any((c) => c.kode == kode)) {
      return 'Kategori "$nama" sudah ada.';
    }
    try {
      await _service.addAdminCategory(kode: kode, nama: nama);
      await load();
      return null;
    } catch (e) {
      return 'Gagal menambah kategori: $e';
    }
  }

  Future<bool> setCategoryActive(AdminCategory category, bool isActive) async {
    try {
      await _service.setAdminCategoryActive(category.id, isActive);
      _categories = [
        for (final c in _categories)
          c.id == category.id
              ? AdminCategory(id: c.id, kode: c.kode, nama: c.nama, isActive: isActive)
              : c,
      ];
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Gagal mengubah kategori: $e';
      notifyListeners();
      return false;
    }
  }
}
