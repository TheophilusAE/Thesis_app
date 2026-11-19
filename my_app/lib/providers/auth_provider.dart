import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/admin_permission.dart';
import '../models/user.dart';
import '../services/push_service.dart';
import '../services/supabase_service.dart';
import '../utils/permissions.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService;

  AuthProvider({SupabaseService? service})
      : _supabaseService = service ?? SupabaseService();

  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _lastMessage;
  late String _currentDisplayRole = 'jemaat';
  bool _suppressAuthEvents = false;
  // Non-null when a session exists but the account is not approved yet
  // ('pending' or 'rejected'). Approval (membership_status) is separate from
  // Supabase email confirmation.
  String? _blockedStatus;
  String? _lastRawError; // debug aid only; never shown in release builds
  PermissionSet _permissions = PermissionSet.none;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get blockedStatus => _blockedStatus;
  String? get lastRawError => _lastRawError;
  bool get isInitializing => _isInitializing;
  String? get lastMessage => _lastMessage;

  /// No approved session: the app shows the public guest home.
  bool get isGuest => !_isLoggedIn && _blockedStatus == null;

  /// Highest role: full CRUD everywhere, manages admins and permissions.
  bool get isSuperAdmin => _currentUser?.hasRole('super_admin') ?? false;

  /// Any administrative account (Admin or Super Admin).
  bool get isAdmin =>
      (_currentUser?.hasRole('admin') ?? false) || isSuperAdmin;
  /// True only when the account really holds the admin role AND the admin
  /// view is active (an admin who switched to Jemaat/Pelayan view is not in
  /// admin mode). Use this for admin-only UI and route guards.
  bool get isAdminMode => isAdmin && _currentDisplayRole == 'admin';
  bool get isPelayan => _currentUser?.hasRole('pelayan') ?? false;
  bool get isJemaat => _currentUser?.hasRole('jemaat') ?? false;
  /// The app views this user can switch between: jemaat / pelayan / admin.
  /// `super_admin` is not a view of its own — it is the Admin view with full
  /// rights — so it maps to 'admin' (listing it separately sent the user to
  /// an unknown view that fell back to the Jemaat screens).
  List<String> get userRoles {
    final raw = _currentUser?.roles ?? const <String>[];
    return [
      for (final r in const ['jemaat', 'pelayan', 'admin'])
        if (raw.contains(r) || (r == 'admin' && raw.contains('super_admin'))) r,
    ];
  }
  User? get user => _currentUser;
  String get currentDisplayRole => _currentDisplayRole;

  /// Permissions of the signed-in account. UI decisions only — the database
  /// (RLS + RPCs) enforces the same rules.
  PermissionSet get permissions => _permissions;

  /// Admin-mode permission check for a module action (see [PermissionSet]).
  bool can(String module, PermissionAction action, {String? categoryId}) =>
      isAdminMode && _permissions.can(module, action, categoryId: categoryId);

  /// Admin-mode check: may open the module's management screen at all.
  bool canAccess(String module) => isAdminMode && _permissions.canAccess(module);

  /// Editing/deleting existing records — Super Admin only.
  bool get canModifyExisting => isAdminMode && _permissions.canModifyExisting;

  String _mapError(dynamic e) {
    // Always log the real exception; the user only sees a friendly message.
    debugPrint('Auth error: $e');
    _lastRawError = e.toString();
    final msg = e.toString().toLowerCase();
    if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
      return 'Email belum dikonfirmasi. Periksa kotak masuk email Anda.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Email atau password salah. Silakan coba lagi.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('user_already_exists') ||
        msg.contains('already registered')) {
      return 'Email ini sudah terdaftar. Silakan login.';
    }
    if (msg.contains('password should be') || msg.contains('weak_password')) {
      return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
    }
    if (msg.contains('unable to validate email') || msg.contains('invalid email')) {
      return 'Format email tidak valid.';
    }
    if (msg.contains('rate_limit') ||
        msg.contains('rate limit') ||
        msg.contains('over_request_rate_limit') ||
        msg.contains('429')) {
      return 'Terlalu banyak percobaan atau batas pengiriman email tercapai. Tunggu beberapa saat lalu coba lagi.';
    }
    if (msg.contains('database error saving new user')) {
      return 'Server gagal menyimpan data akun baru. Hubungi admin gereja.';
    }
    if (msg.contains('signup') && msg.contains('disabled')) {
      return 'Pendaftaran akun baru sedang dinonaktifkan.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
      return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  /// Turns a database/RPC exception into the message for the user. Our RPCs
  /// raise readable Indonesian messages (PostgrestException.message); other
  /// errors fall back to the generic mapping.
  String _dbError(Object e) {
    debugPrint('DB error: $e');
    _lastRawError = e.toString();
    if (e is PostgrestException && e.message.trim().isNotEmpty) {
      if (e.code == '42501' || e.code == '22023' || e.code == 'P0002' || e.code == 'P0001') {
        return e.message;
      }
    }
    final msg = e.toString();
    if (msg.contains('Super Admin') || msg.contains('izin')) {
      return msg.replaceFirst('Exception: ', '');
    }
    return _mapError(e);
  }

  /// Statuses treated as approved. 'verified' is a legacy value the admin
  /// screen already normalizes to 'active'.
  static bool isApprovedStatus(String status) =>
      status == 'active' || status == 'verified';

  /// Single access gate: only approved accounts count as logged in; anything
  /// else with a session ('pending', 'rejected', 'inactive') is held on the
  /// waiting screen. Admin roles no longer bypass this — a Super Admin can
  /// deactivate an admin account (mirrors `public.is_approved()`).
  void _applyAccessGate() {
    final user = _currentUser;
    if (user == null) {
      _isLoggedIn = false;
      _blockedStatus = null;
      return;
    }
    final approved = isApprovedStatus(user.membershipStatus);
    _isLoggedIn = approved;
    _blockedStatus = approved ? null : user.membershipStatus;
  }

  /// Builds the app user from a `public.users` row. Single mapping so every
  /// column (incl. membership_type) is read the same way everywhere.
  static User userFromRow(Map<String, dynamic> p, {String? fallbackId}) {
    return User(
      id: (p['id'] ?? fallbackId ?? '') as String,
      name: (p['nama'] ?? '') as String,
      email: (p['email'] ?? '') as String,
      phone: (p['phone'] ?? '') as String,
      roles: List<String>.from(p['roles'] ?? const ['jemaat']),
      membershipStatus: (p['membership_status'] ?? 'pending') as String,
      identityNumber: p['identity_number'] as String?,
      familyGroup: p['family_group'] as String?,
      membershipType: p['membership_type'] as String?,
      memberCardNumber: p['member_card_number'] as String?,
      memberSince: p['member_since'] as String?,
      address: p['address'] as String?,
      baptismDate: p['baptism_date'] as String?,
      groupId: p['group_id'] as String?,
      birthDate: DateTime.tryParse((p['tanggal_lahir'] ?? '') as String),
    );
  }

  /// Loads the admin's grants. Before the RBAC v2 migration the table does
  /// not exist: fall back to legacy behaviour (RLS still enforces access).
  Future<void> _loadPermissions() async {
    final user = _currentUser;
    if (user == null || !_isLoggedIn || !isAdmin) {
      _permissions = PermissionSet.none;
      return;
    }
    if (isSuperAdmin) {
      _permissions = const PermissionSet(isSuperAdmin: true, isAdmin: true);
      return;
    }
    try {
      final rows = await _supabaseService.getMyAdminPermissions(user.id);
      if (rows == null) {
        debugPrint('admin_permissions missing — RBAC v2 migration not run; legacy admin mode');
        _permissions = const PermissionSet(isSuperAdmin: false, isAdmin: true, legacyMode: true);
      } else {
        _permissions = PermissionSet(
          isSuperAdmin: false,
          isAdmin: true,
          grants: rows.map(AdminPermission.fromJson).toList(),
        );
      }
    } catch (e) {
      // Fail closed: an admin whose grants cannot be read sees no admin menus.
      debugPrint('Error loading admin permissions: $e');
      _permissions = const PermissionSet(isSuperAdmin: false, isAdmin: true);
    }
  }

  /// Re-reads the signed-in admin's permissions (e.g. after a Super Admin
  /// changed them).
  Future<void> refreshPermissions() async {
    await _loadPermissions();
    notifyListeners();
  }

  void _clearSession() {
    _isLoggedIn = false;
    _blockedStatus = null;
    _currentUser = null;
    _currentDisplayRole = 'jemaat';
    _permissions = PermissionSet.none;
  }

  void init() {
    _supabaseService.onAuthStateChange().listen((data) {
      if (_suppressAuthEvents) return;
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadUserData(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _clearSession();
        notifyListeners();
      }
    });
  }

  void switchRole(String role) {
    if (userRoles.contains(role)) {
      _currentDisplayRole = role;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        await _loadUserData(user.id);
      } else {
        _clearSession();
      }
    } catch (e) {
      _lastMessage = _mapError(e);
      _isLoggedIn = false;
      _blockedStatus = null;
    } finally {
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final profileData = await _supabaseService.getUserProfile(userId);
      if (profileData != null) {
        _currentUser = userFromRow(profileData, fallbackId: userId);
      } else {
        // Fallback: build minimal user from auth metadata so home screen doesn't crash
        final authUser = _supabaseService.getCurrentUser();
        _currentUser = User(
          id: userId,
          name: authUser?.userMetadata?['nama'] as String? ??
              authUser?.email?.split('@').first ??
              '',
          email: authUser?.email ?? '',
          phone: authUser?.userMetadata?['phone'] as String? ?? '',
          roles: ['jemaat'],
          membershipStatus: 'pending',
        );
      }

      _applyAccessGate();

      if (isAdmin) {
        _currentDisplayRole = 'admin';
      } else if (_currentUser!.hasRole('pelayan')) {
        _currentDisplayRole = 'pelayan';
      } else {
        _currentDisplayRole = 'jemaat';
      }
      await _loadPermissions();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Without a verified profile we cannot prove approval: fail closed.
      _clearSession();
    }
    notifyListeners();
  }

  /// Re-reads the profile (used by the waiting-for-approval screen).
  Future<void> refreshApprovalStatus() async {
    final user = _supabaseService.getCurrentUser();
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    await _loadUserData(user.id);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _lastMessage = null;
    // signUp may auto-sign-in the new (unapproved) user; keep that from
    // briefly flipping app state before we sign out below.
    _suppressAuthEvents = true;
    notifyListeners();

    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        nama: name,
        phone: phone,
      );

      if (response.user == null) {
        _lastMessage = 'Registrasi gagal. Silakan coba lagi.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Always sign out after registration — account must be verified by admin first
      try {
        await _supabaseService.signOut();
      } catch (_) {}
      _isLoggedIn = false;
      _blockedStatus = null;
      _currentUser = null;
      _lastMessage =
          'Registrasi berhasil. Akun Anda sedang menunggu verifikasi admin gereja.';

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastMessage = _mapError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _suppressAuthEvents = false;
    }
  }

  Future<bool> resendConfirmationEmail(String email) async {
    try {
      await _supabaseService.resendConfirmationEmail(email);
      _lastMessage = 'Email konfirmasi telah dikirim ulang. Periksa kotak masuk Anda.';
      notifyListeners();
      return true;
    } catch (e) {
      _lastMessage = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _lastMessage = null;
    // Login decides access itself; keep the auth listener from racing it.
    _suppressAuthEvents = true;
    notifyListeners();

    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserData(response.user!.id);

        // Block accounts admin has not approved (pending), has rejected, or
        // a Super Admin has deactivated.
        final blocked = _blockedStatus;
        if (blocked != null || _currentUser == null) {
          _clearSession();
          _lastMessage = switch (blocked) {
            'rejected' => 'Pendaftaran akun Anda ditolak. Silakan hubungi admin gereja.',
            'inactive' => 'Akun Anda telah dinonaktifkan. Silakan hubungi admin gereja.',
            _ => 'Akun Anda belum diverifikasi admin. Silakan tunggu persetujuan untuk dapat login.',
          };
          try {
            await _supabaseService.signOut();
          } catch (_) {}
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _lastMessage = 'Login berhasil';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _lastMessage = 'Login gagal. Silakan coba lagi.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _lastMessage = _mapError(e);
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _suppressAuthEvents = false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _supabaseService.resetPassword(email);
      _lastMessage = 'Link reset password telah dikirim ke email Anda.';
      notifyListeners();
      return true;
    } catch (e) {
      _lastMessage = _mapError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Before signing out (the token row is deleted as this user): this phone
    // must not keep receiving the previous account's push notifications.
    await PushService.instance.unregister(service: _supabaseService);
    try {
      await _supabaseService.signOut();
    } catch (e) {
      _lastMessage = 'Error logout: $e';
    }
    _clearSession();
    notifyListeners();
  }

  /// Permanently deletes the signed-in user's own account (Google Play
  /// requirement). Super Admin must hand the role over first (also enforced
  /// server-side). On success the session is cleared.
  Future<bool> deleteAccount() async {
    if (_currentUser == null) {
      _lastMessage = 'Anda belum login.';
      return false;
    }
    if (isSuperAdmin) {
      _lastMessage =
          'Akun Super Admin tidak dapat dihapus sendiri. Serahkan peran Super Admin ke akun lain terlebih dahulu.';
      return false;
    }
    try {
      await _supabaseService.deleteMyAccount();
    } on AccountDeletionException catch (e) {
      _lastMessage = e.message;
      return false;
    } catch (_) {
      _lastMessage = 'Gagal menghapus akun. Periksa koneksi internet lalu coba lagi.';
      return false;
    }
    // The account is gone server-side (its push token rows went with it);
    // drop this phone's FCM token and the local session.
    await PushService.instance.unregister(service: _supabaseService);
    try {
      await _supabaseService.signOut();
    } catch (_) {}
    _clearSession();
    _lastMessage = 'Akun Anda telah dihapus.';
    notifyListeners();
    return true;
  }

  static bool _sameDay(DateTime? a, DateTime? b) =>
      (a == null && b == null) ||
      (a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day);

  static String? _isoDate(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Saves only the profile fields that actually changed (one small UPDATE,
  /// or none at all), then updates the in-memory profile.
  Future<bool> updateProfile(User updatedUser) async {
    // No loaded profile to compare with (or another account): write every field.
    final before = _currentUser?.id == updatedUser.id ? _currentUser : null;
    final full = before == null;
    final changes = <String, dynamic>{
      if (full || updatedUser.name != before.name) 'nama': updatedUser.name,
      if (full || updatedUser.phone != before.phone) 'phone': updatedUser.phone,
      // Extended Jemaat data is optional: blank -> NULL, never a placeholder.
      if (full || updatedUser.address != before.address) 'address': updatedUser.address,
      if (full || updatedUser.identityNumber != before.identityNumber) 'identity_number': updatedUser.identityNumber,
      if (full || updatedUser.baptismDate != before.baptismDate) 'baptism_date': updatedUser.baptismDate,
      // The Group picker replaces the old free-text family_group, which is
      // left untouched in the database.
      if (full || updatedUser.groupId != before.groupId) 'group_id': updatedUser.groupId,
      // users.tanggal_lahir (migration_notifications_v2.sql).
      if (full ? updatedUser.birthDate != null : !_sameDay(updatedUser.birthDate, before.birthDate)) 'tanggal_lahir': _isoDate(updatedUser.birthDate),
    };
    try {
      if (changes.isNotEmpty) {
        await _supabaseService
            .updateUserProfile(updatedUser.id, changes)
            .timeout(const Duration(seconds: 20));
      }
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } on TimeoutException {
      _lastMessage = 'Koneksi lambat. Periksa internet lalu coba lagi.';
      return false;
    } catch (e) {
      _lastMessage = 'Error updating profile: $e';
      return false;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final data = await _supabaseService.getAllUsers();
      _lastMessage = null;
      debugPrint('getAllUsers: fetched ${data.length} row(s)');
      final users = <User>[];
      for (final p in data) {
        try {
          users.add(userFromRow(p));
        } catch (e) {
          // Don't let one malformed row take down the entire admin user list.
          debugPrint('getAllUsers: skipped malformed row ${p['id']}: $e');
        }
      }
      return users;
    } catch (e) {
      _lastMessage = e.toString();
      debugPrint('getAllUsers error: $e');
      return [];
    }
  }

  Future<List<User>> getPendingUsers() async {
    try {
      final data = await _supabaseService.getPendingUsers();
      return data.map((p) => userFromRow(p)).toList();
    } catch (e) {
      _lastMessage = e.toString();
      return [];
    }
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    List<String> roles = const ['jemaat'],
    String? identityNumber,
    String? familyGroup,
    String? membershipType,
    String? address,
    String? memberCardNumber,
    String? memberSince,
    String? baptismDate,
    String? membershipStatus,
  }) async {
    final supabase = Supabase.instance.client;
    final adminRefreshToken = supabase.auth.currentSession?.refreshToken;
    final adminUserId = supabase.auth.currentUser?.id;

    // Suppress auth state events while we create the new user so the admin's
    // UI state is not replaced by the new (unverified) user's session.
    _suppressAuthEvents = true;
    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        nama: name,
        phone: phone,
      );

      if (response.user == null) {
        _lastMessage = 'Gagal membuat akun pengguna.';
        return false;
      }

      // If email confirmation is disabled Supabase auto-signs in the new user,
      // replacing the admin's session. Restore it before updating the profile.
      final nowUserId = supabase.auth.currentUser?.id;
      if (adminUserId != null &&
          nowUserId != adminUserId &&
          adminRefreshToken != null) {
        try {
          await supabase.auth.setSession(adminRefreshToken);
          await _loadUserData(adminUserId);
        } catch (e) {
          debugPrint('Admin session restore failed: $e');
          _lastMessage = 'Sesi admin tidak dapat dipulihkan. Silakan login ulang.';
          return false;
        }
      }

      // Admin only holds `users:create`: the new row is completed by a
      // permission-checked RPC instead of a direct UPDATE (which RLS now
      // reserves for Super Admin). Admins may only give jemaat/pelayan roles;
      // 'active' additionally needs `users:approve`.
      await _supabaseService.adminCompleteNewUser(
        userId: response.user!.id,
        roles: roles,
        status: membershipStatus ?? 'pending',
        profile: {
          'identity_number': identityNumber,
          'family_group': familyGroup,
          'address': address,
          'member_card_number': memberCardNumber,
          'member_since': memberSince,
          'baptism_date': baptismDate,
          'membership_type': membershipType,
        },
      );

      return true;
    } catch (e) {
      _lastMessage = _dbError(e);
      // Attempt to restore admin session even on error.
      final nowUserId = supabase.auth.currentUser?.id;
      if (adminUserId != null &&
          nowUserId != adminUserId &&
          adminRefreshToken != null) {
        try {
          await supabase.auth.setSession(adminRefreshToken);
          await _loadUserData(adminUserId);
        } catch (_) {}
      }
      return false;
    } finally {
      _suppressAuthEvents = false;
    }
  }

  /// Edits another member's full record — Super Admin only (RLS
  /// `users_update_own` + escalation trigger). Every column is written from
  /// [updatedUser], so the caller must pass a user loaded with all columns
  /// (see [userFromRow]) to avoid nulling fields such as membership_type.
  Future<bool> updateUser(User updatedUser) async {
    try {
      await _supabaseService.updateUserProfile(updatedUser.id, {
        'nama': updatedUser.name,
        'phone': updatedUser.phone,
        'roles': updatedUser.roles,
        'identity_number': updatedUser.identityNumber,
        'family_group': updatedUser.familyGroup,
        'member_card_number': updatedUser.memberCardNumber,
        'member_since': updatedUser.memberSince,
        'address': updatedUser.address,
        'baptism_date': updatedUser.baptismDate,
        'membership_status': updatedUser.membershipStatus,
        'membership_type': updatedUser.membershipType,
        'group_id': updatedUser.groupId,
      });
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _lastMessage = _dbError(e);
      return false;
    }
  }

  /// Changes only the roles column (Super Admin only, DB-enforced).
  Future<bool> updateUserRoles(String userId, List<String> roles) async {
    try {
      await _supabaseService.updateUserRoles(userId, roles);
      if (_currentUser?.id == userId) {
        _currentUser = _currentUser!.copyWith(roles: roles);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _lastMessage = _dbError(e);
      return false;
    }
  }

  /// Super Admin "removes" a member by deactivating the account
  /// (membership_status = 'inactive'). Deleting the login itself needs the
  /// service-role key, which never ships in the app; deactivation blocks
  /// sign-in and every RLS-gated write while keeping history intact.
  Future<bool> deactivateUser(String userId) =>
      setMemberStatus(userId: userId, status: 'inactive');

  /// Approve ('active') / reject ('rejected') a member — needs
  /// `users:approve`; other statuses are Super Admin only (RPC-enforced).
  Future<bool> setMemberStatus({required String userId, required String status}) async {
    try {
      await _supabaseService.setMemberStatus(userId, status);
      return true;
    } catch (e) {
      _lastMessage = _dbError(e);
      return false;
    }
  }

  Future<bool> verifyUser({required String userId, required bool approved}) =>
      setMemberStatus(userId: userId, status: approved ? 'active' : 'rejected');
}
