import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF647D31);
  static const secondary = Color(0xFFE7A14B);
  static const tertiary = Color(0xFFD79059);
  static const background = Color(0xFFFFF2BB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF2E8D9);
  static const text = Color(0xFF13243B);
  static const mutedText = Color(0xFF64748B);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFE7A14B);
  static const error = Color(0xFFE25454);
  static const info = Color(0xFF3B82F6);

  static const primarySoft = Color(0xFFEFF6D6);
  static const successSoft = Color(0xFFE8F8F0);
  static const warningSoft = Color(0xFFFFF0D8);
  static const infoSoft = Color(0xFFEAF2FF);
  static const dangerSoft = Color(0xFFFFEAEA);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge:
            TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.18),
        headlineMedium:
            TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.22),
        headlineSmall:
            TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
        titleLarge:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
        titleMedium:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
        titleSmall:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.35),
        bodyLarge:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
        bodySmall:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.35),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(56, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size(56, 52),
          side: const BorderSide(color: AppColors.surfaceVariant),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
