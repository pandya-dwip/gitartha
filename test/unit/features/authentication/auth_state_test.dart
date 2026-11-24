import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/features/authentication/domain/entities/app_user.dart';
import 'package:gitartha/features/authentication/domain/entities/auth_failure.dart';
import 'package:gitartha/features/authentication/domain/repositories/auth_repository.dart';
import 'package:gitartha/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:gitartha/features/authentication/presentation/providers/member_access_provider.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repo;
  late ProviderContainer container;

  ProviderContainer start(FakeAuthRepository r) {
    repo = r;
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(r)],
    );
    // Keep the status alive, as the router does.
    container.listen(authStatusProvider, (_, _) {});
    return container;
  }

  AuthStatus status() => container.read(authStatusProvider);
  AuthController auth() => container.read(authControllerProvider.notifier);

  /// Lets stream events and membership futures complete.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  tearDown(() => container.dispose());

  group('authentication', () {
    test('no backend: sign-in is unavailable, nothing else is', () async {
      container = ProviderContainer();
      expect(container.read(authStatusProvider), AuthStatus.backendUnavailable);
      expect(container.read(canEditSharedContentProvider), isFalse);
      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .signIn(email: 'a@b.co', password: 'x'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.kind,
            'kind',
            AuthFailureKind.backendUnavailable,
          ),
        ),
      );
    });

    test('starts signed out without a stored session', () {
      start(FakeAuthRepository());
      expect(status(), AuthStatus.signedOut);
      expect(container.read(currentUserProvider), isNull);
    });

    test('restores a stored session and loads membership', () async {
      start(
        FakeAuthRepository(
          restoredUser: reader,
          members: {reader.id: membership(reader, isAccessible: false)},
        ),
      );
      expect(container.read(currentUserProvider), reader);
      expect(status(), AuthStatus.loadingMembership);
      await settle();
      expect(status(), AuthStatus.readOnly);
      expect(repo.signInCalls, 0, reason: 'no login needed');
    });

    test('successful sign-in, then membership', () async {
      start(
        FakeAuthRepository(
          members: {reader.id: membership(reader, isAccessible: false)},
        ),
      );
      await auth().signIn(email: reader.email!, password: 'pw-reader');
      expect(container.read(currentUserProvider), reader);
      await settle();
      expect(status(), AuthStatus.readOnly);
    });

    test('invalid credentials keep the user signed out', () async {
      start(FakeAuthRepository());
      await expectLater(
        auth().signIn(email: reader.email!, password: 'wrong'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.kind,
            'kind',
            AuthFailureKind.invalidCredentials,
          ),
        ),
      );
      expect(status(), AuthStatus.signedOut);
    });

    test('malformed input is rejected before calling Supabase', () async {
      start(FakeAuthRepository());
      for (final (email, password) in [
        ('not-an-email', 'pw'),
        ('reader@example.test', ''),
        ('', 'pw'),
      ]) {
        await expectLater(
          auth().signIn(email: email, password: password),
          throwsA(isA<AuthFailure>()),
        );
      }
      expect(repo.signInCalls, 0);
    });

    test(
      'network failure during sign-in is reported, state unchanged',
      () async {
        start(FakeAuthRepository()).read(authControllerProvider); // build
        repo.signInFailure = const AuthFailure(AuthFailureKind.network);
        await expectLater(
          auth().signIn(email: reader.email!, password: 'pw-reader'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.kind,
              'kind',
              AuthFailureKind.network,
            ),
          ),
        );
        expect(status(), AuthStatus.signedOut);
      },
    );

    test('logout clears the user and the in-memory permission', () async {
      start(
        FakeAuthRepository(
          restoredUser: editor,
          members: {editor.id: membership(editor, isAccessible: true)},
        ),
      );
      await settle();
      expect(container.read(canEditSharedContentProvider), isTrue);

      await auth().signOut();
      await settle();
      expect(status(), AuthStatus.signedOut);
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(canEditSharedContentProvider), isFalse);
      expect(container.read(memberAccessProvider).value, isNull);
    });

    test('a failed logout (session still present) is surfaced', () async {
      start(FakeAuthRepository(restoredUser: reader));
      repo.signOutFailure = const AuthFailure(AuthFailureKind.unknown);
      await expectLater(auth().signOut(), throwsA(isA<AuthFailure>()));
      expect(container.read(currentUserProvider), reader);
    });

    test('session expiry signs the user out', () async {
      start(
        FakeAuthRepository(
          restoredUser: reader,
          members: {reader.id: membership(reader, isAccessible: false)},
        ),
      );
      await settle();
      expect(status(), AuthStatus.readOnly);

      repo.expireSession();
      await settle();
      expect(status(), AuthStatus.signedOut);
    });

    test(
      'token refresh keeps the user and does not refetch membership',
      () async {
        start(
          FakeAuthRepository(
            restoredUser: reader,
            members: {reader.id: membership(reader, isAccessible: false)},
          ),
        );
        await settle();
        expect(repo.membershipCalls, 1);

        repo.emit(const AuthChange(user: reader)); // tokenRefreshed
        await settle();
        expect(status(), AuthStatus.readOnly);
        expect(repo.membershipCalls, 1);
      },
    );

    test('an auth stream error re-reads the session', () async {
      start(FakeAuthRepository(restoredUser: reader));
      await settle();
      repo.expireSession(); // session gone…
      repo.emitError(Exception('refresh failed')); // …and the stream errors
      await settle();
      expect(status(), AuthStatus.signedOut);
    });

    test('subscribes to auth changes exactly once', () async {
      start(FakeAuthRepository(restoredUser: reader));
      container.read(currentUserProvider);
      container.read(memberAccessProvider);
      container.read(canEditSharedContentProvider);
      await auth().signOut();
      await settle();
      expect(repo.listenCount, 1);
    });
  });

  group('password recovery', () {
    test('a reset request is sent for a valid email only', () async {
      start(FakeAuthRepository());
      await auth().requestPasswordReset(' reader@example.test ');
      await expectLater(
        auth().requestPasswordReset('nope'),
        throwsA(isA<AuthFailure>()),
      );
      expect(repo.resetRequests, [' reader@example.test ']);
    });

    test('recovery event requires a new password before the app', () async {
      start(
        FakeAuthRepository(
          members: {reader.id: membership(reader, isAccessible: false)},
        ),
      );
      repo.emit(const AuthChange(user: reader, isPasswordRecovery: true));
      await settle();
      expect(status(), AuthStatus.passwordRecovery);

      // A token refresh during recovery does not end recovery.
      repo.emit(const AuthChange(user: reader));
      await settle();
      expect(status(), AuthStatus.passwordRecovery);

      // A failed change keeps the user in recovery.
      repo.updatePasswordFailure = const AuthFailure(
        AuthFailureKind.weakPassword,
      );
      await expectLater(
        auth().updatePassword('longenough1'),
        throwsA(isA<AuthFailure>()),
      );
      expect(status(), AuthStatus.passwordRecovery);

      repo.updatePasswordFailure = null;
      await auth().updatePassword('longenough1');
      await settle();
      expect(repo.passwordUpdates, ['longenough1']);
      expect(status(), AuthStatus.readOnly);
    });

    test('too-short new passwords are rejected locally', () async {
      start(FakeAuthRepository(restoredUser: reader));
      await expectLater(
        auth().updatePassword('short'),
        throwsA(isA<AuthFailure>()),
      );
      expect(repo.passwordUpdates, isEmpty);
    });
  });

  group('membership', () {
    test('is_accessible = false → read-only member', () async {
      start(
        FakeAuthRepository(
          restoredUser: reader,
          members: {reader.id: membership(reader, isAccessible: false)},
        ),
      );
      await settle();
      expect(status(), AuthStatus.readOnly);
      expect(status().isMember, isTrue);
      expect(container.read(canEditSharedContentProvider), isFalse);
    });

    test('is_accessible = true → editor', () async {
      start(
        FakeAuthRepository(
          restoredUser: editor,
          members: {editor.id: membership(editor, isAccessible: true)},
        ),
      );
      await settle();
      expect(status(), AuthStatus.editor);
      expect(container.read(canEditSharedContentProvider), isTrue);
    });

    test('no row → membership missing, not an error', () async {
      start(FakeAuthRepository(restoredUser: reader));
      await settle();
      expect(status(), AuthStatus.membershipMissing);
      expect(container.read(canEditSharedContentProvider), isFalse);
    });

    for (final kind in MembershipFailureKind.values) {
      test(
        'lookup failure (${kind.name}) → retryable error, not missing',
        () async {
          start(
            FakeAuthRepository(
              restoredUser: editor,
              members: {editor.id: membership(editor, isAccessible: true)},
            ),
          );
          repo.membershipFailure = MembershipFailure(kind);
          await settle();
          expect(status(), AuthStatus.membershipError);
          expect(container.read(canEditSharedContentProvider), isFalse);

          // No automatic retry; the user retries.
          expect(repo.membershipCalls, 1);
          repo.membershipFailure = null;
          container.invalidate(memberAccessProvider);
          expect(status(), AuthStatus.loadingMembership);
          await settle();
          expect(status(), AuthStatus.editor);
        },
      );
    }

    test('loading state never grants editing', () async {
      final gate = Completer<void>();
      start(
        FakeAuthRepository(
          restoredUser: editor,
          members: {editor.id: membership(editor, isAccessible: true)},
        )..membershipGate = gate,
      );
      await settle();
      expect(status(), AuthStatus.loadingMembership);
      expect(container.read(canEditSharedContentProvider), isFalse);
      gate.complete();
      await settle();
      expect(container.read(canEditSharedContentProvider), isTrue);
    });
  });

  group('permission', () {
    test('comes from the server row, not from the user', () async {
      // Same user, two different server answers → two different results.
      for (final accessible in [false, true]) {
        start(
          FakeAuthRepository(
            restoredUser: reader,
            members: {reader.id: membership(reader, isAccessible: accessible)},
          ),
        );
        await settle();
        expect(container.read(canEditSharedContentProvider), accessible);
        container.dispose();
      }
      container = ProviderContainer(); // for tearDown
    });

    test('a revoked permission takes effect on the next check', () async {
      start(
        FakeAuthRepository(
          restoredUser: editor,
          members: {editor.id: membership(editor, isAccessible: true)},
        ),
      );
      await settle();
      expect(status(), AuthStatus.editor);

      // The owner revokes editing on the server.
      repo.members[editor.id] = membership(editor, isAccessible: false);

      // Re-checked on retry…
      container.invalidate(memberAccessProvider);
      expect(
        container.read(canEditSharedContentProvider),
        isFalse,
        reason: 'stale editor value is not used while re-checking',
      );
      await settle();
      expect(status(), AuthStatus.readOnly);

      // …and on every new sign-in.
      repo.members[editor.id] = membership(editor, isAccessible: true);
      await auth().signOut();
      await settle();
      repo.members.remove(editor.id);
      await auth().signIn(email: editor.email!, password: 'pw-editor');
      await settle();
      expect(status(), AuthStatus.membershipMissing);
    });

    test('a different user never inherits the previous permission', () async {
      start(
        FakeAuthRepository(
          restoredUser: editor,
          members: {
            editor.id: membership(editor, isAccessible: true),
            reader.id: membership(reader, isAccessible: false),
          },
        ),
      );
      await settle();
      expect(status(), AuthStatus.editor);
      await auth().signOut();
      await auth().signIn(email: reader.email!, password: 'pw-reader');
      expect(container.read(canEditSharedContentProvider), isFalse);
      await settle();
      expect(status(), AuthStatus.readOnly);
    });
  });

  group('registration', () {
    test('invalid input never reaches Supabase', () async {
      start(FakeAuthRepository());
      for (final (name, email, pw) in [
        ('', 'new@example.test', 'long-enough-1'),
        ('Asha', 'not-an-email', 'long-enough-1'),
        ('Asha', 'new@example.test', 'short'),
      ]) {
        await expectLater(
          auth().signUp(fullName: name, email: email, password: pw),
          throwsA(isA<AuthFailure>()),
        );
      }
      expect(repo.signUps, isEmpty);
    });

    test('email confirmation required: stays signed out', () async {
      start(FakeAuthRepository());
      final outcome = await auth().signUp(
        fullName: 'Asha',
        email: 'new@example.test',
        password: 'long-enough-1',
      );
      expect(outcome, SignUpOutcome.confirmEmail);
      expect(repo.signUps.single.fullName, 'Asha');
      expect(status(), AuthStatus.signedOut);
    });

    test('immediate session: the new user is a read-only member', () async {
      const u = FakeAuthRepository.newUser;
      start(
        FakeAuthRepository(members: {u.id: membership(u, isAccessible: false)})
          ..signUpSignsIn = true,
      );
      final outcome = await auth().signUp(
        fullName: 'Asha',
        email: 'new@example.test',
        password: 'long-enough-1',
      );
      expect(outcome, SignUpOutcome.signedIn);
      await settle();
      expect(status(), AuthStatus.readOnly);
      expect(container.read(canEditSharedContentProvider), isFalse);
    });

    test('server refusal is reported', () async {
      start(
        FakeAuthRepository()
          ..signUpFailure = const AuthFailure(
            AuthFailureKind.emailAlreadyRegistered,
          ),
      );
      await expectLater(
        auth().signUp(
          fullName: 'Asha',
          email: 'new@example.test',
          password: 'long-enough-1',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.kind,
            'kind',
            AuthFailureKind.emailAlreadyRegistered,
          ),
        ),
      );
    });
  });
}
