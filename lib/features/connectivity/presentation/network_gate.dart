import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/motion/motion.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/internet_checker.dart';
import 'providers/network_status_provider.dart';

/// Shows a modal "turn on the internet" prompt above the whole app whenever
/// the server cannot be reached (checked on launch and on resume).
///
/// Signing in and confirming membership need Supabase, so the prompt stays
/// until the connection is back. It re-checks by itself and closes
/// automatically, and the membership check is then retried.
class NetworkGate extends ConsumerWidget {
  const NetworkGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(networkStatusProvider.select((s) => s.isOffline));
    return Stack(
      children: [
        ExcludeFocus(excluding: offline, child: child),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            switchInCurve: Motion.enter,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: offline
                ? const _OfflinePrompt(key: ValueKey('offline'))
                : const SizedBox.shrink(key: ValueKey('online')),
          ),
        ),
      ],
    );
  }
}

class _OfflinePrompt extends ConsumerWidget {
  const _OfflinePrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final checking = ref.watch(networkStatusProvider.select((s) => s.checking));
    final controller = ref.read(networkStatusProvider.notifier);

    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Color(0x8A000000)),
        BlockSemantics(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FadeSlideIn(
                  offset: 24,
                  duration: Motion.medium,
                  child: Material(
                    color: c.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      side: BorderSide(color: c.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Semantics(
                        scopesRoute: true,
                        namesRoute: true,
                        explicitChildNodes: true,
                        label: 'No internet connection',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.accentSoft,
                                ),
                                alignment: Alignment.center,
                                child: PopSwitcher(
                                  child: checking
                                      ? SizedBox.square(
                                          key: const ValueKey('checking'),
                                          dimension: 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: c.accent,
                                          ),
                                        )
                                      : Icon(
                                          Icons.wifi_off_rounded,
                                          key: const ValueKey('icon'),
                                          size: 30,
                                          color: c.accent,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No internet connection',
                              textAlign: TextAlign.center,
                              style: t.headline.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Gitartha needs the internet to verify your '
                              'account. Please turn on Wi-Fi or mobile data.',
                              textAlign: TextAlign.center,
                              style: t.commentary.copyWith(
                                fontSize: 15,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (NetworkSettings.canOpen) ...[
                              FilledButton.icon(
                                onPressed: NetworkSettings.open,
                                icon: const Icon(Icons.settings_outlined),
                                label: const Text('Open network settings'),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            OutlinedButton(
                              onPressed: checking ? null : controller.check,
                              child: Text(checking ? 'Checking…' : 'Try again'),
                            ),
                            const SizedBox(height: AppSpacing.gutter),
                            Text(
                              'This closes by itself when you are back online.',
                              textAlign: TextAlign.center,
                              style: t.ui.copyWith(
                                fontSize: 12,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
