import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/sacred_widgets.dart';

/// code.html "Splash Screen": the welcome shown to signed-out visitors.
/// "Begin Sacred Journey" leads to sign-in (accounts are invitation-only).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: ThemeToggleButton(),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.card,
                            border: Border.all(color: c.accent, width: 2),
                            boxShadow: c.halo,
                          ),
                          child: CustomPaint(painter: _LotusMandala(c.accent)),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'गीतार्थ',
                          style: t.sanskrit.copyWith(
                            fontSize: 36,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'GITARTHA',
                          style: t.headline.copyWith(
                            color: c.accent,
                            fontSize: 17,
                            letterSpacing: 4.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const SacredDivider(width: 144),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'The Essence of the Bhagavad Gita',
                          style: t.commentary.copyWith(
                            color: c.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                'TIMELESS WISDOM • SACRED READING',
                style: t.meta.copyWith(fontSize: 11, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.login),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Begin Sacred Journey'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The code.html lotus/kalash emblem: dashed outer ring, inner ring, four
/// petals and a centre dot.
class _LotusMandala extends CustomPainter {
  const _LotusMandala(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100 * 0.58; // emblem is 58% of the circle
    canvas.translate(size.width / 2 - 50 * s, size.height / 2 - 50 * s);
    canvas.scale(s);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = color.withValues(alpha: 0.15);

    // Dashed outer circle (3/3 dash).
    const r = 42.0;
    const dash = 3 / r; // radians per dash at this radius
    for (var a = 0.0; a < 6.283; a += dash * 2) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(50, 50), radius: r),
        a,
        dash,
        false,
        stroke,
      );
    }
    canvas.drawCircle(const Offset(50, 50), 30, stroke);

    for (final petal in [
      [50.0, 20.0, 42.0, 35.0, 42.0, 45.0, 58.0, 45.0, 58.0, 35.0],
      [50.0, 80.0, 42.0, 65.0, 42.0, 55.0, 58.0, 55.0, 58.0, 65.0],
      [20.0, 50.0, 35.0, 42.0, 45.0, 42.0, 45.0, 58.0, 35.0, 58.0],
      [80.0, 50.0, 65.0, 42.0, 55.0, 42.0, 55.0, 58.0, 65.0, 58.0],
    ]) {
      final path = Path()
        ..moveTo(petal[0], petal[1])
        ..cubicTo(petal[2], petal[3], petal[4], petal[5], 50, 50)
        ..cubicTo(petal[6], petal[7], petal[8], petal[9], petal[0], petal[1])
        ..close();
      canvas
        ..drawPath(path, fill)
        ..drawPath(path, stroke);
    }
    canvas.drawCircle(const Offset(50, 50), 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LotusMandala old) => old.color != color;
}
