import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/app/widgets/gitartha_splash.dart';
import 'package:gitartha/features/authentication/presentation/screens/auth_loading_screen.dart';
import 'package:gitartha/app/app.dart';
import 'package:gitartha/app/router/app_router.dart';
import 'package:gitartha/core/config/app_config.dart';
import 'package:gitartha/core/config/app_config_provider.dart';
import 'package:gitartha/data/local/local_database_providers.dart';
import 'package:gitartha/features/authentication/domain/entities/app_user.dart';
import 'package:gitartha/features/authentication/domain/entities/auth_failure.dart';
import 'package:gitartha/features/authentication/presentation/providers/auth_state_provider.dart';

import '../unit/data/local/test_database.dart';
import '../unit/features/authentication/fake_auth_repository.dart';

/// The real app, router and screens over a fake Supabase.
void main() {
  late FakeAuthRepository repo;
  late ProviderContainer container;

  Future<void> launch(
    WidgetTester tester,
    FakeAuthRepository r, {
    bool settle = true,
  }) async {
    repo = r;
    final db = openTestDatabase();
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromMap(const {})),
        authRepositoryProvider.overrideWithValue(r),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GitarthaApp(),
      ),
    );
    // A spinner never settles; tests that hold a request pump manually.
    settle ? await tester.pumpAndSettle() : await tester.pump();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Settings & About'));
    await tester.pumpAndSettle();
  }

  String location() => container
      .read(appRouterProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;

  Future<void> signInAs(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  testWidgets('signed out: the app opens on sign-in; deep links redirect', (
    tester,
  ) async {
    await launch(tester, FakeAuthRepository());
    expect(location(), AppRoutes.login);
    expect(find.text('गीतार्थ'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);

    for (final deepLink in [
      AppRoutes.home,
      AppRoutes.verse(2, 47),
      AppRoutes.journal,
    ]) {
      container.read(appRouterProvider).go(deepLink);
      await tester.pumpAndSettle();
      expect(location(), AppRoutes.login, reason: deepLink);
    }
    expect(find.text('Sign in'), findsWidgets);
    expect(find.textContaining('Sign up'), findsNothing);
  });

  testWidgets('login validates input and toggles password visibility', (
    tester,
  ) async {
    await launch(tester, FakeAuthRepository());
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(repo.signInCalls, 0);

    EditableText password() => tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(EditableText),
      ),
    );
    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('wrong password shows a safe error and stays on login', (
    tester,
  ) async {
    await launch(tester, FakeAuthRepository());
    await signInAs(tester, reader.email!, 'wrong');
    expect(
      find.text(AuthFailureKind.invalidCredentials.message),
      findsOneWidget,
    );
    expect(location(), AppRoutes.login);
  });

  testWidgets('sign-in cannot be submitted twice while in progress', (
    tester,
  ) async {
    await launch(
      tester,
      FakeAuthRepository(
        members: {reader.id: membership(reader, isAccessible: false)},
      ),
    );
    repo.signInGate = Completer();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      reader.email!,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'pw-reader',
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(repo.signInCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repo.signInGate!.complete();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.home);
  });

  testWidgets('read-only member: sign in, read, sign out', (tester) async {
    await launch(
      tester,
      FakeAuthRepository(
        members: {reader.id: membership(reader, isAccessible: false)},
      ),
    );
    await signInAs(tester, reader.email!, 'pw-reader');
    expect(location(), AppRoutes.home);
    await openSettings(tester);
    expect(find.text('Read-only access.'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.login);

    // Authenticated routes are no longer reachable.
    container.read(appRouterProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.login);
  });

  testWidgets('editor: restored session passes through loading to the app', (
    tester,
  ) async {
    final r = FakeAuthRepository(
      restoredUser: editor,
      members: {editor.id: membership(editor, isAccessible: true)},
    )..membershipGate = Completer();
    await launch(tester, r, settle: false);
    expect(location(), AppRoutes.loading);
    // The same splash as at startup (logo + name)...
    expect(find.byType(GitarthaSplash), findsOneWidget);
    expect(find.text('गीतार्थ'), findsOneWidget);
    expect(find.text('Checking your access…'), findsNothing);
    // ...with a hint only if the check takes a while.
    await tester.pump(AuthLoadingScreen.hintDelay);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Checking your access…'), findsOneWidget);

    r.membershipGate!.complete();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.home);
    await openSettings(tester);
    expect(find.textContaining('Editor access'), findsOneWidget);
  });

  testWidgets('missing membership is blocked with sign-out', (tester) async {
    await launch(tester, FakeAuthRepository(restoredUser: reader));
    expect(location(), AppRoutes.accountAccess);
    expect(find.text('Access unavailable'), findsOneWidget);

    container.read(appRouterProvider).go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.accountAccess);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.login);
  });

  testWidgets('membership error offers retry', (tester) async {
    final r =
        FakeAuthRepository(
            restoredUser: reader,
            members: {reader.id: membership(reader, isAccessible: false)},
          )
          ..membershipFailure = const MembershipFailure(
            MembershipFailureKind.unavailable,
          );
    await launch(tester, r);
    expect(location(), AppRoutes.accountAccess);
    expect(find.text(MembershipFailure.message), findsOneWidget);

    r.membershipFailure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.home);
  });

  testWidgets('session expiry returns to login', (tester) async {
    await launch(
      tester,
      FakeAuthRepository(
        restoredUser: reader,
        members: {reader.id: membership(reader, isAccessible: false)},
      ),
    );
    expect(location(), AppRoutes.home);
    repo.expireSession();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.login);
  });

  testWidgets(
    'forgot password sends a reset email without revealing accounts',
    (tester) async {
      await launch(tester, FakeAuthRepository());
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(location(), AppRoutes.forgotPassword);

      await tester.enterText(
        find.byType(TextFormField),
        'someone@example.test',
      );
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(repo.resetRequests, ['someone@example.test']);
      expect(find.textContaining('If an account exists'), findsOneWidget);
    },
  );

  testWidgets('recovery link: choose a new password, then the app', (
    tester,
  ) async {
    await launch(
      tester,
      FakeAuthRepository(
        members: {reader.id: membership(reader, isAccessible: false)},
      ),
    );
    repo.emit(const AuthChange(user: reader, isPasswordRecovery: true));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.resetPassword);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'new-password-1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'new-password-1',
    );
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(repo.passwordUpdates, ['new-password-1']);
    expect(location(), AppRoutes.home);
    expect(find.text('Your password has been changed.'), findsOneWidget);
  });

  Future<void> tapCreateAccount(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
  }

  Future<void> fillRegistration(
    WidgetTester tester, {
    String password = 'long-enough-1',
    String? confirm,
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Asha Devi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'new@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      confirm ?? password,
    );
    await tester.pump();
  }

  testWidgets('register: validation, then "check your email"', (tester) async {
    await launch(tester, FakeAuthRepository());
    await tester.ensureVisible(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.register);
    expect(find.text('Begin your journey'), findsOneWidget);

    await tapCreateAccount(tester);
    await tester.pump();
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);

    await fillRegistration(tester, password: 'Long-enough-1', confirm: 'nope');
    expect(find.text('Strong'), findsOneWidget);
    await tapCreateAccount(tester);
    await tester.pump();
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(repo.signUps, isEmpty);

    await fillRegistration(tester, password: 'Long-enough-1');
    await tapCreateAccount(tester);
    await tester.pumpAndSettle();
    expect(repo.signUps.single, (
      email: 'new@example.test',
      fullName: 'Asha Devi',
    ));
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('new@example.test'), findsOneWidget);
    expect(location(), AppRoutes.register);

    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.login);
  });

  testWidgets('register without email confirmation enters the app', (
    tester,
  ) async {
    const u = FakeAuthRepository.newUser;
    await launch(
      tester,
      FakeAuthRepository(members: {u.id: membership(u, isAccessible: false)})
        ..signUpSignsIn = true,
    );
    await tester.ensureVisible(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await fillRegistration(tester);
    await tapCreateAccount(tester);
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.home);
  });

  testWidgets('register shows server errors; sign-in and sign-up link', (
    tester,
  ) async {
    await launch(
      tester,
      FakeAuthRepository()
        ..signUpFailure = const AuthFailure(AuthFailureKind.signupDisabled),
    );
    await tester.ensureVisible(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await fillRegistration(tester);
    await tapCreateAccount(tester);
    await tester.pumpAndSettle();
    expect(find.text(AuthFailureKind.signupDisabled.message), findsOneWidget);

    await tester.ensureVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.login);
    await tester.ensureVisible(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.register);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'auth screens fit a small phone with large text (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 640 * 2);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await launch(tester, FakeAuthRepository());
        for (final path in [
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.forgotPassword,
        ]) {
          container.read(appRouterProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
      },
    );
  }
}
