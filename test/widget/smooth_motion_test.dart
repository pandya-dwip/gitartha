import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/app/motion/motion.dart';
import 'package:gitartha/app/theme/app_theme.dart';
import 'package:gitartha/app/widgets/state_views.dart';

/// Smoothness rules: no spinner flashes for quick loads, and no staggered
/// entrance stacked on top of a page transition.
void main() {
  Widget app(Widget home) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: home),
  );

  double opacityOf(WidgetTester tester, Finder child) => tester
      .widget<AnimatedOpacity>(
        find.ancestor(of: child, matching: find.byType(AnimatedOpacity)).first,
      )
      .opacity;

  testWidgets('loader stays invisible for quick loads, then fades in', (
    tester,
  ) async {
    await tester.pumpWidget(app(const LoadingState()));
    final spinner = find.byType(CircularProgressIndicator);
    expect(opacityOf(tester, spinner), 0);

    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, spinner), 0, reason: 'still a quick load');

    await tester.pump(const Duration(milliseconds: 150));
    expect(opacityOf(tester, spinner), 1);
  });

  testWidgets('a loader removed early leaves no pending timer', (tester) async {
    await tester.pumpWidget(app(const LoadingState()));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(app(const Text('data')));
    // The test would fail with "A Timer is still pending" otherwise.
    expect(find.text('data'), findsOneWidget);
  });

  testWidgets('no entrance animation on top of a page transition', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: AppTheme.light,
        home: const Scaffold(body: Text('first')),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: FadeSlideIn(child: Text('card'))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20)); // mid-transition
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('card'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1, reason: 'the page transition is the motion');
    await tester.pumpAndSettle();
  });

  testWidgets('entrances still play on a settled screen', (tester) async {
    await tester.pumpWidget(app(const FadeSlideIn(child: Text('card'))));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('card'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);
  });
}
