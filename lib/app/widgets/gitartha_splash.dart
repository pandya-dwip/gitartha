import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Gitartha's one and only splash: the logo with the name below it, centred
/// on the canvas colour.
///
/// It is used for every "please wait" moment (app start, checking the
/// member's access), always with the same layout, so moving from one to the
/// next never shows a jump. The native launch screens show only the canvas
/// colour, so this is the first thing with content the user sees.
///
/// With [animateIn] the logo scales and fades in, then the name rises into
/// place, once. The entrance starts only after the logo image is decoded,
/// so logo and name never appear separately.
class GitarthaSplash extends StatefulWidget {
  const GitarthaSplash({
    super.key,
    this.animateIn = true,
    this.footer,
    this.onEntranceComplete,
  });

  final bool animateIn;

  /// Shown under the name (a slow-start hint, or an error with a retry).
  final Widget? footer;

  /// Called once the entrance has finished (immediately without one).
  final VoidCallback? onEntranceComplete;

  static const double logoSize = 120;

  @override
  State<GitarthaSplash> createState() => _GitarthaSplashState();
}

class _GitarthaSplashState extends State<GitarthaSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.splash,
  );
  bool _started = false;

  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.55, curve: Curves.easeOut),
  );
  late final Animation<double> _logoScale = Tween(begin: 0.88, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.7, curve: Motion.emphasized),
        ),
      );
  late final Animation<double> _nameIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1, curve: Motion.enter),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animateIn || Motion.reduced(context)) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
      return;
    }
    // Decode the logo first, then play the entrance for logo and name
    // together.
    precacheImage(
      GitarthaLogo.provider(context, GitarthaSplash.logoSize),
      context,
    ).whenComplete(() {
      if (!mounted) return;
      _controller.forward().whenComplete(_complete);
    });
  }

  void _complete() {
    if (mounted) widget.onEntranceComplete?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      backgroundColor: c.canvas,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: const GitarthaLogo(size: GitarthaSplash.logoSize),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeTransition(
                opacity: _nameIn,
                child: AnimatedBuilder(
                  animation: _nameIn,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 10 * (1 - _nameIn.value)),
                    child: child,
                  ),
                  child: Semantics(
                    header: true,
                    label: 'Gitartha',
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          Text(
                            'गीतार्थ',
                            style: t.sanskrit.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: c.accent,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'GITARTHA',
                            style: t.meta.copyWith(
                              color: c.textSecondary,
                              fontSize: 11,
                              letterSpacing: 3.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Fixed height: the footer appearing never moves the logo.
              SizedBox(
                height: 168,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: AnimatedSwitcher(
                      duration: Motion.of(context, Motion.medium),
                      child: widget.footer ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
