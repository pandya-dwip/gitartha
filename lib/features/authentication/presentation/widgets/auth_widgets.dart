import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/lotus_emblem.dart';

/// Shared layout of every authentication screen (sign in, register, forgot /
/// reset password, account access), in the DESIGN.md language: a warm
/// parchment gradient with a faint ॐ watermark, the lotus emblem and
/// wordmark, a serif title and the form on a vellum card with the soft gold
/// halo. Content fades and rises in gently when the screen opens.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Shown below the card (e.g. "New to Gitartha? Create an account").
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.canvas, c.well],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -60,
              child: ExcludeSemantics(
                child: Text(
                  'ॐ',
                  style: t.sanskrit.copyWith(
                    fontSize: 260,
                    height: 1,
                    color: c.accent.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                    vertical: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _Entrance(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: LotusEmblem(size: 76)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'गीतार्थ',
                            textAlign: TextAlign.center,
                            style: t.sanskrit.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                              height: 1.3,
                            ),
                          ),
                          Text(
                            'GITARTHA',
                            textAlign: TextAlign.center,
                            style: t.meta.copyWith(
                              color: c.accent,
                              letterSpacing: 4,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: t.display.copyWith(fontSize: 24),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: t.commentary.copyWith(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(AppRadii.xl),
                              border: Border.all(color: c.border),
                              boxShadow: c.halo,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: children,
                            ),
                          ),
                          if (footer != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades the content in while lifting it a few pixels (once, on open).
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
    ),
  );
}

/// "Question? Action" line under the auth card.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        prompt,
        style: context.text.ui.copyWith(color: context.colors.textSecondary),
      ),
      TextButton(onPressed: onPressed, child: Text(action)),
    ],
  );
}

/// An error banner (soft error tint, icon, message), announced to screen
/// readers.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: error.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 20, color: error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: context.text.ui.copyWith(color: error, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animates errors in and out without a jump in the layout.
class AnimatedAuthError extends StatelessWidget {
  const AnimatedAuthError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOut,
    alignment: Alignment.topCenter,
    child: message == null
        ? const SizedBox(width: double.infinity)
        : AuthErrorText(message!),
  );
}

/// A full-width filled button that shows a spinner and ignores taps while
/// [busy].
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    onPressed: busy ? null : onPressed,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: busy
          ? SizedBox.square(
              key: const ValueKey('busy'),
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.onAccent,
              ),
            )
          : Text(label, key: const ValueKey('label')),
    ),
  );
}
