import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// DESIGN.md spacing scale (mobile values; 1rem = 16 px).
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 36.0;

  /// Mobile page margin ("margin-mobile", 1.25rem).
  static const page = 20.0;

  /// Space between list items ("gutter-mobile").
  static const gutter = 12.0;

  /// Maximum reading width on tablets/foldables (DESIGN.md: 680px).
  static const maxReadingWidth = 680.0;
}

/// Corner radii. Softer than DESIGN.md's original 4–8 px at the owner's
/// request ("smooth, not sharp"); closer to code.html's rounded-2xl cards.
abstract final class AppRadii {
  static const sm = 12.0; // number badges, small tiles
  static const md = 16.0; // buttons, inputs, icon buttons, banners
  static const lg = 22.0; // cards, dialogs
  static const xl = 28.0; // sheets, the auth card, pills
}

/// DESIGN.md type scale ("-mobile" variants, as the app is mobile-first).
@immutable
class GitarthaText extends ThemeExtension<GitarthaText> {
  const GitarthaText({
    required this.display,
    required this.sanskrit,
    required this.headline,
    required this.translation,
    required this.commentary,
    required this.transliteration,
    required this.meta,
    required this.ui,
  });

  factory GitarthaText.of(GitarthaColors c) => GitarthaText(
    display: TextStyle(
      fontFamily: AppFonts.serif,
      fontFamilyFallback: AppFonts.serifFallback,
      fontSize: 26,
      height: 36 / 26,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.26,
      color: c.text,
    ),
    sanskrit: TextStyle(
      fontFamily: AppFonts.devanagari,
      fontFamilyFallback: const [AppFonts.serif],
      fontSize: 19,
      height: 32 / 19,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.29,
      color: c.text,
    ),
    headline: TextStyle(
      fontFamily: AppFonts.serif,
      fontFamilyFallback: AppFonts.serifFallback,
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      color: c.text,
    ),
    translation: TextStyle(
      fontFamily: AppFonts.serif,
      fontFamilyFallback: AppFonts.serifFallback,
      fontSize: 16,
      height: 28 / 16,
      color: c.text,
    ),
    commentary: TextStyle(
      fontFamily: AppFonts.serif,
      fontFamilyFallback: AppFonts.serifFallback,
      fontSize: 15,
      height: 25 / 15,
      color: c.text,
    ),
    // Italics only for Latin transliteration (DESIGN.md italics policy).
    transliteration: TextStyle(
      fontFamily: AppFonts.serif,
      fontFamilyFallback: AppFonts.serifFallback,
      fontSize: 14,
      height: 22 / 14,
      letterSpacing: 0.28,
      fontStyle: FontStyle.italic,
      color: c.text,
    ),
    meta: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.72,
      color: c.textSecondary,
    ),
    ui: TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
      color: c.text,
    ),
  );

  /// Page titles.
  final TextStyle display;

  /// Devanagari verse text.
  final TextStyle sanskrit;

  /// Section and card titles.
  final TextStyle headline;

  /// Hindi and English meanings.
  final TextStyle translation;

  /// Context, lesson, spiritual meaning, summaries.
  final TextStyle commentary;

  /// Latin transliteration (italic).
  final TextStyle transliteration;

  /// Small uppercase tags: verse numbers, section labels.
  final TextStyle meta;

  /// Functional interface text: buttons, navigation, captions.
  final TextStyle ui;

  @override
  GitarthaText copyWith() => this;

  @override
  GitarthaText lerp(GitarthaText? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return GitarthaText(
      display: mix(display, other.display),
      sanskrit: mix(sanskrit, other.sanskrit),
      headline: mix(headline, other.headline),
      translation: mix(translation, other.translation),
      commentary: mix(commentary, other.commentary),
      transliteration: mix(transliteration, other.transliteration),
      meta: mix(meta, other.meta),
      ui: mix(ui, other.ui),
    );
  }
}

/// Bundled font families (see pubspec.yaml).
abstract final class AppFonts {
  static const serif = 'NotoSerif';
  static const devanagari = 'NotoSerifDevanagari';
  static const sans = 'PlusJakartaSans';

  /// Latin serif text that contains Devanagari falls back to the matching
  /// serif Devanagari face.
  static const serifFallback = [devanagari];
}

extension GitarthaThemeContext on BuildContext {
  GitarthaColors get colors => Theme.of(this).extension<GitarthaColors>()!;
  GitarthaText get text => Theme.of(this).extension<GitarthaText>()!;
}

/// Centralized Material 3 light and dark themes built from DESIGN.md.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, GitarthaColors.light);

  static ThemeData get dark => _build(Brightness.dark, GitarthaColors.dark);

  static ThemeData _build(Brightness brightness, GitarthaColors c) {
    final text = GitarthaText.of(c);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.accent,
          brightness: brightness,
        ).copyWith(
          primary: c.accent,
          onPrimary: c.onAccent,
          secondary: c.textSecondary,
          surface: c.canvas,
          onSurface: c.text,
          onSurfaceVariant: c.textSecondary,
          surfaceContainerLowest: c.card,
          surfaceContainerLow: c.card,
          surfaceContainer: c.well,
          surfaceContainerHigh: c.well,
          surfaceContainerHighest: c.well,
          outline: c.textSecondary,
          outlineVariant: c.border,
          error: brightness == Brightness.light
              ? const Color(0xFFBA1A1A)
              : const Color(0xFFFFB4AB),
        );
    final control = BorderRadius.circular(AppRadii.md);
    final buttonText = text.ui.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.canvas,
      fontFamily: AppFonts.serif,
      fontFamilyFallback: AppFonts.serifFallback,
      extensions: [c, text],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.textSecondary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.headline.copyWith(fontSize: 17),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.accent.withValues(alpha: 0.4),
          disabledForegroundColor: c.onAccent,
          shape: RoundedRectangleBorder(borderRadius: control),
          padding: buttonPadding,
          minimumSize: const Size(48, 48),
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.card,
          foregroundColor: c.text,
          side: BorderSide(color: c.accent),
          shape: RoundedRectangleBorder(borderRadius: control),
          padding: buttonPadding,
          minimumSize: const Size(48, 48),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: buttonText,
          minimumSize: const Size(48, 44),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        hintStyle: text.commentary.copyWith(
          color: c.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        labelStyle: text.ui.copyWith(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: control,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: control,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: control,
          borderSide: BorderSide(color: c.accent, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.accent.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.ui.copyWith(
            fontSize: 11,
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.textSecondary,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: c.border),
        ),
        titleTextStyle: text.headline,
        contentTextStyle: text.commentary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.text,
        contentTextStyle: text.ui.copyWith(color: c.canvas),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      // Smooth fade-through between pages on Android; native on iOS.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.accent),
        trackColor: WidgetStatePropertyAll(c.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.border,
      ),
    );
  }
}
