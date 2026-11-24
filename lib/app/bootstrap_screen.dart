import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config_provider.dart';
import '../features/authentication/domain/entities/auth_failure.dart';
import '../features/authentication/presentation/providers/auth_state_provider.dart';
import '../features/authentication/presentation/providers/member_access_provider.dart';

/// Temporary authenticated entry point: confirms who is signed in and their
/// access level. It will be replaced by the real home flow in a later
/// milestone.
class BootstrapScreen extends ConsumerWidget {
  const BootstrapScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } on AuthFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final user = ref.watch(currentUserProvider);
    final canEdit = ref.watch(canEditSharedContentProvider);
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
            if (user?.email != null) Text(user!.email!),
            Text(
              canEdit ? 'Editor access' : 'Read-only access',
              style: textTheme.bodySmall?.copyWith(color: secondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _signOut(context, ref),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
