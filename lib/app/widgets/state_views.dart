import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Calm empty state (code.html "coming soon" panel: gold ring icon, serif
/// title, short description, optional action).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Scrollable so it also fits short screens and large text.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.card,
                border: Border.all(color: c.accent, width: 2),
              ),
              child: Icon(icon, color: c.accent, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: context.text.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: context.text.commentary.copyWith(
                  color: c.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown while data loads. Invisible for the first [delay] (local reads
/// usually finish well before that, so no spinner flashes on screen), then
/// the spinner fades in.
class LoadingState extends StatefulWidget {
  const LoadingState({super.key});

  static const delay = Duration(milliseconds: 300);

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(LoadingState.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: const CircularProgressIndicator(),
    ),
  );
}

/// A failed local read. Shows a safe message, never the exception.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.error_outline,
    title: 'Something went wrong',
    message: 'This could not be loaded. Your saved content is safe.',
    action: onRetry == null
        ? null
        : OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
  );
}
