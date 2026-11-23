import 'package:flutter/material.dart';

/// The Gitartha colour palette. Reference these through the theme's
/// [ColorScheme] in widgets; use this class only when building themes.
abstract final class AppColors {
  // Light
  static const lightBackground = Color(0xFFF7F3EA);
  static const lightAccent = Color(0xFFB99A60);
  static const lightTextPrimary = Color(0xFF493A2E);
  static const lightTextSecondary = Color(0xFF7A6A58); // muted warm brown
  static const lightOnAccent = Color(0xFF2B2118);

  // Dark
  static const darkBackground = Color(0xFF191817);
  static const darkAccent = Color(0xFFC3A46A);
  static const darkTextPrimary = Color(0xFFE9E0D1);
  static const darkTextSecondary = Color(0xFFB3A794);
  static const darkOnAccent = Color(0xFF191817);
}
