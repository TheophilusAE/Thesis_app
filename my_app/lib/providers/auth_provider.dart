import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/supabase_service.dart';

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

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get blockedStatus => _blockedStatus;
  String? get lastRawError => _lastRawError;
  bool get isInitializing => _isInitializing;
  String? get lastMessage => _lastMessage;
  bool get isAdmin => _currentUser?.hasRole('admin') ?? false;
  /// True only when the account really holds the admin role AND the admin
  /// view is active (an admin who switched to Jemaat/Pelayan view is not in
  /// admin mode). Use this for admin-only UI and route guards.
  bool get isAdminMode => isAdmin && _currentDisplayRole == 'admin';
  bool get isPelayan => _currentUser?.hasRole('pelayan') ?? false;
  bool get isJemaat => _currentUser?.hasRole('jemaat') ?? false;
  List<String> get userRoles => _currentUser?.roles ?? [];
  User? get user => _currentUser;
  String get currentDisplayRole => _currentDisplayRole;

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

  /// Statuses treated as approved. 'verified' is a legacy value the admin
  /// screen already normalizes to 'active'.
  static bool isApprovedStatus(String status) =>
      status == 'active' || status == 'verified';

  /// Single access gate: only approved accounts (or admins) count as logged
  /// in; anything else with a session is held on the waiting screen.
  void _applyAccessGate() {
    final user = _currentUser;
    if (user == null) {
      _isLoggedIn = false;
      _blockedStatus = null;
      return;
    }
    final approved = user.hasRole('admin') || isApprovedStatus(user.membershipStatus);
    _isLoggedIn = approved;
    _blockedStatus = approved ? null : user.membershipStatus;
  }

  void init() {
    _supabaseService.onAuthStateChange().listen((data) {
      if (_suppressAuthEvents) return;
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadUserData(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _isLoggedIn = false;
        _blockedStatus = null;
        _currentUser = null;
        _currentDisplayRole = 'jemaat';
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
        _isLoggedIn = false;
        _blockedStatus = null;
        _currentUser = null;
        _currentDisplayRole = 'jemaat';
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
        _currentUser = User(
          id: profileData['id'] ?? userId,
          name: profileData['nama'] ?? '',
          email: profileData['email'] ?? '',
          phone: profileData['phone'] ?? '',
          roles: List<String>.from(profileData['roles'] ?? ['jemaat']),
          membershipStatus: profileData['membership_status'] ?? 'pending',
          identityNumber: profileData['identity_number'],
          familyGroup: profileData['family_group'],
          memberCardNumber: profileData['member_card_number'],
          memberSince: profileData['member_since'],
          address: profileData['address'],
          baptismDate: profileData['baptism_date'],
        );
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

      if (_currentUser!.hasRole('admin')) {
        _currentDisplayRole = 'admin';
      } else if (_currentUser!.hasRole('pelayan')) {
        _currentDisplayRole = 'pelayan';
      } else {
        _currentDisplayRole = 'jemaat';
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Without a verified profile we cannot prove approval: fail closed.
      _currentUser = null;
      _isLoggedIn = false;
      _blockedStatus = null;
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

        // Block accounts admin has not approved (pending) or has rejected.
        final blocked = _blockedStatus;
        if (blocked != null || _currentUser == null) {
          _isLoggedIn = false;
          _blockedStatus = null;
          _currentUser = null;
          _currentDisplayRole = 'jemaat';
          _lastMessage = blocked == 'rejected'
              ? 'Pendaftaran akun Anda ditolak. Silakan hubungi admin gereja.'
              : 'Akun Anda belum diverifikasi admin. Silakan tunggu persetujuan untuk dapat login.';
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
    try {
      await _supabaseService.signOut();
    } catch (e) {
      _lastMessage = 'Error logout: $e';
    }
    _isLoggedIn = false;
    _blockedStatus = null;
    _currentUser = null;
    _currentDisplayRole = 'jemaat';
    notifyListeners();
  }

  Future<bool> updateProfile(User updatedUser) async {
    try {
      await _supabaseService.updateUserProfile(
        updatedUser.id,
        {
          'nama': updatedUser.name,
          'phone': updatedUser.phone,
          // Extended Jemaat data is optional: blank -> NULL, never a placeholder.
          'address': updatedUser.address,
          'identity_number': updatedUser.identityNumber,
          'family_group': updatedUser.familyGroup,
          'baptism_date': updatedUser.baptismDate,
        },
      );
      _currentUser = updatedUser;
      notifyListeners();
      return true;
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
          users.add(User(
            id: p['id'] ?? '',
            name: p['nama'] ?? '',
            email: p['email'] ?? '',
            phone: p['phone'] ?? '',
            roles: List<String>.from(p['roles'] ?? ['jemaat']),
            membershipStatus: p['membership_status'] ?? 'pending',
            identityNumber: p['identity_number'],
            familyGroup: p['family_group'],
            memberCardNumber: p['member_card_number'],
            memberSince: p['member_since'],
            address: p['address'],
            baptismDate: p['baptism_date'],
          ));
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
      return data
          .map((p) => User(
                id: p['id'] ?? '',
                name: p['nama'] ?? '',
                email: p['email'] ?? '',
                phone: p['phone'] ?? '',
                roles: List<String>.from(p['roles'] ?? ['jemaat']),
                membershipStatus: p['membership_status'] ?? 'pending',
                identityNumber: p['identity_number'],
                familyGroup: p['family_group'],
                memberCardNumber: p['member_card_number'],
                memberSince: p['member_since'],
                address: p['address'],
                baptismDate: p['baptism_date'],
              ))
          .toList();
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

      await _supabaseService.updateUserProfile(response.user!.id, {
        'roles': roles,
        'identity_number': identityNumber,
        'family_group': familyGroup,
        'address': address,
        'member_card_number': memberCardNumber,
        'member_since': memberSince,
        'baptism_date': baptismDate,
        'membership_status': membershipStatus ?? 'active',
        'membership_type': membershipType,
      });

      return true;
    } catch (e) {
      _lastMessage = e.toString();
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
      });
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _lastMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateUserRoles(String userId, List<String> roles) async {
    try {
      await _supabaseService.updateUserRoles(userId, roles);
      return true;
    } catch (e) {
      _lastMessage = e.toString();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _supabaseService.deleteUserProfile(userId);
      return true;
    } catch (e) {
      _lastMessage = e.toString();
      return false;
    }
  }

  Future<void> loadPendingUsers() async {
    // Exposed as getPendingUsers() — call that instead
  }

  Future<bool> verifyUser({required String userId, required bool approved}) async {
    try {
      await _supabaseService.verifyUser(userId, approved: approved);
      return true;
    } catch (e) {
      _lastMessage = e.toString();
      return false;
    }
  }
}
