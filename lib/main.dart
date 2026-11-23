import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';

Future<void> main() async {
  // Bindings are needed before reading `.env` from the asset bundle.
  WidgetsFlutterBinding.ensureInitialized();

  final config = await AppConfig.load();

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const GitarthaApp(),
    ),
  );
}
