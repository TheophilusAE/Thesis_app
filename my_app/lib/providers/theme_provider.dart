import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _fontSizeKey = 'app_font_size_factor';
  
  // Defaults to light — this app's audience skews elderly, and an
  // auto-switching dark theme was making text hard to read for them. Dark
  // mode is a manual choice (Profil / menu toggle), remembered per device.
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

    _applyBrightness();
    notifyListeners();
  }

  bool get isDark =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  /// Points the `AppTheme.*` tokens at the active palette, matches the status
  /// bar icons and rebuilds every widget — including `const` subtrees, which a
  /// plain notifyListeners() would skip — so no screen keeps stale colours.
  void _applyBrightness() {
    final dark = isDark;
    if (AppTheme.isDark == dark) return;
    AppTheme.setDark(dark);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light, // iOS
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark, // Android
    ));
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    void markAll(Element e) {
      e.markNeedsBuild();
      e.visitChildren(markAll);
    }
    root.visitChildren(markAll);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _applyBrightness();
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
