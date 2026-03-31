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

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;
  List<User> get pendingUsers => _pendingUsers;
  bool get isAdmin => _currentUser?.role == 'admin';

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      _currentUser = await _authService.getCurrentUser();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'jemaat',
    String? identityNumber,
    String? familyGroup,
    String? membershipType,
    String? address,
  }) async {
    _isLoading = true;
    _lastMessage = null;
    notifyListeners();

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      role: role,
      membershipStatus: role == 'admin' ? 'verified' : 'pending',
      identityNumber: identityNumber,
      familyGroup: familyGroup,
      membershipType: membershipType,
      memberCardNumber: 'MEM${DateTime.now().millisecondsSinceEpoch}',
      memberSince: DateTime.now().toString().substring(0, 10),
      address: address,
    );

    final result = await _authService.register(user, password);
    _lastMessage = result.message;

    if (result.success) {
      if (user.role == 'admin') {
        _currentUser = user;
        _isLoggedIn = true;
      } else {
        _currentUser = null;
        _isLoggedIn = false;
      }
    }

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
    final success = await _authService.updateUser(updatedUser);
    if (success) {
      _currentUser = updatedUser;
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

  Future<List<User>> getAllUsers() {
    return _authService.getAllUsers();
  }
}
