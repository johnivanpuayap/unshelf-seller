import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

abstract class UnshelfTheme {
  static ThemeData light() {
    // Soft Editorial surface mapping: `surface` is the warm cream canvas
    // (background token) while `surfaceContainerHighest` is the honey-paper
    // raised layer (surface token). This intentional remap inverts the M3
    // default so cards/inputs sit *higher* than the page rather than tinted.
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: UnshelfTokens.colorLightPrimary,
      onPrimary: UnshelfTokens.colorLightOnPrimary,
      secondary: UnshelfTokens.colorLightAccent,
      onSecondary: UnshelfTokens.colorLightForeground,
      tertiary: UnshelfTokens.colorLightHighlight,
      error: UnshelfTokens.colorLightDestructive,
      onError: UnshelfTokens.colorLightOnPrimary,
      surface: UnshelfTokens.colorLightBackground,
      onSurface: UnshelfTokens.colorLightForeground,
      surfaceContainerHighest: UnshelfTokens.colorLightSurface,
      outline: UnshelfTokens.colorLightBorder,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UnshelfTokens.colorLightBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: UnshelfTokens.colorDarkPrimary,
      onPrimary: UnshelfTokens.colorDarkOnPrimary,
      secondary: UnshelfTokens.colorDarkAccent,
      onSecondary: UnshelfTokens.colorDarkForeground,
      tertiary: UnshelfTokens.colorDarkHighlight,
      error: UnshelfTokens.colorDarkDestructive,
      onError: UnshelfTokens.colorDarkOnPrimary,
      surface: UnshelfTokens.colorDarkBackground,
      onSurface: UnshelfTokens.colorDarkForeground,
      surfaceContainerHighest: UnshelfTokens.colorDarkSurface,
      outline: UnshelfTokens.colorDarkBorder,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UnshelfTokens.colorDarkBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
    );
  }

  static void preloadFonts() {
    GoogleFonts.dmSerifDisplay();
    GoogleFonts.dmSans();
  }

  static TextTheme _textTheme(Color onSurface) {
    TextStyle serif(
            {double? fontSize,
            FontWeight fontWeight = FontWeight.w400,
            double? height}) =>
        GoogleFonts.dmSerifDisplay(
          textStyle: TextStyle(
              color: onSurface,
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: height),
        );
    TextStyle sans(
            {double? fontSize,
            FontWeight fontWeight = FontWeight.w400,
            double? height}) =>
        GoogleFonts.dmSans(
          textStyle: TextStyle(
              color: onSurface,
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: height),
        );
    return TextTheme(
      displayLarge: serif(fontSize: 57, height: 1.12),
      displayMedium: serif(fontSize: 45, height: 1.16),
      displaySmall: serif(fontSize: 36, height: 1.22),
      headlineLarge: serif(fontSize: 32, height: 1.25),
      headlineMedium: serif(fontSize: 28, height: 1.29),
      headlineSmall: serif(fontSize: 24, height: 1.33),
      titleLarge: serif(fontSize: 22, height: 1.27),
      titleMedium:
          sans(fontSize: 16, fontWeight: FontWeight.w600, height: 1.50),
      titleSmall: sans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
      bodyLarge: sans(fontSize: 16, height: 1.50),
      bodyMedium: sans(fontSize: 14, height: 1.43),
      bodySmall: sans(fontSize: 12, height: 1.33),
      labelLarge: sans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
      labelMedium:
          sans(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
      labelSmall: sans(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme cs) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        isDense: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.dmSans(
          textStyle: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w400),
        ),
        labelStyle: GoogleFonts.dmSans(
          textStyle: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500),
        ),
        floatingLabelStyle: GoogleFonts.dmSans(
          textStyle: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: cs.outline.withValues(alpha: 0.6), width: 1.2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: cs.outline.withValues(alpha: 0.6), width: 1.2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: cs.error.withValues(alpha: 0.7), width: 1.4)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.error, width: 2)),
      );

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
        color: cs.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}

/// Deprecated compatibility shim bridging legacy [AppTheme] callers to the new
/// [UnshelfTheme] / [UnshelfTokens] API.
///
/// Numeric constants forward to [UnshelfTokens] where a matching token exists
/// (the 4/8/16/20/24/32/48 spacing scale and the 8/14/20/999 radius scale). The
/// `spacing12` and `radiusMedium` names are kept for compile-compatibility and
/// map to the nearest scale value (16 and 14 respectively) — Phase 4 will
/// replace these call sites with semantic [UnshelfTokens] references.
///
/// Elevations are not tokenized in the brand kit yet, so the values here are
/// hand-picked from the Material 3 elevation steps (0/2/6/12 dp).
@Deprecated(
  'Use UnshelfTheme / UnshelfTokens / Theme.of(context). '
  'To be removed when Phase 4 finishes redesigning screens.',
)
abstract class AppTheme {
  // ThemeData getters — forward to the new API.
  static ThemeData get lightTheme => UnshelfTheme.light();
  static ThemeData get darkTheme => UnshelfTheme.dark();

  // Spacing scale — aligned to UnshelfTokens (4/8/16/20/24/32/48).
  // spacing12 is not on the scale; map to spaceBase (16) so callers still
  // align to the design system. Phase 4 will adjust per-screen.
  static const double spacing4 = UnshelfTokens.spaceXs;
  static const double spacing8 = UnshelfTokens.spaceSm;
  static const double spacing12 = UnshelfTokens.spaceBase;
  static const double spacing16 = UnshelfTokens.spaceBase;
  static const double spacing24 = UnshelfTokens.spaceLg;
  static const double spacing32 = UnshelfTokens.spaceXl;
  static const double spacing48 = UnshelfTokens.space2xl;

  // Radius scale — aligned to UnshelfTokens (8/14/20/999).
  static const double radiusSmall = UnshelfTokens.radiusSm;
  static const double radiusMedium = UnshelfTokens.radiusBase;
  static const double radiusLarge = UnshelfTokens.radiusLg;
  static const double radiusFull = UnshelfTokens.radiusPill;

  // Elevation steps (Material 3 dp). Not tokenized yet.
  static const double elevationNone = 0;
  static const double elevationLow = 2;
  static const double elevationMedium = 6;
  static const double elevationHigh = 12;

  // Minimum touch target (WCAG 2.5.5 — 48 dp).
  static const double minTouchTarget = UnshelfTokens.space2xl;
}
