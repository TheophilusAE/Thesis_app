import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

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
  }) async {
    _isLoading = true;
    notifyListeners();

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      memberCardNumber: 'MEM${DateTime.now().millisecondsSinceEpoch}',
      memberSince: DateTime.now().toString().substring(0, 10),
    );

    final success = await _authService.register(user, password);

    if (success) {
      _currentUser = user;
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();

    return success;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _authService.login(email, password);

    if (success) {
      _isLoggedIn = true;
      _currentUser = await _authService.getCurrentUser();
    }

    _isLoading = false;
    notifyListeners();

    return success;
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
}
