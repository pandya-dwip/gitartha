import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/core/config/app_config.dart';
import 'package:gitartha/core/errors/configuration_exception.dart';

String _jwtWithRole(String role) {
  String part(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'role': role})}.signature';
}

void main() {
  group('AppConfig.fromMap', () {
    test('uses development defaults when nothing is set', () {
      final config = AppConfig.fromMap(const {});

      expect(config.appName, 'Gitartha');
      expect(config.environment, AppEnvironment.development);
      expect(config.isSupabaseConfigured, isFalse);
    });

    test('treats empty values as unset', () {
      final config = AppConfig.fromMap(const {
        'APP_NAME': '',
        'APP_ENV': 'development',
        'SUPABASE_URL': '',
        'SUPABASE_ANON_KEY': '  ',
      });

      expect(config.appName, 'Gitartha');
      expect(config.isSupabaseConfigured, isFalse);
    });

    test('requireSupabase explains how to configure the backend', () {
      final config = AppConfig.fromMap(const {});

      expect(
        () => config.requireSupabase,
        throwsA(
          isA<ConfigurationException>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_URL'),
          ),
        ),
      );
    });

    test('reads a complete Supabase configuration', () {
      final config = AppConfig.fromMap({
        'APP_ENV': 'production',
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_ANON_KEY': _jwtWithRole('anon'),
      });

      expect(config.isProduction, isTrue);
      expect(config.requireSupabase.url, 'https://example.supabase.co');
    });

    test('rejects an unknown APP_ENV', () {
      expect(
        () => AppConfig.fromMap(const {'APP_ENV': 'prod'}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('requires Supabase in production', () {
      expect(
        () => AppConfig.fromMap(const {'APP_ENV': 'production'}),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('rejects a half-filled Supabase configuration', () {
      expect(
        () => AppConfig.fromMap(const {
          'SUPABASE_URL': 'https://example.supabase.co',
        }),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('rejects a non-https Supabase URL', () {
      expect(
        () => AppConfig.fromMap(const {
          'SUPABASE_URL': 'http://example.supabase.co',
          'SUPABASE_ANON_KEY': 'sb_publishable_abc',
        }),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('rejects secret and service-role keys', () {
      for (final key in ['sb_secret_abc', _jwtWithRole('service_role')]) {
        expect(
          () => AppConfig.fromMap({
            'SUPABASE_URL': 'https://example.supabase.co',
            'SUPABASE_ANON_KEY': key,
          }),
          throwsA(isA<ConfigurationException>()),
          reason: key,
        );
      }
    });

    test('prefers SUPABASE_PUBLISHABLE_KEY over the legacy anon key', () {
      final config = AppConfig.fromMap(const {
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_new',
        'SUPABASE_ANON_KEY': 'sb_publishable_old',
      });
      expect(config.requireSupabase.publishableKey, 'sb_publishable_new');
    });

    test('rejects a secret key in SUPABASE_PUBLISHABLE_KEY', () {
      expect(
        () => AppConfig.fromMap(const {
          'SUPABASE_URL': 'https://example.supabase.co',
          'SUPABASE_PUBLISHABLE_KEY': 'sb_secret_abc',
        }),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });
}
