import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/config/app_config_provider.dart';
import '../data/local/local_database_providers.dart';
import '../features/authentication/data/secure_session_storage.dart';
import '../features/authentication/presentation/providers/auth_state_provider.dart';
import '../features/synchronization/presentation/providers/content_sync_provider.dart';
import 'app.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';

/// Starts Gitartha without ever blocking the first frame.
///
/// The startup screen is drawn immediately; configuration, Supabase and the
/// on-device database are prepared behind it, each with a time limit:
///  * Supabase slow or unreachable → the app opens without it (offline
///    reading works; sign-in shows as unavailable / retries later).
///  * Anything else failing → a clear message with "Try again", never a
///    blank screen.
class GitarthaStartup extends StatefulWidget {
  const GitarthaStartup({super.key});

  @override
  State<GitarthaStartup> createState() => _GitarthaStartupState();
}

class _GitarthaStartupState extends State<GitarthaStartup> {
  ProviderContainer? _container;
  Object? _error;
  AppLifecycleListener? _lifecycle;

  static const _supabaseTimeout = Duration(seconds: 12);
  static const _databaseTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _container?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    final watch = Stopwatch()..start();
    void step(String name) =>
        debugPrint('Startup: $name (${watch.elapsedMilliseconds} ms)');
    try {
      final config = await AppConfig.load();
      step('configuration loaded');
      final supabase = await _initializeSupabase(config);
      step(supabase == null ? 'Supabase unavailable' : 'Supabase ready');

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          supabaseClientProvider.overrideWithValue(supabase),
        ],
      );
      try {
        await container
            .read(appDatabaseProvider)
            .ensureInitialized()
            .timeout(_databaseTimeout);
      } on Object {
        container.dispose();
        rethrow;
      }
      step('database ready');

      // Content sync runs in the background and never blocks reading.
      final sync = container.read(contentSyncProvider.notifier);
      _lifecycle = AppLifecycleListener(onResume: sync.onAppResumed);
      if (!mounted) return container.dispose();
      setState(() => _container = container);
      step('app started');
    } on Object catch (error, stack) {
      debugPrint('Startup failed: $error\n$stack');
      if (mounted) setState(() => _error = error);
    }
  }

  /// Initializes Supabase and restores a persisted session. Returns null when
  /// Supabase is not configured, fails, or does not answer in time.
  static Future<SupabaseClient?> _initializeSupabase(AppConfig config) async {
    final settings = config.supabase;
    if (settings == null) return null;
    if (_supabaseReady) return Supabase.instance.client; // retry after error
    try {
      final instance = await Supabase.initialize(
        url: settings.url,
        publishableKey: settings.publishableKey,
        authOptions: const FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(),
        ),
      ).timeout(_supabaseTimeout);
      _supabaseReady = true;
      return instance.client;
    } on Object catch (e) {
      debugPrint('Supabase failed to initialize (${e.runtimeType}).');
      return null;
    }
  }

  static bool _supabaseReady = false;

  @override
  Widget build(BuildContext context) {
    final container = _container;
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: const GitarthaApp(),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light, // the default theme
      home: _StartupScreen(error: _error, onRetry: _start),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GitarthaLogo(size: 96),
              const SizedBox(height: AppSpacing.md),
              Text(
                'गीतार्थ',
                style: t.sanskrit.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (error == null)
                SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: c.accent,
                  ),
                )
              else ...[
                Text(
                  'Gitartha could not start',
                  style: t.headline.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your saved reflections and notes are safe. Please try '
                  'again; if this keeps happening, restart the phone.',
                  textAlign: TextAlign.center,
                  style: t.commentary.copyWith(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: t.ui.copyWith(fontSize: 11, color: c.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
