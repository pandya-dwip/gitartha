import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:gitartha/features/authentication/domain/entities/auth_failure.dart';
import 'package:gitartha/features/authentication/domain/repositories/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory PKCE verifier storage (the app uses SharedPreferences).
class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _items[key];
  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);
  @override
  Future<void> setItem({required String key, required String value}) async =>
      _items[key] = value;
}

/// The real Supabase-backed repository against a mocked HTTP layer:
/// verifies what is sent (own user id only, no writes) and how errors map.
void main() {
  const publishableKey = 'sb_publishable_TESTKEY';
  const userId = '00000000-0000-4000-8000-00000000e001';
  const otherUserId = '00000000-0000-4000-8000-00000000e002';

  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late SupabaseClient client;
  late SupabaseAuthRepository repo;

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    // Real Supabase Auth responses carry this; gotrue needs it to read
    // error codes.
    headers: {
      'content-type': 'application/json',
      'x-supabase-api-version': '2024-01-01',
    },
  );

  final session = {
    'access_token': 'TEST-ACCESS-TOKEN',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'TEST-REFRESH',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'member@example.test',
      'app_metadata': <String, Object>{},
      'user_metadata': <String, Object>{},
      'created_at': '2026-01-01T00:00:00Z',
    },
  };

  Map<String, Object?> row({
    String id = userId,
    Object? isAccessible = false,
  }) => {
    'user_id': id,
    'is_accessible': ?isAccessible,
    'created_at': '2026-01-01T00:00:00+00:00',
    'updated_at': '2026-02-01T00:00:00+00:00',
  };

  setUp(() {
    requests = [];
    respond = (r) {
      if (r.url.path == '/auth/v1/token') return json(session);
      if (r.url.path == '/auth/v1/logout') return http.Response('', 204);
      if (r.url.path == '/auth/v1/user') return json(session['user']!);
      if (r.url.path == '/auth/v1/recover') return json(<String, Object>{});
      if (r.url.path == '/rest/v1/app_members') return json(row());
      return http.Response('unexpected', 500);
    };
    client = SupabaseClient(
      'https://example-project.supabase.co',
      publishableKey,
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _MemoryAsyncStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final r = respond(request);
        return http.Response.bytes(
          r.bodyBytes,
          r.statusCode,
          headers: r.headers,
          request: request,
        );
      }),
    );
    repo = SupabaseAuthRepository(client);
  });

  tearDown(() => client.dispose());

  Future<void> signIn() =>
      repo.signIn(email: 'member@example.test', password: 'pw');

  Matcher authFailure(AuthFailureKind kind) =>
      throwsA(isA<AuthFailure>().having((e) => e.kind, 'kind', kind));

  Matcher membershipFailure(MembershipFailureKind kind) =>
      throwsA(isA<MembershipFailure>().having((e) => e.kind, 'kind', kind));

  group('sign-in', () {
    test(
      'password grant with the publishable key; user from session',
      () async {
        final user = await repo.signIn(
          email: '  member@example.test ',
          password: 'pw',
        );
        expect(user.id, userId);
        expect(repo.currentUser?.id, userId);

        final token = requests.single;
        expect(token.url.queryParameters['grant_type'], 'password');
        expect(token.headers['apikey'], publishableKey);
        expect(jsonDecode(token.body), {
          'email': 'member@example.test',
          'password': 'pw',
          'gotrue_meta_security': {'captcha_token': null},
        });
      },
    );

    final cases = <String, (http.Response, AuthFailureKind)>{
      'invalid credentials': (
        json({'code': 'invalid_credentials', 'msg': 'x'}, 400),
        AuthFailureKind.invalidCredentials,
      ),
      'email not confirmed': (
        json({'code': 'email_not_confirmed', 'msg': 'x'}, 400),
        AuthFailureKind.emailNotConfirmed,
      ),
      'disabled account': (
        json({'code': 'user_banned', 'msg': 'x'}, 400),
        AuthFailureKind.accountDisabled,
      ),
      'rate limited': (
        json({'code': 'over_request_rate_limit', 'msg': 'x'}, 429),
        AuthFailureKind.rateLimited,
      ),
      'service unavailable': (
        http.Response('down', 503),
        AuthFailureKind.serviceUnavailable,
      ),
    };
    cases.forEach((name, c) {
      test('maps $name', () async {
        respond = (_) => c.$1;
        await expectLater(signIn(), authFailure(c.$2));
        expect(repo.currentUser, isNull);
      });
    });

    test('maps network errors', () async {
      respond = (_) => throw http.ClientException('offline');
      await expectLater(signIn(), authFailure(AuthFailureKind.network));
    });

    test('error messages never contain server text', () async {
      respond = (_) => json({'code': 'x', 'msg': 'SECRET-SERVER-DETAIL'}, 400);
      try {
        await signIn();
        fail('expected failure');
      } on AuthFailure catch (e) {
        expect(e.message, isNot(contains('SECRET')));
        expect(e.toString(), isNot(contains('SECRET')));
      }
    });
  });

  group('membership', () {
    test('reads only the session user\'s row, and never writes', () async {
      await signIn();
      final access = await repo.fetchOwnMembership();
      expect(access!.userId, userId);
      expect(access.isAccessible, isFalse);
      expect(access.canEditSharedContent, isFalse);
      expect(access.updatedAt, DateTime.utc(2026, 2, 1));

      final query = requests.last;
      expect(query.method, 'GET');
      expect(query.url.queryParameters['user_id'], 'eq.$userId');
      expect(
        query.url.queryParameters['select'],
        'user_id,is_accessible,created_at,updated_at',
      );
      expect(query.headers['Authorization'], 'Bearer TEST-ACCESS-TOKEN');
      expect(
        requests
            .where((r) => r.url.path.startsWith('/rest/'))
            .map((r) => r.method),
        everyElement('GET'),
      );
    });

    test('is_accessible = true → can edit', () async {
      respond = (r) => r.url.path == '/auth/v1/token'
          ? json(session)
          : json(row(isAccessible: true));
      await signIn();
      expect((await repo.fetchOwnMembership())!.canEditSharedContent, isTrue);
    });

    test('no row → null (missing, not an error)', () async {
      respond = (r) =>
          r.url.path == '/auth/v1/token' ? json(session) : json(<Object>[]);
      await signIn();
      expect(await repo.fetchOwnMembership(), isNull);
    });

    final invalidRows = <String, Map<String, Object?>>{
      'missing is_accessible': row(isAccessible: null),
      'non-boolean is_accessible': row(isAccessible: 'true'),
      'another user\'s row': row(id: otherUserId, isAccessible: true),
      'missing timestamps': {'user_id': userId, 'is_accessible': true},
    };
    invalidRows.forEach((name, body) {
      test('rejects $name as an invalid response', () async {
        respond = (r) =>
            r.url.path == '/auth/v1/token' ? json(session) : json(body);
        await signIn();
        await expectLater(
          repo.fetchOwnMembership(),
          membershipFailure(MembershipFailureKind.invalidResponse),
        );
      });
    });

    test('RLS denial → accessDenied', () async {
      respond = (r) => r.url.path == '/auth/v1/token'
          ? json(session)
          : json({'code': '42501', 'message': 'permission denied'}, 403);
      await signIn();
      await expectLater(
        repo.fetchOwnMembership(),
        membershipFailure(MembershipFailureKind.accessDenied),
      );
    });

    test('server and network errors → unavailable (retryable)', () async {
      await signIn();
      respond = (_) => json({'code': 'XX000', 'message': 'boom'}, 503);
      await expectLater(
        repo.fetchOwnMembership(),
        membershipFailure(MembershipFailureKind.unavailable),
      );
      respond = (_) => throw http.ClientException('offline');
      await expectLater(
        repo.fetchOwnMembership(),
        membershipFailure(MembershipFailureKind.unavailable),
      );
    });

    test('without a session, nothing is queried', () async {
      await expectLater(
        repo.fetchOwnMembership(),
        membershipFailure(MembershipFailureKind.accessDenied),
      );
      expect(requests, isEmpty);
    });
  });

  group('sign-out', () {
    test('clears the session and emits signed-out', () async {
      await signIn();
      final changes = repo.authChanges.map((c) => c.user?.id).take(2).toList();
      await repo.signOut();
      expect(repo.currentUser, isNull);
      expect((await changes).last, isNull);
      expect(requests.last.url.path, '/auth/v1/logout');
    });

    test('works offline: the local session is still cleared', () async {
      await signIn();
      respond = (_) => throw http.ClientException('offline');
      await repo.signOut();
      expect(repo.currentUser, isNull);
    });
  });

  group('password recovery', () {
    test('reset email links back into the app', () async {
      await repo.requestPasswordReset(' member@example.test ');
      final recover = requests.single;
      expect(recover.url.path, '/auth/v1/recover');
      expect(
        recover.url.queryParameters['redirect_to'],
        SupabaseAuthRepository.authRedirectUrl,
      );
      expect(jsonDecode(recover.body)['email'], 'member@example.test');
    });

    test('update password is confirmed by the server', () async {
      await signIn();
      await repo.updatePassword('a-new-password');
      final update = requests.last;
      expect(update.method, 'PUT');
      expect(update.url.path, '/auth/v1/user');
      expect(jsonDecode(update.body)['password'], 'a-new-password');
    });

    test('weak / same password are reported', () async {
      await signIn();
      respond = (_) => json({'code': 'same_password', 'msg': 'x'}, 422);
      await expectLater(
        repo.updatePassword('a-new-password'),
        authFailure(AuthFailureKind.samePassword),
      );
      respond = (_) => json({
        'code': 'weak_password',
        'msg': 'x',
        'weak_password': {
          'reasons': ['length'],
        },
      }, 422);
      await expectLater(
        repo.updatePassword('a-new-password'),
        authFailure(AuthFailureKind.weakPassword),
      );
    });
  });

  test('error-code mapping covers session expiry', () {
    for (final code in [
      'session_expired',
      'session_not_found',
      'refresh_token_not_found',
    ]) {
      expect(
        authFailureKindFor(
          AuthApiException('x', statusCode: '403', code: code),
        ),
        AuthFailureKind.sessionExpired,
      );
    }
    expect(
      authFailureKindFor(AuthSessionMissingException()),
      AuthFailureKind.sessionExpired,
    );
  });

  group('registration', () {
    test('creates the Auth account with the name as metadata only', () async {
      respond = (_) => json(session['user']!); // no session: confirm email
      final outcome = await repo.signUp(
        email: ' new@example.test ',
        password: 'a-long-password',
        fullName: '  Asha Devi ',
      );
      expect(outcome, SignUpOutcome.confirmEmail);
      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/auth/v1/signup');
      expect(
        r.url.queryParameters['redirect_to'],
        SupabaseAuthRepository.authRedirectUrl,
      );
      final body = jsonDecode(r.body) as Map;
      expect(body['email'], 'new@example.test');
      expect(body['password'], 'a-long-password');
      expect(body['data'], {'full_name': 'Asha Devi'});
      expect(r.headers['apikey'], 'sb_publishable_TESTKEY');
      // Membership is created by the database trigger, never by the app.
      expect(requests.where((x) => x.url.path.startsWith('/rest/')), isEmpty);
    });

    test('signed in straight away when no confirmation is required', () async {
      respond = (_) => json(session);
      final outcome = await repo.signUp(
        email: 'new@example.test',
        password: 'a-long-password',
        fullName: 'Asha',
      );
      expect(outcome, SignUpOutcome.signedIn);
      expect(repo.currentUser?.id, userId);
    });

    final cases = <String, (http.Response, AuthFailureKind)>{
      'existing account': (
        json({'code': 'user_already_exists', 'msg': 'x'}, 422),
        AuthFailureKind.emailAlreadyRegistered,
      ),
      'sign-ups disabled': (
        json({'code': 'signup_disabled', 'msg': 'x'}, 422),
        AuthFailureKind.signupDisabled,
      ),
      'weak password': (
        json({
          'code': 'weak_password',
          'msg': 'x',
          'weak_password': {
            'reasons': ['length'],
          },
        }, 422),
        AuthFailureKind.weakPassword,
      ),
    };
    cases.forEach((name, c) {
      test('maps $name', () async {
        respond = (_) => c.$1;
        await expectLater(
          repo.signUp(
            email: 'new@example.test',
            password: 'a-long-password',
            fullName: 'A',
          ),
          authFailure(c.$2),
        );
      });
    });
  });
}
