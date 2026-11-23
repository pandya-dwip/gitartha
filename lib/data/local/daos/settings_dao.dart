import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/local_settings.dart';

part 'settings_dao.g.dart';

/// Well-known setting keys. Other keys are allowed, but prefer adding them
/// here so they are discoverable.
abstract final class LocalSettingKeys {
  /// `"system"`, `"light"` or `"dark"`.
  static const String themeMode = 'theme_mode';
  static const String sanskritFontScale = 'sanskrit_font_scale';
  static const String bodyFontScale = 'body_font_scale';
  static const String showTransliteration = 'show_transliteration';
  static const String showHindi = 'show_hindi';
  static const String showEnglish = 'show_english';
  static const String lastOpenedShlokaId = 'last_opened_shloka_id';
}

/// Device-local preferences, stored as JSON values.
///
/// Credentials, tokens and keys must never be stored here: Supabase keeps
/// its session in its own storage, and secret keys never reach the app.
/// Keys that look like secrets are rejected.
@DriftAccessor(tables: [LocalSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  static final RegExp _secretLikeKey = RegExp(
    r'(password|passwd|secret|token|credential|api_?key|anon_?key|service_?role|jwt)',
    caseSensitive: false,
  );

  /// Stores [value], which must be JSON-encodable (String, num, bool, null,
  /// List or Map). Overwrites any previous value for [key].
  Future<void> setValue(String key, Object? value) {
    _checkKey(key);
    final encoded = jsonEncode(value);
    return into(localSettings).insertOnConflictUpdate(
      LocalSettingsCompanion.insert(
        key: key,
        value: encoded,
        updatedAt: attachedDatabase.now(),
      ),
    );
  }

  /// The decoded value for [key], or null if it is not set.
  Future<Object?> getValue(String key) async {
    final row = await _row(key).getSingleOrNull();
    return row == null ? null : jsonDecode(row.value);
  }

  /// Emits the decoded value for [key] whenever it changes.
  Stream<Object?> watchValue(String key) => _row(key).watchSingleOrNull().map(
    (row) => row == null ? null : jsonDecode(row.value),
  );

  /// Deletes [key]. Returns false if it was not set.
  Future<bool> deleteValue(String key) async =>
      await (delete(localSettings)..where((s) => s.key.equals(key))).go() > 0;

  /// Every setting, decoded, keyed by setting key.
  Future<Map<String, Object?>> getAll() async {
    final rows = await select(localSettings).get();
    return {for (final row in rows) row.key: jsonDecode(row.value)};
  }

  // Typed helpers. They return null when the key is unset; they throw
  // FormatException if the stored value has a different type.

  Future<void> setString(String key, String value) => setValue(key, value);
  Future<void> setBool(String key, bool value) => setValue(key, value);
  Future<void> setInt(String key, int value) => setValue(key, value);
  Future<void> setDouble(String key, double value) => setValue(key, value);
  Future<void> setJson(String key, Map<String, Object?> value) =>
      setValue(key, value);

  Future<String?> getString(String key) => _typed<String>(key);
  Future<bool?> getBool(String key) => _typed<bool>(key);
  Future<int?> getInt(String key) => _typed<int>(key);

  Future<double?> getDouble(String key) async =>
      (await _typed<num>(key))?.toDouble();

  Future<Map<String, Object?>?> getJson(String key) async =>
      (await _typed<Map<String, dynamic>>(key))?.cast<String, Object?>();

  Future<T?> _typed<T>(String key) async {
    final value = await getValue(key);
    if (value == null || value is T) return value as T?;
    throw FormatException('Setting "$key" holds ${value.runtimeType}, not $T');
  }

  SimpleSelectStatement<$LocalSettingsTable, LocalSetting> _row(String key) =>
      select(localSettings)..where((s) => s.key.equals(key));

  void _checkKey(String key) {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'must not be empty');
    }
    if (_secretLikeKey.hasMatch(key)) {
      throw ArgumentError.value(
        key,
        'key',
        'looks like a credential; secrets must not be stored in local settings',
      );
    }
  }
}
