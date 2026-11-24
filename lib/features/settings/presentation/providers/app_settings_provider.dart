import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/daos/settings_dao.dart';
import '../../../../data/local/local_database_providers.dart';

/// Reader text sizes (code.html: S / M / L / XL "Serene").
enum ReaderFontSize {
  small('S', 'Small', 0.88),
  medium('M', 'Medium', 1.0),
  large('L', 'Large', 1.15),
  serene('XL', 'Serene', 1.3);

  const ReaderFontSize(this.label, this.title, this.scale);

  final String label;
  final String title;
  final double scale;

  ReaderFontSize get next => values[(index + 1) % values.length];

  static ReaderFontSize fromScale(Object? value) => values.firstWhere(
    (s) => s.scale == value,
    orElse: () => ReaderFontSize.medium,
  );
}

/// Stored in `local_settings` (`theme_mode`: "light" | "dark" | "system").
/// Light (warm ivory) is the default.
final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref
      .watch(localDatabaseRepositoryProvider)
      .watchSetting(LocalSettingKeys.themeMode)
      .map(
        (v) => switch (v) {
          'dark' => ThemeMode.dark,
          'system' => ThemeMode.system,
          // Light is the default until the reader chooses otherwise.
          _ => ThemeMode.light,
        },
      ),
);

/// Stored in `local_settings` (`body_font_scale`).
final readerFontSizeProvider = StreamProvider<ReaderFontSize>(
  (ref) => ref
      .watch(localDatabaseRepositoryProvider)
      .watchSetting(LocalSettingKeys.bodyFontScale)
      .map(ReaderFontSize.fromScale),
);

class AppSettingsActions {
  const AppSettingsActions(this._ref);

  final Ref _ref;

  /// Switches to the opposite of what is currently shown.
  Future<void> toggleTheme(Brightness current) => _ref
      .read(localDatabaseRepositoryProvider)
      .setSetting(
        LocalSettingKeys.themeMode,
        current == Brightness.dark ? 'light' : 'dark',
      );

  Future<ReaderFontSize> cycleFontSize() async {
    final next =
        (_ref.read(readerFontSizeProvider).value ?? ReaderFontSize.medium).next;
    await _ref
        .read(localDatabaseRepositoryProvider)
        .setSetting(LocalSettingKeys.bodyFontScale, next.scale);
    return next;
  }
}

final appSettingsActionsProvider = Provider<AppSettingsActions>(
  AppSettingsActions.new,
);
