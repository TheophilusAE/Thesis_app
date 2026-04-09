import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthOperationResult {
  final bool success;
  final String message;

  const AuthOperationResult({required this.success, required this.message});
}

class AuthService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _accountsKey = 'auth_accounts';

  Future<void> _seedAdminIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);

    if (raw != null) {
      final parsed = List<Map<String, dynamic>>.from(jsonDecode(raw));
      final hasAdmin = parsed.any(
        (entry) =>
            (entry['user'] as Map<String, dynamic>)['role']?.toString() ==
            'admin',
      );
      if (hasAdmin) {
        return;
      }
    }

    final adminUser = User(
      id: 'admin-1',
      name: 'Administrator Gereja',
      email: 'admin@gereja.local',
      phone: '0800000000',
      role: 'admin',
      membershipStatus: 'verified',
      memberCardNumber: 'ADM-0001',
      memberSince: DateTime.now().toIso8601String().split('T').first,
    );

    final accounts = await _getAccounts();
    accounts.add({
      'user': adminUser.toJson(),
      'password': 'admin123',
    });
    await _saveAccounts(accounts);
  }

  Future<List<Map<String, dynamic>>> _getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _saveAccounts(List<Map<String, dynamic>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<User?> _getCachedCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson == null) {
      return null;
    }

    return User.fromJson(jsonDecode(userJson));
  }

  Future<AuthOperationResult> register(User user, String password) async {
    return _createUserInternal(user, password, updateSession: true);
  }

  Future<AuthOperationResult> createUser(User user, String password) async {
    return _createUserInternal(user, password, updateSession: false);
  }

  Future<AuthOperationResult> _createUserInternal(
    User user,
    String password, {
    required bool updateSession,
  }) async {
    try {
      await _seedAdminIfNeeded();
      final accounts = await _getAccounts();
      final email = user.email.trim().toLowerCase();

      final emailAlreadyExists = accounts.any(
        (entry) =>
            ((entry['user'] as Map<String, dynamic>)['email'] as String)
                .toLowerCase() ==
            email,
      );

      if (emailAlreadyExists) {
        return const AuthOperationResult(
          success: false,
          message: 'Email sudah terdaftar.',
        );
      }

      final userToSave = user.copyWith(
        email: email,
        role: user.role,
        membershipStatus: user.role == 'admin' ? 'verified' : 'pending',
      );

      accounts.add({
        'user': userToSave.toJson(),
        'password': password,
      });

      await _saveAccounts(accounts);

      if (updateSession) {
        final prefs = await SharedPreferences.getInstance();
        if (userToSave.role == 'admin') {
          await prefs.setString(_userKey, jsonEncode(userToSave.toJson()));
          await prefs.setBool(_isLoggedInKey, true);
        } else {
          await prefs.remove(_userKey);
          await prefs.setBool(_isLoggedInKey, false);
        }
      }

      return AuthOperationResult(
        success: true,
        message: userToSave.membershipStatus == 'pending'
            ? 'Registrasi berhasil. Akun menunggu verifikasi admin.'
            : 'Registrasi berhasil.',
      );
    } catch (e) {
      debugPrint('Registration error: $e');
      return const AuthOperationResult(
        success: false,
        message: 'Terjadi kesalahan saat registrasi.',
      );
    }
  }

  Future<AuthOperationResult> login(String email, String password) async {
    try {
      await _seedAdminIfNeeded();
      final normalizedEmail = email.trim().toLowerCase();
      final accounts = await _getAccounts();
      final idx = accounts.indexWhere(
        (entry) =>
            ((entry['user'] as Map<String, dynamic>)['email'] as String)
                .toLowerCase() ==
            normalizedEmail,
      );

      if (idx == -1) {
        return const AuthOperationResult(
          success: false,
          message: 'Email belum terdaftar.',
        );
      }

      final account = accounts[idx];
      final savedPassword = account['password'] as String? ?? '';
      if (savedPassword != password) {
        return const AuthOperationResult(
          success: false,
          message: 'Password salah.',
        );
      }

      final user = User.fromJson(
        Map<String, dynamic>.from(account['user'] as Map),
      );

      if (user.role == 'jemaat' && user.membershipStatus != 'verified') {
        return const AuthOperationResult(
          success: false,
          message: 'Akun Anda belum diverifikasi admin.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setBool(_isLoggedInKey, true);

      return const AuthOperationResult(success: true, message: 'Login berhasil.');
    } catch (e) {
      debugPrint('Login error: $e');
      return const AuthOperationResult(
        success: false,
        message: 'Terjadi kesalahan saat login.',
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await _seedAdminIfNeeded();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _seedAdminIfNeeded();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      await _seedAdminIfNeeded();
      final currentUser = await _getCachedCurrentUser();
      if (currentUser == null || currentUser.role != 'admin') {
        debugPrint('Update user denied: admin access required.');
        return false;
      }

      final accounts = await _getAccounts();
      final idx = accounts.indexWhere(
        (entry) =>
            ((entry['user'] as Map<String, dynamic>)['id'] as String) ==
            user.id,
      );
      if (idx == -1) {
        return false;
      }

      final account = accounts[idx];
      accounts[idx] = {
        'user': user.toJson(),
        'password': account['password'],
      };
      await _saveAccounts(accounts);

      final prefs = await SharedPreferences.getInstance();
      if (currentUser.id == user.id) {
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
      }
      return true;
    } catch (e) {
      debugPrint('Update user error: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _seedAdminIfNeeded();
      final currentUser = await _getCachedCurrentUser();
      if (currentUser == null || currentUser.role != 'admin') {
        debugPrint('Delete user denied: admin access required.');
        return false;
      }

      final accounts = await _getAccounts();
      final before = accounts.length;
      accounts.removeWhere(
        (entry) =>
            ((entry['user'] as Map<String, dynamic>)['id'] as String) == userId,
      );

      if (accounts.length == before) {
        return false;
      }

      await _saveAccounts(accounts);

      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getString(_userKey);
      if (current != null) {
        final currentAccount = User.fromJson(jsonDecode(current));
        if (currentAccount.id == userId) {
          await prefs.remove(_userKey);
          await prefs.setBool(_isLoggedInKey, false);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Delete user error: $e');
      return false;
    }
  }

  Future<List<User>> getPendingUsers() async {
    await _seedAdminIfNeeded();
    final accounts = await _getAccounts();
    return accounts
        .map((entry) => User.fromJson(Map<String, dynamic>.from(entry['user'])))
        .where((user) => user.role == 'jemaat' && user.membershipStatus == 'pending')
        .toList();
  }

  Future<List<User>> getAllUsers() async {
    await _seedAdminIfNeeded();
    final accounts = await _getAccounts();
    return accounts
        .map((entry) => User.fromJson(Map<String, dynamic>.from(entry['user'])))
        .toList();
  }

  Future<bool> verifyUser({required String userId, required bool approved}) async {
    await _seedAdminIfNeeded();
    final accounts = await _getAccounts();
    final idx = accounts.indexWhere(
      (entry) =>
          ((entry['user'] as Map<String, dynamic>)['id'] as String) == userId,
    );
    if (idx == -1) {
      return false;
    }

    final userMap = Map<String, dynamic>.from(accounts[idx]['user'] as Map);
    userMap['membershipStatus'] = approved ? 'verified' : 'rejected';
    accounts[idx]['user'] = userMap;
    await _saveAccounts(accounts);

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_userKey);
    if (current != null) {
      final currentUser = User.fromJson(jsonDecode(current));
      if (currentUser.id == userId) {
        await prefs.setString(_userKey, jsonEncode(userMap));
      }
    }

    return true;
  }
}
