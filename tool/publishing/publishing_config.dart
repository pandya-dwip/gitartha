import 'dart:io';

import 'package:gitartha/core/config/supabase_key_safety.dart';

/// Supabase connection settings for the publisher, from environment
/// variables and/or the project's `.env` file (process environment wins).
///
/// | Variable | Required | Meaning |
/// |---|---|---|
/// | `SUPABASE_URL` | yes | Project URL, e.g. `https://<ref>.supabase.co` |
/// | `SUPABASE_PUBLISHABLE_KEY` | yes* | Publishable key (`sb_publishable_…`) |
/// | `SUPABASE_ANON_KEY` | *legacy | Used only if the above is unset (the app's existing variable) |
///
/// Privileged keys are **refused**: `sb_secret_…` keys and legacy
/// `service_role` JWTs. The key only identifies the project; write access
/// comes from the publisher's own session and RLS.
class PublishingConfig {
  const PublishingConfig._({
    required this.url,
    required this.publishableKey,
    required this.keyVariable,
  });

  final String url;
  final String publishableKey;

  /// Which variable the key came from (for display; never the key itself).
  final String keyVariable;

  /// The project host, safe to print and to store in reports.
  String get host => Uri.parse(url).host;

  static const String urlVariable = 'SUPABASE_URL';
  static const String publishableKeyVariable = 'SUPABASE_PUBLISHABLE_KEY';
  static const String legacyAnonKeyVariable = 'SUPABASE_ANON_KEY';

  /// Loads and validates the settings. Throws [PublishingConfigException]
  /// with a message that never includes a key's value.
  static PublishingConfig load({
    String envFile = '.env',
    Map<String, String>? environment,
  }) {
    final values = {
      ...readEnvFile(envFile),
      ...(environment ?? Platform.environment),
    };
    String? read(String name) {
      final v = values[name]?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    final url = read(urlVariable);
    if (url == null) {
      throw PublishingConfigException(
        '$urlVariable is not set. Add it to $envFile or the environment.',
      );
    }
    final urlProblem = supabaseUrlProblem(url);
    if (urlProblem != null) {
      throw PublishingConfigException('$urlVariable $urlProblem');
    }

    final publishable = read(publishableKeyVariable);
    final legacy = read(legacyAnonKeyVariable);
    final key = publishable ?? legacy;
    if (key == null) {
      throw const PublishingConfigException(
        '$publishableKeyVariable is not set (nor the legacy '
        '$legacyAnonKeyVariable). Use the project\'s publishable key.',
      );
    }
    final variable = publishable != null
        ? publishableKeyVariable
        : '$legacyAnonKeyVariable (legacy)';
    if (looksLikeSupabaseSecretKey(key)) {
      throw PublishingConfigException(
        '$variable contains a secret / service-role key. The publisher '
        'refuses privileged keys: it must act as you, under RLS. Use the '
        'publishable (anon) key instead.',
      );
    }
    return PublishingConfig._(
      url: url.endsWith('/') ? url.substring(0, url.length - 1) : url,
      publishableKey: key,
      keyVariable: variable,
    );
  }

  /// Parses `KEY=VALUE` lines (comments, blank lines and surrounding quotes
  /// allowed). A missing file is an empty map.
  static Map<String, String> readEnvFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return const {};
    final result = <String, String>{};
    for (final raw in file.readAsLinesSync()) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      var value = line.substring(eq + 1).trim();
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }
      result[line.substring(0, eq).trim()] = value;
    }
    return result;
  }
}

class PublishingConfigException implements Exception {
  const PublishingConfigException(this.message);

  final String message;

  @override
  String toString() => 'PublishingConfigException: $message';
}
