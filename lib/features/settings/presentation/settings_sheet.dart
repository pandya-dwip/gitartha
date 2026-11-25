import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
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
    final brightness = Theme.of(context).brightness;
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
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Settings',
                  style: t.headline.copyWith(fontSize: 22),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const _SectionLabel('Appearance'),
          _Group(
            children: [
              _Tile(
                icon: Icons.dark_mode_outlined,
                title: 'Night mode',
                subtitle: 'Easier on the eyes at night',
                onTap: () => settings.toggleTheme(brightness),
                trailing: Switch(
                  value: brightness == Brightness.dark,
                  onChanged: (_) => settings.toggleTheme(brightness),
                ),
              ),
              _Tile(
                icon: Icons.format_size,
                title: 'Reading text size',
                subtitle: 'Size of the scripture text in the reader',
                below: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ReaderFontSize>(
                    showSelectedIcon: false,
                    // Same font and hairline as the rest of the sheet, and
                    // tight enough that every size name fits on one line.
                    style: SegmentedButton.styleFrom(
                      textStyle: t.ui.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: c.border),
                    ),
                    segments: [
                      for (final size in ReaderFontSize.values)
                        ButtonSegment(value: size, label: Text(size.title)),
                    ],
                    selected: {fontSize},
                    onSelectionChanged: (s) => settings.setFontSize(s.single),
                  ),
                ),
              ),
            ],
          ),
          const _SectionLabel('Scripture'),
          _Group(
            children: [
              _Tile(
                icon: Icons.sync,
                title: 'Scripture updates',
                subtitle: syncText,
                trailing: sync.isRunning
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () => ref
                            .read(contentSyncProvider.notifier)
                            .syncContentManually(),
                        child: const Text('Check now'),
                      ),
              ),
            ],
          ),
          const _SectionLabel('Account'),
          _Group(
            children: [
              _Tile(
                icon: Icons.person_outline,
                title: user?.email ?? 'Signed in',
                subtitle: canEdit
                    ? 'Editor: may also publish shared scripture'
                    : 'Read-only access',
              ),
              _Tile(
                icon: Icons.logout,
                title: 'Sign out',
                destructive: true,
                onTap: () => _signOut(context, ref),
              ),
            ],
          ),
          _Footnote(
            'Your reflections, notes, bookmarks and progress stay on this '
            'device.',
            color: c.textSecondary,
          ),
          const _SectionLabel('About'),
          _Group(
            children: [
              _Tile(
                icon: Icons.info_outline,
                title: 'About & licences',
                subtitle: 'Gitartha (गीतार्थ)',
                trailing: Icon(Icons.chevron_right, color: c.textSecondary),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Gitartha (गीतार्थ)',
                ),
              ),
            ],
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

/// Small upper-case heading above a group, iOS-settings style.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xs,
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.sm,
    ),
    child: Text(
      text.toUpperCase(),
      style: context.text.meta.copyWith(
        color: context.colors.textSecondary,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _Footnote extends StatelessWidget {
  const _Footnote(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xs,
      AppSpacing.sm,
      AppSpacing.xs,
      0,
    ),
    child: Text(
      text,
      style: context.text.ui.copyWith(fontSize: 12, color: color),
    ),
  );
}

/// One rounded card holding rows, separated by hairlines aligned with the
/// row text (not the icons).
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: c.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: _Tile.textStart,
                color: c.border.withValues(alpha: 0.6),
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// A settings row: icon badge, title and subtitle, an optional control on
/// the right, and optionally a full-width control underneath. Every row
/// uses the same paddings, so icons, text and controls line up.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;
  final bool destructive;

  static const _pad = AppSpacing.md;
  static const _badge = 36.0;

  /// Where the row text starts (also the divider indent).
  static const textStart = _pad + _badge + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final tint = destructive ? Theme.of(context).colorScheme.error : c.accent;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: _badge,
                  height: _badge,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: tint),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.ui.copyWith(
                          fontWeight: FontWeight.w600,
                          color: destructive ? tint : null,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: t.ui.copyWith(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
            if (below != null) ...[const SizedBox(height: 12), below!],
          ],
        ),
      ),
    );
  }
}
