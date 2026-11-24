import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/app/app.dart';
import 'package:gitartha/app/router/app_router.dart';
import 'package:gitartha/core/config/app_config.dart';
import 'package:gitartha/core/config/app_config_provider.dart';
import 'package:gitartha/features/authentication/domain/entities/app_user.dart';
import 'package:gitartha/features/authentication/domain/entities/auth_failure.dart';
import 'package:gitartha/features/authentication/presentation/providers/auth_state_provider.dart';

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
    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromMap(const {})),
        authRepositoryProvider.overrideWithValue(r),
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

  testWidgets('signed out: protected routes redirect to login', (tester) async {
    await launch(tester, FakeAuthRepository());
    expect(location(), AppRoutes.login);

    container.read(appRouterProvider).go(AppRoutes.home); // deep link
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.login);
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
    expect(find.text('Read-only access'), findsOneWidget);

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
    expect(find.text('Checking your access…'), findsOneWidget);

    r.membershipGate!.complete();
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.home);
    expect(find.text('Editor access'), findsOneWidget);
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
}
