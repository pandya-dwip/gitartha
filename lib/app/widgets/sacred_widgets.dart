import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/providers/app_settings_provider.dart';
import '../motion/motion.dart';
import '../theme/app_theme.dart';

/// The surfaces of DESIGN.md's tonal layering.
enum SacredTone {
  /// Milk vellum (`card`): verse cards, primary content.
  card,

  /// Aged parchment (`well`): commentary wells, context, trays.
  well,
}

/// A bordered card (1px linen hairline, 8px radius, DESIGN.md "Sacred Verse
/// Cards"). [emphasized] uses a soft gold border for sacred anchors.
class SacredCard extends StatelessWidget {
  const SacredCard({
    super.key,
    required this.child,
    this.onTap,
    this.tone = SacredTone.card,
    this.emphasized = false,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final VoidCallback? onTap;
  final SacredTone tone;
  final bool emphasized;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(AppRadii.lg);
    final tappable = onTap != null;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: tone == SacredTone.card ? c.softShadow : null,
      ),
      child: Material(
        color: tone == SacredTone.card ? c.card : c.well,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: emphasized
                ? c.accent.withValues(alpha: 0.4)
                : c.border.withValues(alpha: 0.7),
          ),
        ),
        // The clip only exists to keep the ink ripple inside the rounded
        // corners; static cards (most of the reader) skip it.
        clipBehavior: tappable ? Clip.antiAlias : Clip.none,
        child: tappable
            ? InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );
    return tappable ? PressScale(child: card) : card;
  }
}

/// Small uppercase section label with an icon ("CONTINUE READING").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon, this.accent = true});

  final String text;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? context.colors.accent : context.colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: context.text.meta.copyWith(color: color, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

/// DESIGN.md filigree divider: hairlines fading out around a ✦ mark.
class SacredDivider extends StatelessWidget {
  const SacredDivider({super.key, this.width = 140});

  final double width;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    Widget line(bool left) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: left ? 0 : 0.35),
              accent.withValues(alpha: left ? 0.35 : 0),
            ],
          ),
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            line(true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('✦', style: TextStyle(color: accent, fontSize: 12)),
            ),
            line(false),
          ],
        ),
      ),
    );
  }
}

/// Square seal-like number badge (chapter / verse numbers).
class NumberBadge extends StatelessWidget {
  const NumberBadge(this.label, {super.key, this.size = 40});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.well,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        label,
        style: context.text.ui.copyWith(
          color: c.accent,
          fontWeight: FontWeight.w600,
          fontSize: size > 36 ? 14 : 12,
        ),
      ),
    );
  }
}

/// Outlined square icon button used in headers (theme, settings, font).
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.label,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Gold when active (e.g. bookmarked), sandalwood otherwise.
  final bool active;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.accent : c.textSecondary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PopSwitcher(
                    child: Icon(
                      icon,
                      key: ValueKey(icon),
                      size: 20,
                      color: color,
                    ),
                  ),
                  if (label != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      label!,
                      style: context.text.meta.copyWith(
                        color: c.text,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light / dark toggle, persisted in local settings.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HeaderIconButton(
      icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      tooltip: dark ? 'Switch to Warm Ivory theme' : 'Switch to Night theme',
      active: true,
      onPressed: () => ref
          .read(appSettingsActionsProvider)
          .toggleTheme(Theme.of(context).brightness),
    );
  }
}

/// Selectable pill (verse ranges, journal tabs).
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.accent : c.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? c.accent : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: context.text.ui.copyWith(
                fontSize: 12,
                color: selected ? c.onAccent : c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sticky top bar of inner screens: a gold back link, a centred title and
/// the theme toggle (code.html chapter overview / index / reader headers).
class InnerTopBar extends StatelessWidget implements PreferredSizeWidget {
  const InnerTopBar({
    super.key,
    required this.backLabel,
    required this.onBack,
    required this.center,
    this.backIcon = Icons.arrow_back,
    this.trailing,
  });

  final String backLabel;
  final VoidCallback onBack;
  final Widget center;
  final IconData backIcon;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.canvas,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page - 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: c.border.withValues(alpha: 0.6)),
            ),
          ),
          // The title is centred on the screen, not between the side
          // controls, so it lines up the same on every screen.
          child: LayoutBuilder(
            builder: (context, box) => NavigationToolbar(
              middleSpacing: AppSpacing.sm,
              leading: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * 0.34),
                child: TextButton.icon(
                  onPressed: onBack,
                  icon: Icon(backIcon, size: 18),
                  label: Text(
                    backLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              middle: FittedBox(fit: BoxFit.scaleDown, child: center),
              trailing: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: trailing ?? const ThemeToggleButton(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centres content at DESIGN.md's maximum reading width.
class ReadingWidth extends StatelessWidget {
  const ReadingWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxReadingWidth),
      child: child,
    ),
  );
}

/// Shared tab header: serif title, gold subtitle, hairline below.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.gutter,
        AppSpacing.page,
        AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.headline.copyWith(fontSize: 18, letterSpacing: 1.5),
                ),
                Text(
                  subtitle,
                  style: t.commentary.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    color: c.accent,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const ThemeToggleButton(),
        ],
      ),
    );
  }
}
