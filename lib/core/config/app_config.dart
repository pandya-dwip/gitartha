import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../errors/configuration_exception.dart';
import 'supabase_key_safety.dart';

/// The environment the app is running in, read from `APP_ENV`.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return AppEnvironment.development;
    for (final env in AppEnvironment.values) {
      if (env.name == value) return env;
    }
    throw ConfigurationException(
      'APP_ENV has an unknown value "$raw". '
      'Use one of: ${AppEnvironment.values.map((e) => e.name).join(', ')}.',
    );
  }
}

/// Supabase connection settings. Only the public, client-safe values live
/// here: the project URL and the publishable (anon) key.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  final String url;
  final String publishableKey;
}

/// Centralized, immutable application configuration.
///
/// Build it once at startup with [AppConfig.load] and read it through
/// `appConfigProvider`. Nothing else in the app should read environment
/// variables directly.
class AppConfig {
  const AppConfig._({
    required this.appName,
    required this.environment,
    required this.supabase,
  });

  /// Environment variable names.
  static const keyAppName = 'APP_NAME';
  static const keyAppEnv = 'APP_ENV';
  static const keySupabaseUrl = 'SUPABASE_URL';
  static const keySupabasePublishableKey = 'SUPABASE_PUBLISHABLE_KEY';

  /// Legacy name for the same publishable key; used only when
  /// [keySupabasePublishableKey] is empty.
  static const keySupabaseAnonKey = 'SUPABASE_ANON_KEY';

  static const _defaultAppName = 'Gitartha';

  final String appName;
  final AppEnvironment environment;

  /// `null` when Supabase credentials are not configured (allowed in
  /// development and staging).
  final SupabaseConfig? supabase;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
  bool get isSupabaseConfigured => supabase != null;

  /// Returns the Supabase settings, or throws a [ConfigurationException]
  /// explaining how to provide them. Use this at the point where a feature
  /// genuinely needs the backend.
  SupabaseConfig get requireSupabase {
    final config = supabase;
    if (config == null) {
      throw const ConfigurationException(
        'Supabase is not configured. Set $keySupabaseUrl and '
        '$keySupabasePublishableKey in .env (see .env.example).',
      );
    }
    return config;
  }

  /// Loads `.env` from the asset bundle and validates it.
  ///
  /// A missing or empty `.env` file is tolerated so that the app can run in
  /// local development mode with defaults.
  static Future<AppConfig> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName, isOptional: true);
    return AppConfig.fromMap(dotenv.env);
  }

  /// Builds and validates configuration from raw key/value pairs.
  factory AppConfig.fromMap(Map<String, String> env) {
    String? read(String key) {
      final value = env[key]?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final environment = AppEnvironment.parse(read(keyAppEnv));
    final supabase = _parseSupabase(
      url: read(keySupabaseUrl),
      key: read(keySupabasePublishableKey) ?? read(keySupabaseAnonKey),
    );

    if (supabase == null && environment == AppEnvironment.production) {
      throw const ConfigurationException(
        'Supabase configuration is required when APP_ENV=production. '
        'Set $keySupabaseUrl and $keySupabasePublishableKey in .env.',
      );
    }

    return AppConfig._(
      appName: read(keyAppName) ?? _defaultAppName,
      environment: environment,
      supabase: supabase,
    );
  }

  static SupabaseConfig? _parseSupabase({String? url, String? key}) {
    if (url == null && key == null) return null;

    if (url == null || key == null) {
      final missing = url == null ? keySupabaseUrl : keySupabasePublishableKey;
      throw ConfigurationException(
        'Incomplete Supabase configuration: $missing is empty. '
        'Set both $keySupabaseUrl and $keySupabasePublishableKey, '
        'or leave both empty to run without a backend.',
      );
    }

    final urlProblem = supabaseUrlProblem(url);
    if (urlProblem != null) {
      throw ConfigurationException('$keySupabaseUrl $urlProblem');
    }

    if (looksLikeSupabaseSecretKey(key)) {
      throw const ConfigurationException(
        'The Supabase key in .env is a secret / service-role key. '
        'Only the publishable (anon) key may be used in the app, because '
        'everything in .env ships inside the application bundle.',
      );
    }

    return SupabaseConfig(url: url, publishableKey: key);
  }
}
