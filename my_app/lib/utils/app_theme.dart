import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GPDI brand palette and modern Light-First theme:
/// - GPDI Burgundy Red (#A62639) for authority, church identity, and active states
/// - Warm Gold (#C89B3C) for glory, achievements, and subtle accents
/// - Warm Ivory / White (#FFFDF8 / #FFFFFF) for clean, high-contrast, welcoming surfaces
/// - Near-black charcoal (#1F1F1F) for high readability across all generations
class AppTheme {
  // ── Official GPDI Brand Colours ─────────────────────────────
  static const Color primary       = Color(0xFFA62639); // GPDI Burgundy Red
  static const Color primaryDark   = Color(0xFF7D1D2B); // Deep Burgundy
  static const Color primaryLight  = Color(0xFFF4DEE2); // Soft Rose Tint
  static const Color secondary     = Color(0xFFC89B3C); // Warm Gold
  static const Color gold          = Color(0xFFC89B3C); // Warm Gold
  static const Color goldLight     = Color(0xFFF4E8C4); // Soft Gold Tint
  static const Color goldDark      = Color(0xFF9E7522); // Deep Gold
  static const Color accent        = Color(0xFFA62639); // Accent
  static const Color background    = Color(0xFFFFFDF8); // Warm Ivory Canvas
  static const Color surface       = Color(0xFFFFFFFF); // Crisp Card Surface
  static const Color surfaceSubtle = Color(0xFFF9F7F2); // Subtle Muted Container
  static const Color textColor     = Color(0xFF1F1F1F); // Dark Charcoal (High Contrast)
  static const Color darkCharcoal  = Color(0xFF1F1F1F); // Dark Charcoal Alias
  static const Color secondaryText = Color(0xFF555555); // Legible Mid-Tone
  static const Color mutedText     = Color(0xFF707070); // Accessible Muted
  static const Color mutedCharcoal = Color(0xFF707070); // Accessible Muted Charcoal
  static const Color borderColor   = Color(0xFFD9D9D9); // Standard Light Border
  static const Color neutralBorder = Color(0xFFE5E7EB); // 1px Clean Neutral Border
  static const Color neutralMedium = Color(0xFF6B7280); // Secondary Slate Medium
  static const Color neutralMuted  = Color(0xFF6B7280); // Neutral Muted Grey Alias
  static const Color neutralLight  = Color(0xFFF3F4F6); // Neutral Soft Background
  static const Color warmIvory     = Color(0xFFFFFDF8); // Warm Ivory Canvas
  static const Color emerald       = Color(0xFF10B981); // Fresh Vibrant Green
  static const Color burgundy      = Color(0xFFA62639); // GPDI Burgundy
  static const Color burgundyDark  = Color(0xFF7D1D2B); // Deep Burgundy

  // ── Semantic colours ───────────────────────────────────────
  static const Color successColor  = Color(0xFF287A52); // Forest Green
  static const Color success       = Color(0xFF287A52); // Success Alias
  static const Color successLight  = Color(0xFFE8F5EE);
  static const Color warningColor  = Color(0xFF9A6700); // Amber
  static const Color warning       = Color(0xFF9A6700); // Warning Alias
  static const Color warningLight  = Color(0xFFFEF8E7);
  static const Color errorColor    = Color(0xFFB42318); // Crimson Alert
  static const Color error         = Color(0xFFB42318); // Error Alias
  static const Color errorLight    = Color(0xFFFEE4E2);
  static const Color infoColor     = Color(0xFF356A9A); // Muted Serene Blue
  static const Color infoLight     = Color(0xFFEBF3FA);
  static const Color softCard      = Color(0xFFFAF6F0); // Warm soft surface

  // ── Shapes & Radii ─────────────────────────────────────────
  static const BorderRadius cardRadius  = BorderRadius.all(Radius.circular(16));
  static const BorderRadius dialogRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius pillRadius  = BorderRadius.all(Radius.circular(999));

  // ── Modern card decoration ──────────────────────────────────
  static BoxDecoration subtleCardDecoration({
    Color fill = Colors.white,
    BorderRadius? radius,
    Color borderColor = neutralBorder,
  }) =>
      BoxDecoration(
        color: fill,
        borderRadius: radius ?? cardRadius,
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  // ── Backward-compatible modern card & border tokens ─────────
  // Replaced harsh 2.5px black neo-brutalist borders with soft, elegant
  // 1px neutral borders and gentle, refined micro-elevation.
  static const Color retroBorderColor   = Color(0xFFE5E7EB);
  static const double retroBorderWidth  = 1.0;
  static const BorderRadius retroRadius = BorderRadius.all(Radius.circular(16));
  static const Offset retroShadowOffset = Offset(0, 3);

  static List<BoxShadow> retroShadow([Color color = const Color(0x0A000000)]) => [
        BoxShadow(
          color: color == Colors.black ? const Color(0x0C000000) : color.withValues(alpha: 0.08),
          offset: const Offset(0, 3),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ];

  static BoxDecoration retroCardDecoration({
    Color fill = Colors.white,
    Color borderColor = retroBorderColor,
    double borderWidth = retroBorderWidth,
    BorderRadius? radius,
    Color? shadowColor,
  }) =>
      BoxDecoration(
        color: fill,
        border: Border.all(
          color: borderColor == Colors.black ? const Color(0xFFE5E7EB) : borderColor,
          width: borderWidth > 1.5 ? 1.0 : borderWidth,
        ),
        borderRadius: radius ?? retroRadius,
        boxShadow: softShadow(shadowColor ?? const Color(0xFFA62639)),
      );

  // ── Shadows ────────────────────────────────────────────────
  static List<BoxShadow> softShadow([Color color = const Color(0xFFA62639)]) => [
        BoxShadow(
          color: const Color(0x0A000000),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> cardShadow() => const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 20,
          spreadRadius: -2,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Fonts Helper ───────────────────────────────────────────
  static TextStyle _display(double size, FontWeight weight) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: textColor);

  // ── Light Theme (Primary Experience) ───────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
      displayLarge:  _display(32, FontWeight.w700),
      displayMedium: _display(28, FontWeight.w700),
      headlineSmall: _display(22, FontWeight.w700),
      titleLarge:    _display(19, FontWeight.w600),
      titleMedium:   GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge:     GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: textColor),
      bodyMedium:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45, color: secondaryText),
      bodySmall:     GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: mutedText),
      labelLarge:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
      labelMedium:   GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary:              primary,
        onPrimary:            Colors.white,
        primaryContainer:     primaryLight,
        onPrimaryContainer:   primaryDark,
        secondary:            secondary,
        onSecondary:          Colors.white,
        secondaryContainer:   goldLight,
        onSecondaryContainer: Color(0xFF5C4108),
        tertiary:             infoColor,
        onTertiary:           Colors.white,
        surface:              surface,
        onSurface:            textColor,
        error:                errorColor,
        onError:              Colors.white,
        outline:              borderColor,
        outlineVariant:       Color(0xFFE5E7EB),
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme.apply(
        bodyColor:    textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textColor, size: 24),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryLight,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 26);
          }
          return const IconThemeData(color: mutedText, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedText,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEBE8E1), thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSubtle,
        selectedColor:   primaryLight,
        disabledColor:   const Color(0xFFF1F5F9),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: textTheme.bodySmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14.5,
          color: secondaryText,
          height: 1.45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
        labelStyle: GoogleFonts.poppins(color: secondaryText, fontSize: 15),
        hintStyle:  GoogleFonts.poppins(color: mutedText, fontSize: 15),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor:    primary,
        unselectedItemColor:  mutedText,
        selectedLabelStyle:   GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 8,
      ),
    );
  }

  // ── Dark Theme (Clean & Legible) ───────────────────────────
  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF141214);
    const darkSurface    = Color(0xFF1E1C1F);
    const darkBorder     = Color(0xFF2E2B30);
    const darkTextColor  = Color(0xFFF5F3F6);
    const darkTextMuted  = Color(0xFFA5A1A8);

    final textTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
      displayLarge:  _display(32, FontWeight.w700).copyWith(color: darkTextColor),
      displayMedium: _display(28, FontWeight.w700).copyWith(color: darkTextColor),
      headlineSmall: _display(22, FontWeight.w700).copyWith(color: darkTextColor),
      titleLarge:    _display(19, FontWeight.w600).copyWith(color: darkTextColor),
      titleMedium:   GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: darkTextColor),
      bodyLarge:     GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: darkTextColor),
      bodyMedium:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45, color: darkTextMuted),
      bodySmall:     GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: darkTextMuted),
      labelLarge:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: darkTextColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary:              Color(0xFFE56A7A), // Lighter red for dark theme contrast
        onPrimary:            Colors.black,
        primaryContainer:     Color(0xFF4A131A),
        onPrimaryContainer:   Color(0xFFFADAE0),
        secondary:            Color(0xFFE2B755),
        onSecondary:          Colors.black,
        secondaryContainer:   Color(0xFF4A3810),
        onSecondaryContainer: Color(0xFFF8E7BE),
        surface:              darkSurface,
        onSurface:            darkTextColor,
        error:                Color(0xFFF97066),
        outline:              darkBorder,
        outlineVariant:       Color(0xFF262328),
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: textTheme.apply(
        bodyColor:    darkTextColor,
        displayColor: darkTextColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: darkTextColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: darkBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: const Color(0xFF4A131A),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFE56A7A), size: 26);
          }
          return const IconThemeData(color: darkTextMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE56A7A),
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextMuted,
          );
        }),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkTextColor,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14.5,
          color: darkTextMuted,
          height: 1.45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE56A7A),
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE56A7A),
          side: const BorderSide(color: Color(0xFFE56A7A), width: 1.5),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFE56A7A),
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE56A7A), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF97066), width: 1.4),
        ),
      ),
    );
  }

  // ── Brand Gradients ─────────────────────────────────────────
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFA62639), Color(0xFF7D1D2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redDeepGradient = LinearGradient(
    colors: [Color(0xFF7D1D2B), Color(0xFF52111B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF4E8C4), Color(0xFFC89B3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmHeaderGradient = LinearGradient(
    colors: [Color(0xFFFFFDF8), Color(0xFFFDF6F4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Soft warm welcoming gradient for light surfaces & splash
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [Color(0xFFFFFDF8), Color(0xFFFAF1F2), Color(0xFFF6E4E7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy aliases for screens referencing older names
  static const LinearGradient blueGradient       = LinearGradient(
    colors: [Color(0xFF2C5E8A), Color(0xFF1E3A5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient purpleBlueGradient = redGradient;
  static const LinearGradient purpleGradient     = redDeepGradient;
  static const LinearGradient cyanGradient       = blueGradient;
  static const LinearGradient tealGradient       = blueGradient;
  static const LinearGradient headerGradient     = warmHeaderGradient;
}
