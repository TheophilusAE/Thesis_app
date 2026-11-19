import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// GPDI brand palette and modern Light-First theme:
/// - GPDI Burgundy Red (#A62639) for authority, church identity, and active states
/// - Warm Gold (#C89B3C) for glory, achievements, and subtle accents
/// - Warm Ivory / White (#FFFDF8 / #FFFFFF) for clean, high-contrast, welcoming surfaces
/// - Near-black charcoal (#1F1F1F) for high readability across all generations
class AppTheme {
  // ── Light / dark switch ────────────────────────────────────
  // The neutral tokens below (canvas, surfaces, text, borders, tints) and the
  // burgundy accent resolve against the active brightness, so the screens
  // that read `AppTheme.*` directly follow dark mode without per-widget
  // `isDark` checks. ThemeProvider calls [setDark] and then rebuilds the tree.
  static bool _dark = false;
  static bool get isDark => _dark;
  static void setDark(bool value) => _dark = value;
  static Color _pick(Color light, Color dark) => _dark ? dark : light;

  // Light palette (const, used by [lightTheme]).
  static const Color _lPrimary       = Color(0xFFA62639); // GPDI Burgundy Red
  static const Color _lPrimaryLight  = Color(0xFFF4DEE2); // Soft Rose Tint
  static const Color _lGoldLight     = Color(0xFFF4E8C4); // Soft Gold Tint
  static const Color _lBackground    = Color(0xFFFFFDF8); // Warm Ivory Canvas
  static const Color _lSurface       = Color(0xFFFFFFFF); // Crisp Card Surface
  static const Color _lSurfaceSubtle = Color(0xFFF9F7F2); // Subtle Muted Container
  static const Color _lText          = Color(0xFF1F1F1F); // Dark Charcoal
  static const Color _lSecondaryText = Color(0xFF555555); // Legible Mid-Tone
  static const Color _lMutedText     = Color(0xFF707070); // Accessible Muted
  static const Color _lBorder        = Color(0xFFD9D9D9); // Standard Light Border
  static const Color _lNeutralBorder = Color(0xFFE5E7EB); // 1px Clean Neutral Border
  static const Color _lNeutralMedium = Color(0xFF6B7280); // Slate Medium
  static const Color _lNeutralLight  = Color(0xFFF3F4F6); // Neutral Soft Background
  static const Color _lError         = Color(0xFFB42318);
  static const Color _lInfo          = Color(0xFF356A9A);

  // Dark palette (const, used by [darkTheme]).
  static const Color _dPrimary       = Color(0xFFD04A5E); // Burgundy lifted for dark (~4.3:1 on canvas and under white text)
  static const Color _dPrimaryLight  = Color(0xFF3D1A21);
  static const Color _dGoldLight     = Color(0xFF3A2E14);
  static const Color _dBackground    = Color(0xFF141214);
  static const Color _dSurface       = Color(0xFF1E1C1F);
  static const Color _dSurfaceSubtle = Color(0xFF262328);
  static const Color _dText          = Color(0xFFF5F3F6);
  static const Color _dSecondaryText = Color(0xFFC9C5CC);
  static const Color _dMutedText     = Color(0xFFA5A1A8);
  static const Color _dBorder        = Color(0xFF3A363C);
  static const Color _dNeutralBorder = Color(0xFF2E2B30);

  // ── Official GPDI Brand Colours ─────────────────────────────
  static Color get primary        => _pick(_lPrimary, _dPrimary);
  static const Color primaryDark  = Color(0xFF7D1D2B); // Deep Burgundy (fills/gradients)
  static Color get primaryLight   => _pick(_lPrimaryLight, _dPrimaryLight);
  static const Color secondary    = Color(0xFFC89B3C); // Warm Gold
  static const Color gold         = Color(0xFFC89B3C); // Warm Gold
  static Color get goldLight      => _pick(_lGoldLight, _dGoldLight);
  static const Color goldDark     = Color(0xFF9E7522); // Deep Gold
  static Color get accent         => primary;
  static Color get background     => _pick(_lBackground, _dBackground);
  static Color get surface        => _pick(_lSurface, _dSurface);
  static Color get surfaceSubtle  => _pick(_lSurfaceSubtle, _dSurfaceSubtle);
  static Color get textColor      => _pick(_lText, _dText);
  static Color get darkCharcoal   => textColor; // "main text" alias
  static Color get secondaryText  => _pick(_lSecondaryText, _dSecondaryText);
  static Color get mutedText      => _pick(_lMutedText, _dMutedText);
  static Color get mutedCharcoal  => mutedText;
  static Color get borderColor    => _pick(_lBorder, _dBorder);
  static Color get neutralBorder  => _pick(_lNeutralBorder, _dNeutralBorder);
  static Color get neutralMedium  => _pick(_lNeutralMedium, _dMutedText);
  static Color get neutralMuted   => neutralMedium;
  static Color get neutralLight   => _pick(_lNeutralLight, _dSurfaceSubtle);
  static Color get warmIvory      => background;
  static const Color emerald      = Color(0xFF10B981); // Fresh Vibrant Green
  static Color get burgundy       => primary;
  static const Color burgundyDark = Color(0xFF7D1D2B); // Deep Burgundy

  // ── Semantic colours ───────────────────────────────────────
  // Strong tones are lifted in dark mode so they read on dark surfaces while
  // still carrying white text (>= 3:1); tints follow the theme.
  static Color get successColor   => _pick(const Color(0xFF287A52), const Color(0xFF3E9E6E)); // Forest Green
  static Color get success        => successColor;
  static Color get successLight   => _pick(const Color(0xFFE8F5EE), const Color(0xFF16301F));
  static Color get warningColor   => _pick(const Color(0xFF9A6700), const Color(0xFFC58A12)); // Amber
  static Color get warning        => warningColor;
  static Color get warningLight   => _pick(const Color(0xFFFEF8E7), const Color(0xFF33280F));
  static Color get errorColor     => _pick(const Color(0xFFB42318), const Color(0xFFE0504A)); // Crimson Alert
  static Color get error          => errorColor;
  static Color get errorLight     => _pick(const Color(0xFFFEE4E2), const Color(0xFF3A1A18));
  static Color get infoColor      => _pick(const Color(0xFF356A9A), const Color(0xFF4F8CC6)); // Muted Serene Blue
  static Color get infoLight      => _pick(const Color(0xFFEBF3FA), const Color(0xFF172636));
  /// Navy accent used for text/icons (lifted in dark mode for contrast).
  static Color get navy           => _pick(const Color(0xFF1E3A8A), const Color(0xFF8AB4F8));
  static Color get softCard       => _pick(const Color(0xFFFAF6F0), _dSurfaceSubtle);

  // ── Shapes & Radii ─────────────────────────────────────────
  static const BorderRadius cardRadius  = BorderRadius.all(Radius.circular(16));
  static const BorderRadius dialogRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius pillRadius  = BorderRadius.all(Radius.circular(999));

  // ── Modern card decoration ──────────────────────────────────
  static BoxDecoration subtleCardDecoration({
    Color? fill,
    BorderRadius? radius,
    Color? borderColor,
  }) =>
      BoxDecoration(
        color: fill ?? surface,
        borderRadius: radius ?? cardRadius,
        border: Border.all(color: borderColor ?? neutralBorder),
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
  static Color get retroBorderColor => neutralBorder;
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
    Color? fill,
    Color? borderColor,
    double borderWidth = retroBorderWidth,
    BorderRadius? radius,
    Color? shadowColor,
  }) =>
      BoxDecoration(
        color: fill ?? surface,
        border: Border.all(
          color: borderColor == null || borderColor == Colors.black ? neutralBorder : borderColor,
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
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: _lText);

  // ── Light Theme (Primary Experience) ───────────────────────
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
      displayLarge:  _display(32, FontWeight.w700),
      displayMedium: _display(28, FontWeight.w700),
      headlineSmall: _display(22, FontWeight.w700),
      titleLarge:    _display(19, FontWeight.w600),
      titleMedium:   GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: _lText),
      bodyLarge:     GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: _lText),
      bodyMedium:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45, color: _lSecondaryText),
      bodySmall:     GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _lMutedText),
      labelLarge:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _lText),
      labelMedium:   GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _lSecondaryText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary:              _lPrimary,
        onPrimary:            Colors.white,
        primaryContainer:     _lPrimaryLight,
        onPrimaryContainer:   primaryDark,
        secondary:            secondary,
        onSecondary:          Colors.white,
        secondaryContainer:   _lGoldLight,
        onSecondaryContainer: Color(0xFF5C4108),
        tertiary:             _lInfo,
        onTertiary:           Colors.white,
        surface:              _lSurface,
        onSurface:            _lText,
        error:                _lError,
        onError:              Colors.white,
        outline:              _lBorder,
        outlineVariant:       Color(0xFFE5E7EB),
      ),
      scaffoldBackgroundColor: _lBackground,
      textTheme: textTheme.apply(
        bodyColor:    _lText,
        displayColor: _lText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _lText,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: _lText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _lText, size: 24),
      ),
      cardTheme: const CardThemeData(
        color: _lSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: _lPrimaryLight,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _lPrimary, size: 26);
          }
          return const IconThemeData(color: _lMutedText, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _lPrimary,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _lMutedText,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEBE8E1), thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: _lSurfaceSubtle,
        selectedColor:   _lPrimaryLight,
        disabledColor:   const Color(0xFFF1F5F9),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: textTheme.bodySmall?.copyWith(color: _lText, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lSurface,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _lText,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14.5,
          color: _lSecondaryText,
          height: 1.45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lPrimary,
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
          foregroundColor: _lPrimary,
          side: const BorderSide(color: _lPrimary, width: 1.5),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lPrimary,
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
          borderSide: const BorderSide(color: _lBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _lBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _lPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _lError, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _lError, width: 1.8),
        ),
        labelStyle: GoogleFonts.poppins(color: _lSecondaryText, fontSize: 15),
        hintStyle:  GoogleFonts.poppins(color: _lMutedText, fontSize: 15),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor:    _lPrimary,
        unselectedItemColor:  _lMutedText,
        selectedLabelStyle:   GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 8,
      ),
    );
  }

  // ── Dark Theme (Clean & Legible) ───────────────────────────
  static ThemeData get darkTheme {
    const darkBackground = _dBackground;
    const darkSurface    = _dSurface;
    const darkBorder     = _dNeutralBorder;
    const darkTextColor  = _dText;
    const darkTextMuted  = _dMutedText;
    const darkPrimary    = _dPrimary;

    final textTheme = GoogleFonts.poppinsTextTheme(const TextTheme()).copyWith(
      displayLarge:  _display(32, FontWeight.w700).copyWith(color: darkTextColor),
      displayMedium: _display(28, FontWeight.w700).copyWith(color: darkTextColor),
      headlineSmall: _display(22, FontWeight.w700).copyWith(color: darkTextColor),
      titleLarge:    _display(19, FontWeight.w600).copyWith(color: darkTextColor),
      titleMedium:   GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: darkTextColor),
      bodyLarge:     GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: darkTextColor),
      bodyMedium:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45, color: _dSecondaryText),
      bodySmall:     GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: darkTextMuted),
      labelLarge:    GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: darkTextColor),
      labelMedium:   GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _dSecondaryText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary:              darkPrimary,
        onPrimary:            Colors.white,
        primaryContainer:     _dPrimaryLight,
        onPrimaryContainer:   Color(0xFFFADAE0),
        secondary:            Color(0xFFE2B755),
        onSecondary:          Colors.black,
        secondaryContainer:   _dGoldLight,
        onSecondaryContainer: Color(0xFFF8E7BE),
        tertiary:             Color(0xFF7FB0E0),
        onTertiary:           Colors.black,
        surface:              darkSurface,
        onSurface:            darkTextColor,
        onSurfaceVariant:     _dSecondaryText,
        surfaceContainerHighest: _dSurfaceSubtle,
        error:                Color(0xFFF97066),
        onError:              Colors.black,
        outline:              _dBorder,
        outlineVariant:       darkBorder,
      ),
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      iconTheme: const IconThemeData(color: darkTextColor),
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
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: darkTextColor, size: 24),
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
        indicatorColor: _dPrimaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary, size: 26);
          }
          return const IconThemeData(color: darkTextMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkPrimary,
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkSurface,
        selectedItemColor:    darkPrimary,
        unselectedItemColor:  darkTextMuted,
        selectedLabelStyle:   GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
        elevation: 8,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        modalBackgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _dSurfaceSubtle,
        surfaceTintColor: Colors.transparent,
        textStyle: GoogleFonts.poppins(fontSize: 14.5, color: darkTextColor),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: const TimePickerThemeData(backgroundColor: darkSurface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _dSurfaceSubtle,
        contentTextStyle: GoogleFonts.poppins(fontSize: 14, color: darkTextColor),
        actionTextColor: const Color(0xFFE2B755),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      listTileTheme: const ListTileThemeData(iconColor: _dSecondaryText, textColor: darkTextColor),
      chipTheme: ChipThemeData(
        backgroundColor: _dSurfaceSubtle,
        selectedColor:   _dPrimaryLight,
        disabledColor:   darkSurface,
        side: const BorderSide(color: darkBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: textTheme.bodySmall?.copyWith(color: darkTextColor, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkTextColor,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14.5,
          color: _dSecondaryText,
          height: 1.45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
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
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkPrimary, width: 1.5),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _dSurfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _dBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _dBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF97066), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF97066), width: 1.8),
        ),
        labelStyle: GoogleFonts.poppins(color: _dSecondaryText, fontSize: 15),
        hintStyle:  GoogleFonts.poppins(color: darkTextMuted, fontSize: 15),
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

  static LinearGradient get warmHeaderGradient => LinearGradient(
    colors: _dark
        ? const [_dBackground, Color(0xFF1A1618)]
        : const [Color(0xFFFFFDF8), Color(0xFFFDF6F4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Soft warm welcoming gradient for light surfaces & splash
  static LinearGradient get auroraGradient => LinearGradient(
    colors: _dark
        ? const [_dBackground, Color(0xFF1C1517), Color(0xFF261A1D)]
        : const [Color(0xFFFFFDF8), Color(0xFFFAF1F2), Color(0xFFF6E4E7)],
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
  static LinearGradient get headerGradient => warmHeaderGradient;
}
