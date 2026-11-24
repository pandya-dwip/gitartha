import 'package:flutter/material.dart';

/// Gitartha's motion language: calm, short, and cheap to render.
///
/// Every effect here animates only **opacity and transform** (no layout, no
/// blur), runs **once** (no perpetual animations), and respects the system
/// "reduce motion" setting, which turns it off.
abstract final class Motion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration gentle = Duration(milliseconds: 420);
  static const Duration splash = Duration(milliseconds: 700);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeOutBack;

  /// Delay between consecutive items of a staggered list.
  static const Duration stagger = Duration(milliseconds: 45);

  /// Items beyond this index appear without a stagger delay, so long lists
  /// stay responsive when scrolled.
  static const int maxStaggered = 8;

  /// Whether the user asked the system to reduce motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when motion is reduced.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Marks a screen's "first moments". [FadeSlideIn] widgets inside it only
/// animate while the scope is fresh, so a list's first screenful staggers in,
/// but items built later by scrolling (or rebuilt when scrolled back) simply
/// appear. Without a scope, [FadeSlideIn] always animates.
class EntranceScope extends StatefulWidget {
  const EntranceScope({super.key, required this.child});

  final Widget child;

  /// How long after the screen appears entrances still play.
  static const Duration window = Duration(milliseconds: 700);

  /// False once the screen containing [context] has settled.
  static bool isFresh(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_EntranceMarker>()
          ?.isFresh() ??
      true;

  @override
  State<EntranceScope> createState() => _EntranceScopeState();
}

class _EntranceScopeState extends State<EntranceScope> {
  final Stopwatch _age = Stopwatch()..start();

  @override
  Widget build(BuildContext context) => _EntranceMarker(
    isFresh: () => _age.elapsed < EntranceScope.window,
    child: widget.child,
  );
}

class _EntranceMarker extends InheritedWidget {
  const _EntranceMarker({required this.isFresh, required super.child});

  final bool Function() isFresh;

  @override
  bool updateShouldNotify(_EntranceMarker old) => false;
}

/// Fades and slightly rises its child into place once, when first built.
///
/// Use [index] to stagger items of a list: item `i` starts `i * stagger`
/// later (capped at [Motion.maxStaggered]).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration = Motion.gentle,
    this.offset = 14,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  /// Starting vertical offset in logical pixels.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.enter,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context) || !EntranceScope.isFresh(context)) {
      _controller.value = 1;
      return;
    }
    final steps = widget.index.clamp(0, Motion.maxStaggered);
    final wait = widget.delay + Motion.stagger * steps;
    if (wait == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(wait, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, widget.offset * (1 - _curve.value)),
        child: child,
      ),
      child: widget.child,
    ),
  );
}

/// Gives tappable surfaces a subtle "press" (scale to 0.98) while touched.
/// Purely visual: taps are still handled by the child (e.g. an InkWell).
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: Motion.of(context, Motion.quick),
        curve: Motion.enter,
        child: widget.child,
      ),
    );
  }
}

/// Swaps an icon (or any small widget) with a scale + fade, e.g. a bookmark
/// outline turning into a filled bookmark. Give each state a distinct key.
class PopSwitcher extends StatelessWidget {
  const PopSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.of(context, Motion.medium),
    switchInCurve: Motion.emphasized,
    switchOutCurve: Motion.exit,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: animation, child: child),
    ),
    child: child,
  );
}
