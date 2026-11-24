import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/sacred_widgets.dart';
import '../../authentication/domain/entities/auth_failure.dart';
import '../../authentication/presentation/providers/auth_state_provider.dart';
import '../../authentication/presentation/providers/member_access_provider.dart';
import '../../synchronization/presentation/providers/content_sync_provider.dart';
import 'providers/app_settings_provider.dart';

/// code.html "Settings & About" modal, as a bottom sheet.
Future<void> showSettingsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _SettingsSheet(),
    );

/// "24 Nov 2026, 10:30" in the device's locale.
String formatDateTime(BuildContext context, DateTime value) {
  final l = MaterialLocalizations.of(context);
  final local = value.toLocal();
  return '${l.formatMediumDate(local)}, '
      '${l.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fontSize =
        ref.watch(readerFontSizeProvider).value ?? ReaderFontSize.medium;
    final sync = ref.watch(contentSyncProvider);
    final user = ref.watch(currentUserProvider);
    final canEdit = ref.watch(canEditSharedContentProvider);
    final settings = ref.read(appSettingsActionsProvider);

    final syncText = sync.isRunning
        ? 'Updating scripture…'
        : sync.message ??
              (sync.lastSuccessfulSyncAt == null
                  ? 'Not updated on this device yet'
                  : 'Last updated ${formatDateTime(context, sync.lastSuccessfulSyncAt!)}');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gitartha Settings',
                  style: t.headline.copyWith(fontSize: 17),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.gutter),
          _Row(
            title: 'Theme Mode',
            subtitle: 'Warm Ivory / Deep Night',
            trailing: FilledButton.icon(
              onPressed: () =>
                  settings.toggleTheme(Theme.of(context).brightness),
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: Text(dark ? 'Ivory Mode' : 'Night Mode'),
            ),
          ),
          _Row(
            title: 'Scripture Font Size',
            subtitle: 'Default reader scale',
            trailing: OutlinedButton(
              onPressed: settings.cycleFontSize,
              child: Text(fontSize.title),
            ),
          ),
          _Row(
            title: 'Scripture Updates',
            subtitle: syncText,
            trailing: OutlinedButton(
              onPressed: sync.isRunning
                  ? null
                  : () => ref
                        .read(contentSyncProvider.notifier)
                        .syncContentManually(),
              child: Text(sync.isRunning ? 'Updating…' : 'Check now'),
            ),
          ),
          SacredCard(
            tone: SacredTone.well,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Account',
                  style: t.ui.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (user?.email != null) Text(user!.email!, style: t.ui),
                Text(
                  canEdit
                      ? 'Editor access: you may also publish shared scripture.'
                      : 'Read-only access.',
                  style: t.ui.copyWith(color: c.textSecondary, fontSize: 12),
                ),
                Text(
                  'Reflections, notes, bookmarks and progress stay on this device.',
                  style: t.ui.copyWith(color: c.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _signOut(context, ref),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Gitartha (गीतार्थ)',
            ),
            child: const Text('About & licences'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } on AuthFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
    child: SacredCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.ui.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: context.text.ui.copyWith(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    ),
  );
}
