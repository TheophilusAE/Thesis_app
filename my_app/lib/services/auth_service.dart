import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  Future<bool> register(User user, String password) async {
    try {
      // In a real app, this would call an API
      final prefs = await SharedPreferences.getInstance();
      
      // Store user data
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setBool(_isLoggedInKey, true);
      
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // In a real app, this would call an API
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      return true;
    } catch (e) {
      print('Update user error: $e');
      return false;
    }
  }
}
