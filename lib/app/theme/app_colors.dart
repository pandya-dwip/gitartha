import 'package:flutter/material.dart';

/// The Gitartha palette from DESIGN.md ("Sacred Illuminated Scripture").
///
/// Widgets read it with `context.colors` (see `app_theme.dart`); raw hex
/// values appear only here.
@immutable
class GitarthaColors extends ThemeExtension<GitarthaColors> {
  const GitarthaColors({
    required this.canvas,
    required this.well,
    required this.card,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.textSecondary,
    required this.border,
  });

  /// Warm ivory light theme (DESIGN.md → Color Tokens & Roles).
  static const light = GitarthaColors(
    canvas: Color(0xFFF7F3EA), // primary surface / canvas
    well: Color(0xFFEFE8DA), // aged parchment: wells, trays, headers
    card: Color(0xFFFFFDF8), // milk vellum: verse cards, modals
    accent: Color(0xFFB99A60), // antique gold
    onAccent: Color(0xFFFFFDF8),
    text: Color(0xFF493A2E), // deep scorched earth
    textSecondary: Color(0xFF796B5D), // muted sandalwood
    border: Color(0xFFE2D8C7), // woven linen
  );

  /// "Night Contemplation" (DESIGN.md → Dark Mode). Card and secondary text
  /// are not in DESIGN.md's dark list; they come from code.html.
  static const dark = GitarthaColors(
    canvas: Color(0xFF191817),
    well: Color(0xFF24211E),
    card: Color(0xFF211F1C),
    accent: Color(0xFFC3A46A),
    onAccent: Color(0xFF191817),
    text: Color(0xFFE9E0D1),
    textSecondary: Color(0xFFB9AA97),
    border: Color(0xFF36312B),
  );

  final Color canvas;
  final Color well;
  final Color card;
  final Color accent;
  final Color onAccent;
  final Color text;
  final Color textSecondary;
  final Color border;

  /// Soft gold wash, e.g. number badges and highlighted borders.
  Color get accentSoft => accent.withValues(alpha: 0.15);

  /// DESIGN.md "Soft Ambient Halo" for floating controls.
  List<BoxShadow> get halo => [
    BoxShadow(
      color: const Color(0xFF493A2E).withValues(alpha: 0.07),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: const Color(0xFFB99A60).withValues(alpha: 0.12),
      offset: const Offset(0, 2),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  @override
  GitarthaColors copyWith() => this;

  @override
  GitarthaColors lerp(GitarthaColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return GitarthaColors(
      canvas: mix(canvas, other.canvas),
      well: mix(well, other.well),
      card: mix(card, other.card),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      text: mix(text, other.text),
      textSecondary: mix(textSecondary, other.textSecondary),
      border: mix(border, other.border),
    );
  }
}
