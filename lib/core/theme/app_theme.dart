import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_borders.dart';

/// App theme configuration using Material 3.
class AppTheme {
  AppTheme._();

  static const Color _primary = Color(0xFF03A9F4);
  static const Color _accent = Color(0xFF9EEFFD);
  static const Color _surfaceLight = Color(0xFFF4F4F4);
  static const Color _surfaceDark = Color(0xFF171717);
  static const Color _outlineDark = Color(0xFF616161);

  static ThemeData get lightTheme {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      secondary: _accent,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme.copyWith(
        primary: _primary,
        secondary: _accent,
        surface: _surfaceLight,
        surfaceContainerLowest: _surfaceLight,
      ),
      textTheme: _textThemeFor(Brightness.light),
      primaryTextTheme: _textThemeFor(Brightness.light),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(48, AppBorders.inputButtonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(48, AppBorders.inputButtonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, AppBorders.inputButtonHeight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppBorders.borderRadius),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadius,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadius,
          side: BorderSide(
            color: lightScheme.primary.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: AppBorders.borderRadius,
            ),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
            bottom: Radius.circular(24),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  static ThemeData get darkTheme {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
      primary: _primary,
      secondary: _accent,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkScheme.copyWith(
        primary: _primary,
        secondary: _accent,
        surface: _surfaceDark,
        surfaceContainerLowest: const Color(0xFF0D0D0D),
        surfaceContainerHigh: const Color(0xFF252525),
        outline: _outlineDark,
        outlineVariant: _outlineDark.withValues(alpha: 0.7),
        onSurface: const Color(0xFFE8E8E8),
        onSurfaceVariant: const Color(0xFFB0B0B0),
      ),
      textTheme: _textThemeFor(Brightness.dark),
      primaryTextTheme: _textThemeFor(Brightness.dark),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(48, AppBorders.inputButtonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(48, AppBorders.inputButtonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppBorders.borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, AppBorders.inputButtonHeight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppBorders.borderRadius),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadius,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadius,
          side: BorderSide(
            color: darkScheme.primary.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: AppBorders.borderRadius,
            ),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
            bottom: Radius.circular(24),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  /// Resolves Google Font futures so the first frame does not use system fallback.
  static Future<void> preloadFonts() async {
    _textThemeFor(Brightness.light);
    _textThemeFor(Brightness.dark);
    await GoogleFonts.pendingFonts();
  }

  static TextTheme _textThemeFor(Brightness brightness) {
    final material = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme;
    final tuned = material.copyWith(
      displayLarge: material.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: material.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: material.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: material.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: material.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: material.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: material.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: material.bodyMedium?.copyWith(fontSize: 14),
      bodySmall: material.bodySmall?.copyWith(fontSize: 12),
      labelLarge: material.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
    return GoogleFonts.spaceGroteskTextTheme(tuned);
  }
}
