import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/app/motion/motion.dart';
import 'package:gitartha/app/theme/app_theme.dart';
import 'package:gitartha/app/widgets/app_logo.dart';
import 'package:gitartha/app/widgets/gitartha_splash.dart';
import 'package:gitartha/core/config/app_config.dart';
import 'package:gitartha/core/config/app_config_provider.dart';
import 'package:gitartha/core/network/internet_checker.dart';
import 'package:gitartha/features/authentication/presentation/providers/member_access_provider.dart';
import 'package:gitartha/features/connectivity/presentation/network_gate.dart';
import 'package:gitartha/features/connectivity/presentation/providers/network_status_provider.dart';

/// Scriptable connectivity.
class FakeChecker implements InternetChecker {
  FakeChecker(this.online);

  bool online;
  int checks = 0;

  @override
  Future<bool> hasInternet() async {
    checks++;
    return online;
  }
}

Widget themed(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  group('splash', () {
    testWidgets('shows the logo with the name below, then reports the end of '
        'its entrance', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        themed(GitarthaSplash(onEntranceComplete: () => completed = true)),
      );
      expect(find.byType(GitarthaLogo), findsOneWidget);
      expect(find.text('गीतार्थ'), findsOneWidget);
      expect(find.text('GITARTHA'), findsOneWidget);

      // Logo above the name, horizontally centred together.
      final logo = tester.getCenter(find.byType(GitarthaLogo));
      final name = tester.getCenter(find.text('गीतार्थ'));
      expect(logo.dy, lessThan(name.dy));
      expect((logo.dx - name.dx).abs(), lessThan(1));

      await tester.runAsync(() async {
        // The entrance waits for the logo image to be decoded.
        await precacheImage(
          const AssetImage('assets/images/branding/gitartha_logo.png'),
          tester.element(find.byType(GitarthaSplash)),
        );
      });
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });

    testWidgets(
      'without an entrance (checking access) it is complete at once',
      (tester) async {
        var completed = false;
        await tester.pumpWidget(
          themed(
            GitarthaSplash(
              animateIn: false,
              onEntranceComplete: () => completed = true,
            ),
          ),
        );
        await tester.pump();
        expect(completed, isTrue);
        final name = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('गीतार्थ'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(name.opacity.value, 1);
      },
    );
  });

  group('network prompt', () {
    late FakeChecker checker;

    Future<void> pumpGate(WidgetTester tester, {InternetChecker? override}) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(AppConfig.fromMap(const {})),
              internetCheckerProvider.overrideWithValue(override ?? checker),
            ],
            child: themed(
              const NetworkGate(child: Scaffold(body: Text('App content'))),
            ),
          ),
        );

    setUp(() => checker = FakeChecker(false));

    testWidgets('appears when offline and blocks the app', (tester) async {
      await pumpGate(tester);
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.textContaining('verify your account'), findsOneWidget);
      // The app behind is not tappable through the modal barrier.
      expect(find.byType(ModalBarrier), findsWidgets);

      await tester.pumpWidget(const SizedBox()); // dispose: stops polling
    });

    testWidgets('"Try again" re-checks, and the prompt closes by itself once '
        'the connection is back', (tester) async {
      await pumpGate(tester);
      await tester.pumpAndSettle();
      final before = checker.checks;

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(checker.checks, before + 1);
      expect(find.text('No internet connection'), findsOneWidget);

      checker.online = true;
      await tester.pump(NetworkStatusController.pollInterval);
      await tester.pumpAndSettle();
      expect(find.text('No internet connection'), findsNothing);
      expect(find.text('App content'), findsOneWidget);
    });

    testWidgets('never appears while online', (tester) async {
      checker.online = true;
      await pumpGate(tester);
      await tester.pumpAndSettle();
      expect(find.text('No internet connection'), findsNothing);
    });

    testWidgets('is off when no backend is configured', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.fromMap(const {})),
          ],
          child: themed(
            const NetworkGate(child: Scaffold(body: Text('App content'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No internet connection'), findsNothing);
    });
  });

  testWidgets('reconnecting re-checks a membership that failed offline', (
    tester,
  ) async {
    final checker = FakeChecker(false);
    var membershipChecks = 0;
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromMap(const {})),
        internetCheckerProvider.overrideWithValue(checker),
        authStatusProvider.overrideWith((ref) => AuthStatus.membershipError),
        memberAccessProvider.overrideWith((ref) async {
          membershipChecks++;
          return null;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(memberAccessProvider, (_, _) {});
    container.listen(networkStatusProvider, (_, _) {});
    await tester.pump();
    await tester.pump();
    expect(container.read(networkStatusProvider).isOffline, isTrue);
    expect(membershipChecks, 1);

    checker.online = true;
    await container.read(networkStatusProvider.notifier).check();
    await tester.pump();
    expect(container.read(networkStatusProvider).isOffline, isFalse);
    // Riverpod re-runs the invalidated provider on a following frame.
    await tester.pump(const Duration(milliseconds: 50));
    expect(membershipChecks, 2); // asked again after reconnecting
  });

  group('motion', () {
    testWidgets('list items animate only in a screen\'s first moments', (
      tester,
    ) async {
      await tester.pumpWidget(
        themed(const EntranceScope(child: FadeSlideIn(child: Text('early')))),
      );
      final early = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.text('early'),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(early.opacity.value, lessThan(1)); // still entering
      await tester.pumpAndSettle();
      expect(early.opacity.value, 1);

      // Built after the entrance window (e.g. scrolled into view): no replay.
      await tester.runAsync(
        () => Future<void>.delayed(
          EntranceScope.window + const Duration(milliseconds: 50),
        ),
      );
      await tester.pumpWidget(
        themed(
          const EntranceScope(
            child: Column(
              children: [
                FadeSlideIn(child: Text('early')),
                FadeSlideIn(child: Text('late')),
              ],
            ),
          ),
        ),
      );
      final late = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.text('late'),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(late.opacity.value, 1);
    });

    testWidgets('reduced motion turns entrances off', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: themed(const FadeSlideIn(child: Text('still'))),
        ),
      );
      final fade = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.text('still'),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, 1);
    });
  });
}
