import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized Material 3 light and dark themes.
///
/// Bundled Devanagari and English fonts will be wired in here once the font
/// files are added under `assets/fonts/`.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    accent: AppColors.lightAccent,
    onAccent: AppColors.lightOnAccent,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    accent: AppColors.darkAccent,
    onAccent: AppColors.darkOnAccent,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color accent,
    required Color onAccent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: onAccent,
          surface: background,
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
