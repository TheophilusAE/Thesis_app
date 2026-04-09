import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Mode Colors
  static const Color _lightPrimary = Color(0xFF58A77E); // Soft Green
  static const Color _lightSecondary = Color(0xFF73B995); // Mint Green
  static const Color _lightTertiary = Color(0xFF9BD5B8); // Light Mint
  static const Color _lightBackground = Color(0xFFF5FAF7); // Soft green-white
  static const Color _lightSurface = Color(0xFFFFFFFF); // White

  // Dark Mode Colors
  static const Color _darkPrimary = Color(0xFF63B487); // Green
  static const Color _darkSecondary = Color(0xFF7FC8A1); // Mint
  static const Color _darkTertiary = Color(0xFF9CD9BC); // Light mint
  static const Color _darkBackground = Color(0xFF10221A); // Dark green slate
  static const Color _darkSurface = Color(0xFF1B3328); // Deep green slate

  // Accent Colors
  static const Color accentPurple = Color(0xFF4FA77B); // Green Accent
  static const Color accentBlue = Color(0xFF73B995); // Mint Accent
  static const Color accentCyan = Color(0xFF9BD5B8); // Soft Accent
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color softCard = Color(0xFFF4F7FF);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(22));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  // Light Theme
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
      displayLarge: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
      displayMedium: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.45),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
      bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightSecondary,
        tertiary: _lightTertiary,
        surface: _lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: Color(0xFF1E293B),
        error: errorColor,
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFF1E293B),
        displayColor: const Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1E293B),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE9F5EE),
        selectedColor: const Color(0xFFD7EEDD),
        disabledColor: const Color(0xFFF1F5F9),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: textTheme.bodySmall?.copyWith(color: const Color(0xFF2E7D5A)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0.4,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimary,
          side: const BorderSide(color: _lightPrimary, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _lightPrimary,
        unselectedItemColor: Color(0xFF94A3B8),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 8,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
      displayLarge: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
      displayMedium: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.45),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
      bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary,
        tertiary: _darkTertiary,
        surface: _darkSurface,
        onPrimary: Color(0xFF0F172A),
        onSecondary: Color(0xFF0F172A),
        onTertiary: Color(0xFF0F172A),
        onSurface: Color(0xFFE2E8F0),
        error: errorColor,
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFFE2E8F0),
        displayColor: const Color(0xFFF1F5F9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0.4,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _darkSurface,
        selectedItemColor: Color(0xFFBFE6CF),
        unselectedItemColor: Color(0xFF64748B),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 8,
      ),
    );
  }

  // Gradient Backgrounds
  static const LinearGradient purpleBlueGradient = LinearGradient(
    colors: [Color(0xFF74BB96), Color(0xFF59A981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF89CCAA), Color(0xFF66B68D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF66B68D), Color(0xFF4FA77A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFFA4DCC2), Color(0xFF74BB96)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
