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
import '../features/authentication/presentation/providers/member_access_provider.dart';
import '../features/synchronization/presentation/providers/content_sync_provider.dart';
import 'app.dart';
import 'motion/motion.dart';
import 'theme/app_theme.dart';
import 'widgets/gitartha_splash.dart';

/// Starts Gitartha behind a single splash (logo + name), without ever
/// blocking the first frame.
///
/// The native launch screens show only the canvas colour; the first frame
/// Flutter draws is [GitarthaSplash]. It stays up while configuration,
/// Supabase, the on-device database and the first membership check are
/// prepared (each with a time limit), then cross-fades into the app. Because
/// the router's own "checking access" screen uses the same splash, there is
/// never a second, different loading screen.
///
///  * Supabase slow or unreachable: the app opens without it.
///  * Anything else failing: a clear message with "Try again" under the
///    logo, never a blank screen.
class GitarthaStartup extends StatefulWidget {
  const GitarthaStartup({super.key});

  @override
  State<GitarthaStartup> createState() => _GitarthaStartupState();
}

class _GitarthaStartupState extends State<GitarthaStartup> {
  ProviderContainer? _container;
  Object? _error;
  AppLifecycleListener? _lifecycle;

  /// The app is prepared and may replace the splash.
  bool _ready = false;

  /// Startup is taking a while: show a gentle hint under the name.
  bool _slow = false;
  Timer? _slowTimer;
  final Completer<void> _entranceDone = Completer<void>();

  static const _supabaseTimeout = Duration(seconds: 12);
  static const _databaseTimeout = Duration(seconds: 20);

  /// Longest the splash waits for the first membership check. After that
  /// the router shows the same splash while the check finishes.
  static const _accessTimeout = Duration(seconds: 6);
  static const _slowAfter = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _lifecycle?.dispose();
    _container?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _slow = false;
    });
    _slowTimer?.cancel();
    _slowTimer = Timer(_slowAfter, () {
      if (mounted && !_ready) setState(() => _slow = true);
    });
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
      _container = container;

      // Keep the splash up for the first access check, so the router does
      // not open on a second loading screen; and let the entrance finish.
      await Future.wait([_waitForAccess(container), _entranceDone.future]);
      step('access resolved');
      if (!mounted) return;
      _slowTimer?.cancel();
      setState(() => _ready = true);
      step('app started');
    } on Object catch (error, stack) {
      debugPrint('Startup failed: $error\n$stack');
      if (mounted) setState(() => _error = error);
    }
  }

  /// Completes when the signed-in user's membership is no longer being
  /// loaded (or after [_accessTimeout]).
  static Future<void> _waitForAccess(ProviderContainer container) async {
    final resolved = Completer<void>();
    final sub = container.listen<AuthStatus>(authStatusProvider, (_, status) {
      if (status != AuthStatus.loadingMembership && !resolved.isCompleted) {
        resolved.complete();
      }
    }, fireImmediately: true);
    try {
      await resolved.future.timeout(_accessTimeout, onTimeout: () {});
    } finally {
      sub.close();
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
    final Widget current = _ready && container != null
        ? UncontrolledProviderScope(
            key: const ValueKey('app'),
            container: container,
            child: const GitarthaApp(),
          )
        : MaterialApp(
            key: const ValueKey('splash'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.light, // the default theme
            home: GitarthaSplash(
              onEntranceComplete: () {
                if (!_entranceDone.isCompleted) _entranceDone.complete();
              },
              footer: _error != null
                  ? _StartupError(error: _error!, onRetry: _start)
                  : _slow
                  ? const _SlowStartHint()
                  : null,
            ),
          );
    // One cross-fade from the splash into the app.
    return AnimatedSwitcher(
      duration: Motion.gentle,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      child: current,
    );
  }
}

class _SlowStartHint extends StatelessWidget {
  const _SlowStartHint();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            minHeight: 2,
            color: c.accent,
            backgroundColor: c.border,
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Text(
          'Preparing your library…',
          style: context.text.ui.copyWith(fontSize: 13, color: c.textSecondary),
        ),
      ],
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Gitartha could not start',
          style: t.headline.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your saved reflections and notes are safe. Please try again; if '
          'this keeps happening, restart the phone.',
          textAlign: TextAlign.center,
          style: t.commentary.copyWith(fontSize: 14, color: c.textSecondary),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$error',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: t.ui.copyWith(fontSize: 11, color: c.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.gutter),
        FilledButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
