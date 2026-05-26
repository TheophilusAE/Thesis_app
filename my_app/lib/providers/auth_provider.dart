import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _lastMessage;
  List<User> _pendingUsers = [];
  late String _currentDisplayRole; // Track which role is currently being displayed

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;
  List<User> get pendingUsers => _pendingUsers;
  bool get isAdmin => _currentUser?.hasRole('admin') ?? false;
  bool get isPelayan => _currentUser?.hasRole('pelayan') ?? false;
  bool get isJemaat => _currentUser?.hasRole('jemaat') ?? false;
  List<String> get userRoles => _currentUser?.roles ?? [];
  User? get user => _currentUser;
  String get currentDisplayRole => _currentDisplayRole;
  
  /// Switch the currently displayed role
  void switchRole(String role) {
    if (userRoles.contains(role)) {
      _currentDisplayRole = role;
      notifyListeners();
    }
  }

  /// Load all users for admin management
  Future<List<User>> getAllUsers() {
    return _authService.getAllUsers();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      _currentUser = await _authService.getCurrentUser();
      // Initialize display role
      if (_currentUser != null) {
        if (_currentUser!.hasRole('admin')) {
          _currentDisplayRole = 'admin';
        } else if (_currentUser!.hasRole('pelayan')) {
          _currentDisplayRole = 'pelayan';
        } else {
          _currentDisplayRole = 'jemaat';
        }
      } else {
        _currentDisplayRole = 'jemaat';
      }
      final isBlockedMember =
          _currentUser?.hasRole('jemaat') ?? false &&
          _currentUser?.membershipStatus != 'verified';
      if (isBlockedMember) {
        await _authService.logout();
        _currentUser = null;
        _isLoggedIn = false;
        _lastMessage = 'Akun Anda belum diverifikasi admin.';
      }
    } else {
      // Initialize to default when not logged in
      _currentDisplayRole = 'jemaat';
    }

    _isLoading = false;
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

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      roles: const ['jemaat'], // Default to jemaat role
      membershipStatus: 'pending',
      identityNumber: identityNumber,
      familyGroup: familyGroup,
      memberCardNumber: 'MEM${DateTime.now().millisecondsSinceEpoch}',
      memberSince: DateTime.now().toString().substring(0, 10),
      address: address,
      baptismDate: baptismDate,
    );

    final result = await _authService.register(user, password);
    _lastMessage = result.message;

    if (result.success) {
      _currentUser = null;
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();

    return result.success;
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
    String membershipStatus = 'pending',
  }) async {
    _isLoading = true;
    _lastMessage = null;
    notifyListeners();

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      roles: roles,
      membershipStatus: membershipStatus,
      identityNumber: identityNumber,
      familyGroup: familyGroup,
      membershipType: membershipType,
      memberCardNumber: memberCardNumber ?? 'MEM${DateTime.now().millisecondsSinceEpoch}',
      memberSince: memberSince ?? DateTime.now().toString().substring(0, 10),
      address: address,
      baptismDate: baptismDate,
    );

    final result = await _authService.createUser(user, password);
    _lastMessage = result.message;

    _isLoading = false;
    notifyListeners();

    return result.success;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _lastMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);
    _lastMessage = result.message;

    if (result.success) {
      _isLoggedIn = true;
      _currentUser = await _authService.getCurrentUser();
      // Set initial display role (priority: admin > pelayan > jemaat)
      if (_currentUser != null) {
        if (_currentUser!.hasRole('admin')) {
          _currentDisplayRole = 'admin';
        } else if (_currentUser!.hasRole('pelayan')) {
          _currentDisplayRole = 'pelayan';
        } else {
          _currentDisplayRole = 'jemaat';
        }
      }
    }

    _isLoading = false;
    notifyListeners();

    return result.success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile(User updatedUser) async {
    return updateUser(updatedUser);
  }

  Future<bool> updateUser(User updatedUser) async {
    final success = await _authService.updateUser(updatedUser);
    if (success && _currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteUser(String userId) async {
    final success = await _authService.deleteUser(userId);
    if (success && _currentUser?.id == userId) {
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> loadPendingUsers() async {
    _pendingUsers = await _authService.getPendingUsers();
    notifyListeners();
  }

  Future<bool> verifyUser({required String userId, required bool approved}) async {
    final success = await _authService.verifyUser(userId: userId, approved: approved);
    if (success) {
      await loadPendingUsers();
    }
    return success;
  }
}
