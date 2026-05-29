import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colours (public) ─────────────────────────────────
  static const Color primary   = Color(0xFF1E3A5F); // Navy Blue
  static const Color secondary = Color(0xFFD4A017); // Soft Gold
  static const Color accent    = Color(0xFF60A5FA); // Light Blue

  // ── Light palette ──────────────────────────────────────────
  static const Color _lightPrimary    = Color(0xFF1E3A5F); // Navy Blue
  static const Color _lightSecondary  = Color(0xFFD4A017); // Soft Gold
  static const Color _lightTertiary   = Color(0xFF60A5FA); // Light Blue
  static const Color _lightBackground = Color(0xFFF8FAFC); // Off White
  static const Color _lightSurface    = Color(0xFFFFFFFF);

  // ── Dark palette ───────────────────────────────────────────
  static const Color _darkPrimary    = Color(0xFF60A5FA); // Light Blue (legible on dark)
  static const Color _darkSecondary  = Color(0xFFD4A017); // Soft Gold
  static const Color _darkTertiary   = Color(0xFF93C5FD); // Sky Blue 300
  static const Color _darkBackground = Color(0xFF0B1829); // Deep Navy
  static const Color _darkSurface    = Color(0xFF132035); // Dark Navy Surface

  // ── Semantic colours ───────────────────────────────────────
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor   = Color(0xFFEF4444);
  static const Color softCard     = Color(0xFFEFF6FF);

  // ── Shape ──────────────────────────────────────────────────
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  // ── Light Theme ────────────────────────────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
      displayLarge:  const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
      displayMedium: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge:    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium:   const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge:     const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.45),
      bodyMedium:    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
      bodySmall:     const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelLarge:    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary:             _lightPrimary,
        secondary:           _lightSecondary,
        tertiary:            _lightTertiary,
        surface:             _lightSurface,
        onPrimary:           Colors.white,
        onSecondary:         Colors.white,
        onTertiary:          Colors.white,
        onSurface:           Color(0xFF1F2937),
        error:               errorColor,
        primaryContainer:    Color(0xFFDEEAF8),
        onPrimaryContainer:  Color(0xFF1E3A5F),
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: textTheme.apply(
        bodyColor:    const Color(0xFF1F2937),
        displayColor: const Color(0xFF1F2937),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDEEAF8),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _lightPrimary);
          }
          return const IconThemeData(color: Color(0xFF94A3B8));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: _lightPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          );
        }),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFDEEAF8),
        selectedColor:   const Color(0xFFBDD4EE),
        disabledColor:   const Color(0xFFF1F5F9),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: textTheme.bodySmall?.copyWith(color: _lightPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimary,
          side: const BorderSide(color: _lightPrimary, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none,
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
        hintStyle:  const TextStyle(color: Color(0xFFCBD5E1)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor:    _lightPrimary,
        unselectedItemColor:  Color(0xFF94A3B8),
        selectedLabelStyle:   TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 8,
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
      displayLarge:  const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
      displayMedium: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge:    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium:   const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge:     const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.45),
      bodyMedium:    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
      bodySmall:     const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelLarge:    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary:             _darkPrimary,
        secondary:           _darkSecondary,
        tertiary:            _darkTertiary,
        surface:             _darkSurface,
        onPrimary:           Color(0xFF0B1829),
        onSecondary:         Color(0xFF0B1829),
        onTertiary:          Color(0xFF0B1829),
        onSurface:           Color(0xFFE2E8F0),
        error:               errorColor,
        primaryContainer:    Color(0xFF1E3A5F),
        onPrimaryContainer:  Color(0xFFDEEAF8),
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: textTheme.apply(
        bodyColor:    const Color(0xFFE2E8F0),
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
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkSurface,
        indicatorColor: const Color(0xFF1E3A5F),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _darkPrimary);
          }
          return const IconThemeData(color: Color(0xFF64748B));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: _darkPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B),
          );
        }),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: const Color(0xFF0B1829),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          side: const BorderSide(color: _darkPrimary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2E47),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        hintStyle:  const TextStyle(color: Color(0xFF64748B)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: _darkSurface,
        selectedItemColor:    _darkPrimary,
        unselectedItemColor:  Color(0xFF64748B),
        selectedLabelStyle:   TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 8,
      ),
    );
  }

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyDeepGradient = LinearGradient(
    colors: [Color(0xFF152B46), Color(0xFF1E3A5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy aliases — screens referencing these auto-update to the new palette
  static const LinearGradient purpleBlueGradient = navyGradient;
  static const LinearGradient purpleGradient     = navyDeepGradient;
  static const LinearGradient blueGradient       = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cyanGradient = tealGradient;
  static const LinearGradient headerGradient = navyGradient;
}
