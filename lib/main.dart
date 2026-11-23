import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'data/local/local_database_providers.dart';

Future<void> main() async {
  // Bindings are needed before reading `.env` from the asset bundle.
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConfig.load();

  // One container for the whole app, so the database opened here is the same
  // instance that widgets read later.
  final container = ProviderContainer(
    overrides: [appConfigProvider.overrideWithValue(config)],
  );

  // Open the on-device database and run migrations before the first frame.
  // A failure throws LocalDatabaseException with the original cause.
  await container.read(appDatabaseProvider).ensureInitialized();

  runApp(
    UncontrolledProviderScope(container: container, child: const GitarthaApp()),
  );
}
