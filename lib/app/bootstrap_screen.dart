import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config_provider.dart';

/// Temporary launch screen that confirms the app boots. It will be replaced
/// by the real home flow in a later milestone.
class BootstrapScreen extends ConsumerWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final textTheme = Theme.of(context).textTheme;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('गीतार्थ', style: textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(config.appName, style: textTheme.titleMedium),
            const SizedBox(height: 24),
            Text(
              '${config.environment.name} · '
              'backend ${config.isSupabaseConfigured ? 'configured' : 'not configured'}',
              style: textTheme.bodySmall?.copyWith(color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}
