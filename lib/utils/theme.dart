import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:unshelf_seller/utils/colors.dart';

/// Centralized theme for Unshelf Seller app.
/// Uses Material 3 with a teal/emerald primary palette.
class AppTheme {
  AppTheme._();

  // ─── Spacing scale (8dp grid) ───
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing48 = 48;

  // ─── Border radius scale ───
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusFull = 100;

  // ─── Elevation scale ───
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 2;
  static const double elevationHigh = 4;

  // ─── Touch target minimum ───
  static const double minTouchTarget = 48;

  // ─── Light theme ───
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.light,
      primary: AppColors.primaryColor,
      onPrimary: Colors.white,
      secondary: AppColors.darkColor,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF1C1B1F),
      surfaceContainerHighest: const Color(0xFFF5F5F5),
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.jost(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ─── Cards ───
      cardTheme: CardThemeData(
        elevation: elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),

      // ─── Elevated buttons ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: elevationLow,
        ),
      ),

      // ─── Outlined buttons ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          minimumSize: const Size(double.infinity, minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          side: const BorderSide(color: AppColors.primaryColor),
          textStyle: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Text buttons ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          minimumSize: const Size(0, minTouchTarget),
          textStyle: GoogleFonts.jost(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Input decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.jost(
          fontSize: 14,
          color: const Color(0xFF757575),
        ),
        hintStyle: GoogleFonts.jost(
          fontSize: 14,
          color: const Color(0xFF9E9E9E),
        ),
        errorStyle: GoogleFonts.jost(
          fontSize: 12,
          color: AppColors.error,
        ),
      ),

      // ─── Bottom navigation ───
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: const Color(0xFF9E9E9E),
        selectedLabelStyle: GoogleFonts.jost(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.jost(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ─── Floating action button ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: GoogleFonts.jost(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1B1F),
        ),
      ),

      // ─── Snackbar ───
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 0,
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5F5F5),
        selectedColor: AppColors.primaryColor.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.jost(fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: BorderSide.none,
      ),

      // ─── ListTile ───
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing4,
        ),
        minVerticalPadding: spacing8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // ─── Tab bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: const Color(0xFF757575),
        indicatorColor: AppColors.primaryColor,
        labelStyle: GoogleFonts.jost(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.jost(fontSize: 14),
      ),
    );
  }

  // ─── Text theme ───
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display
      displayLarge: GoogleFonts.jost(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.jost(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      displaySmall: GoogleFonts.jost(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),

      // Headline
      headlineLarge: GoogleFonts.jost(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.jost(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.jost(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),

      // Title
      titleLarge: GoogleFonts.jost(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.jost(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.jost(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),

      // Body
      bodyLarge: GoogleFonts.jost(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.jost(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.jost(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF757575),
        height: 1.5,
      ),

      // Label
      labelLarge: GoogleFonts.jost(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      labelMedium: GoogleFonts.jost(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelSmall: GoogleFonts.jost(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF757575),
      ),
    );
  }
}
