import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// Exposes the [AppConfig] loaded at startup.
///
/// It is overridden in `main.dart` (and in tests) with the loaded value.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden with a loaded AppConfig '
    'in the root ProviderScope.',
  ),
);
