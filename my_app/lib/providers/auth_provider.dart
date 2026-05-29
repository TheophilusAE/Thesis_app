import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _lastMessage;
  late String _currentDisplayRole = 'jemaat';

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get lastMessage => _lastMessage;
  bool get isAdmin => _currentUser?.hasRole('admin') ?? false;
  bool get isPelayan => _currentUser?.hasRole('pelayan') ?? false;
  bool get isJemaat => _currentUser?.hasRole('jemaat') ?? false;
  List<String> get userRoles => _currentUser?.roles ?? [];
  User? get user => _currentUser;
  String get currentDisplayRole => _currentDisplayRole;

  String _mapError(dynamic e) {
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
    if (msg.contains('rate_limit') || msg.contains('over_request_rate_limit')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa saat.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
      return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  void init() {
    _supabaseService.onAuthStateChange().listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _isLoggedIn = true;
        _loadUserData(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _isLoggedIn = false;
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
        _isLoggedIn = true;
        await _loadUserData(user.id);
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _currentDisplayRole = 'jemaat';
      }
    } catch (e) {
      _lastMessage = _mapError(e);
      _isLoggedIn = false;
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

      if (_currentUser!.hasRole('admin')) {
        _currentDisplayRole = 'admin';
      } else if (_currentUser!.hasRole('pelayan')) {
        _currentDisplayRole = 'pelayan';
      } else {
        _currentDisplayRole = 'jemaat';
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? identityNumber,
    String? familyGroup,
    String? address,
    String? baptismDate,
  }) async {
    _isLoading = true;
    _lastMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        nama: name,
        phone: phone,
        additionalData: {
          if (identityNumber != null && identityNumber.isNotEmpty)
            'identity_number': identityNumber,
          if (familyGroup != null && familyGroup.isNotEmpty)
            'family_group': familyGroup,
          if (address != null && address.isNotEmpty) 'address': address,
          if (baptismDate != null && baptismDate.isNotEmpty)
            'baptism_date': baptismDate,
        },
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
      _lastMessage =
          'Registrasi berhasil! Akun Anda sedang menunggu verifikasi admin. Anda dapat login setelah akun disetujui.';

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastMessage = _mapError(e);
      _isLoading = false;
      notifyListeners();
      return false;
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
    notifyListeners();

    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserData(response.user!.id);

        // Block accounts that haven't been verified by admin yet
        if (_currentUser?.membershipStatus == 'pending') {
          _isLoggedIn = false;
          _currentUser = null;
          _currentDisplayRole = 'jemaat';
          _lastMessage =
              'Akun Anda belum diverifikasi admin. Silakan tunggu persetujuan untuk dapat login.';
          try {
            await _supabaseService.signOut();
          } catch (_) {}
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _isLoggedIn = true;
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
          if (updatedUser.address != null) 'address': updatedUser.address,
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
    try {
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        nama: name,
        phone: phone,
      );
      if (response.user != null) {
        await _supabaseService.updateUserProfile(response.user!.id, {
          'roles': roles,
          'identity_number': identityNumber,
          'family_group': familyGroup,
          'address': address,
          'member_card_number': memberCardNumber,
          'member_since': memberSince,
          'baptism_date': baptismDate,
          'membership_status': membershipStatus ?? 'active',
        });
      }
      return true;
    } catch (e) {
      _lastMessage = e.toString();
      return false;
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
