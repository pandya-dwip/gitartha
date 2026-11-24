import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'data/local/local_database_providers.dart';
import 'features/authentication/data/secure_session_storage.dart';
import 'features/authentication/presentation/providers/auth_state_provider.dart';
import 'features/synchronization/presentation/providers/content_sync_provider.dart';

Future<void> main() async {
  // Bindings are needed before reading `.env` from the asset bundle.
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConfig.load();
  final supabase = await _initializeSupabase(config);

  // One container for the whole app, so the database opened here is the same
  // instance that widgets read later.
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      supabaseClientProvider.overrideWithValue(supabase),
    ],
  );

  // Open the on-device database and run migrations before the first frame.
  // A failure throws LocalDatabaseException with the original cause.
  await container.read(appDatabaseProvider).ensureInitialized();

  // Content sync runs in the background and never blocks reading: screens
  // render from SQLite immediately. The controller syncs once the restored
  // session's membership is confirmed (and on sign-in), and on resume.
  final sync = container.read(contentSyncProvider.notifier);
  AppLifecycleListener(onResume: sync.onAppResumed);

  runApp(
    UncontrolledProviderScope(container: container, child: const GitarthaApp()),
  );
}

/// Initializes Supabase and restores any persisted session (from secure
/// storage) before the first frame. Returns null when Supabase is not
/// configured or fails to start: the app still opens, offline reading data
/// stays intact, and sign-in shows as unavailable.
Future<SupabaseClient?> _initializeSupabase(AppConfig config) async {
  final settings = config.supabase;
  if (settings == null) return null;
  try {
    final instance = await Supabase.initialize(
      url: settings.url,
      publishableKey: settings.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
    return instance.client;
  } on Object catch (e) {
    debugPrint('Supabase failed to initialize (${e.runtimeType}).');
    return null;
  }
}
