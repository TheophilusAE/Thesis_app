import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _fontSizeKey = 'app_font_size_factor';
  
  // Defaults to light — this app's audience skews elderly, and an
  // auto-switching dark theme was making text hard to read for them.
  // Kept as a settable ThemeMode (not hardcoded to light in main.dart) so a
  // manual dark-mode toggle can still be reintroduced later if wanted.
  ThemeMode _themeMode = ThemeMode.light;
  double _fontSizeFactor = 1.0;

  ThemeProvider() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  double get fontSizeFactor => _fontSizeFactor;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedTheme,
        orElse: () => ThemeMode.light,
      );
    }

    final savedScale = prefs.getDouble(_fontSizeKey);
    if (savedScale != null) {
      _fontSizeFactor = savedScale.clamp(0.85, 1.4);
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  Future<void> setFontSizeFactor(double factor) async {
    _fontSizeFactor = factor.clamp(0.85, 1.4);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSizeFactor);
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}
