import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/publishing/remote_content_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../tool/publishing/publishing_config.dart';
import '../../tool/publishing/supabase_remote_content_store.dart';

/// The real Supabase adapter against a mocked HTTP layer: verifies what is
/// actually sent (keys, session, conflict targets) and how errors map.
void main() {
  const publishableKey = 'sb_publishable_TESTKEY';
  const accessToken = 'TEST-ACCESS-TOKEN';
  const userId = '00000000-0000-4000-8000-00000000e001';

  PublishingConfig config() => PublishingConfig.load(
    envFile: 'does-not-exist.env',
    environment: {
      'SUPABASE_URL': 'https://example-project.supabase.co',
      'SUPABASE_PUBLISHABLE_KEY': publishableKey,
    },
  );

  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;

  SupabaseRemoteContentStore store() => SupabaseRemoteContentStore(
    config(),
    httpClient: MockClient((request) async {
      requests.add(request);
      final r = respond(request);
      // Real responses carry their request; the clients rely on it.
      return http.Response.bytes(
        r.bodyBytes,
        r.statusCode,
        headers: r.headers,
        reasonPhrase: r.reasonPhrase,
        request: request,
      );
    }),
  );

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  final session = {
    'access_token': accessToken,
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'TEST-REFRESH',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'editor@example.test',
      'app_metadata': <String, Object>{},
      'user_metadata': <String, Object>{},
      'created_at': '2026-01-01T00:00:00Z',
    },
  };

  setUp(() {
    requests = [];
    respond = (r) {
      if (r.url.path == '/auth/v1/token') return json(session);
      if (r.url.path == '/auth/v1/logout') return http.Response('', 204);
      if (r.url.path == '/rest/v1/app_members') {
        return json([
          {'user_id': userId, 'is_accessible': true},
        ]);
      }
      if (r.method == 'GET') return json(<Object>[]);
      return http.Response('', 201);
    };
  });

  Future<SupabaseRemoteContentStore> signedIn() async {
    final s = store();
    expect(
      await s.signIn(email: 'editor@example.test', password: 'pw'),
      userId,
    );
    return s;
  }

  test('signs in with password and reads only its own membership', () async {
    final s = await signedIn();
    final membership = await s.fetchOwnMembership();
    expect(membership!.isAccessible, isTrue);

    final login = requests.first;
    expect(login.url.path, '/auth/v1/token');
    expect(login.url.queryParameters['grant_type'], 'password');
    final read = requests.last;
    expect(read.method, 'GET');
    expect(read.url.queryParameters['user_id'], 'eq.$userId');
    expect(read.headers['apikey'], publishableKey);
    expect(read.headers['Authorization'], 'Bearer $accessToken');
    await s.close();
  });

  test('upserts on id with merge-duplicates, as the signed-in user', () async {
    final s = await signedIn();
    await s.upsert('shlokas', [
      {'id': 'x', 'chapter_id': 1, 'verse_number': 1},
    ]);
    final r = requests.last;
    expect(r.method, 'POST');
    expect(r.url.path, '/rest/v1/shlokas');
    expect(r.url.queryParameters['on_conflict'], 'id');
    expect(r.headers['Prefer'], contains('resolution=merge-duplicates'));
    expect(r.headers['Authorization'], 'Bearer $accessToken');
    expect(jsonDecode(r.body), [
      {'id': 'x', 'chapter_id': 1, 'verse_number': 1},
    ]);
    expect(
      () => s.upsert('app_members', [
        {'user_id': userId, 'is_accessible': true},
      ]),
      throwsArgumentError,
    );
    await s.close();
  });

  test(
    'attributions are inserted with ignore-duplicates on the natural key',
    () async {
      final s = await signedIn();
      await s.insertAttributions([
        {
          'id': 'a',
          'shloka_id': 'x',
          'source_id': 'y',
          'content_section': 'context',
        },
      ]);
      final r = requests.last;
      expect(r.url.path, '/rest/v1/shloka_source_attributions');
      expect(
        r.url.queryParameters['on_conflict'],
        'shloka_id,source_id,content_section',
      );
      expect(r.headers['Prefer'], contains('resolution=ignore-duplicates'));
      await s.close();
    },
  );

  test('Postgres and HTTP errors map to safe, typed failures', () async {
    final s = await signedIn();
    Future<RemoteErrorKind> kindFor(http.Response response) async {
      respond = (_) => response;
      try {
        await s.upsert('chapters', [
          {'id': 1},
        ]);
      } on RemoteStoreException catch (e) {
        expect(e.message, isNot(contains(accessToken)));
        return e.kind;
      }
      fail('expected an error');
    }

    expect(
      await kindFor(
        json({
          'code': '42501',
          'message':
              'new row violates row-level security policy for table "chapters"',
        }, 403),
      ),
      RemoteErrorKind.permissionDenied,
    );
    expect(
      await kindFor(json({'code': '23503', 'message': 'fk'}, 409)),
      RemoteErrorKind.foreignKeyViolation,
    );
    expect(
      await kindFor(json({'code': '23505', 'message': 'dup'}, 409)),
      RemoteErrorKind.uniqueViolation,
    );
    expect(
      await kindFor(json({'code': 'PGRST301', 'message': 'JWT expired'}, 401)),
      RemoteErrorKind.sessionExpired,
    );
    expect(
      await kindFor(http.Response('Too Many Requests', 429)),
      RemoteErrorKind.rateLimited,
    );
    expect(
      await kindFor(http.Response('Bad gateway', 502)),
      RemoteErrorKind.serviceUnavailable,
    );
    await s.close();
  });

  test('a missing column is reported as a schema mismatch', () async {
    final s = await signedIn();
    respond = (r) => r.url.path == '/rest/v1/shlokas'
        ? json({
            'code': '42703',
            'message': 'column shlokas.hindi_meaning_note does not exist',
          }, 400)
        : json(<Object>[]);
    await expectLater(
      s.verifySchema(),
      throwsA(
        isA<RemoteStoreException>()
            .having((e) => e.kind, 'kind', RemoteErrorKind.schemaMismatch)
            .having(
              (e) => e.message,
              'message',
              contains('hindi_meaning_note'),
            ),
      ),
    );
    await s.close();
  });

  test(
    'invalid credentials and network failures are friendly and safe',
    () async {
      respond = (_) => json({
        'code': 400,
        'error_code': 'invalid_credentials',
        'msg': 'Invalid login credentials',
      }, 400);
      await expectLater(
        store().signIn(email: 'editor@example.test', password: 'wrong'),
        throwsA(
          isA<PublisherAuthException>()
              .having(
                (e) => e.failure,
                'failure',
                PublisherAuthFailure.invalidCredentials,
              )
              .having((e) => e.message, 'message', isNot(contains('wrong'))),
        ),
      );

      final offline = SupabaseRemoteContentStore(
        config(),
        httpClient: MockClient(
          (_) async => throw const SocketException('down'),
        ),
      );
      await expectLater(
        offline.signIn(email: 'editor@example.test', password: 'pw'),
        throwsA(
          isA<PublisherAuthException>().having(
            (e) => e.failure,
            'failure',
            PublisherAuthFailure.network,
          ),
        ),
      );
    },
  );

  test(
    'close signs out and no request ever carries a privileged key',
    () async {
      final s = await signedIn();
      await s.fetchByIds('chapters', [1, 2], ['id']);
      await s.close();
      expect(requests.last.url.path, '/auth/v1/logout');
      for (final r in requests) {
        expect(r.headers['apikey'], publishableKey);
        expect(r.headers.values.join(' '), isNot(contains('service_role')));
        expect(r.headers.values.join(' '), isNot(contains('sb_secret_')));
      }
    },
  );

  group('configuration', () {
    PublishingConfig load(
      Map<String, String> env, {
      String file = 'none.env',
    }) => PublishingConfig.load(envFile: file, environment: env);

    test('missing or invalid settings are clear errors', () {
      expect(() => load({}), throwsA(isA<PublishingConfigException>()));
      expect(
        () => load({'SUPABASE_URL': 'https://x.supabase.co'}),
        throwsA(
          isA<PublishingConfigException>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_PUBLISHABLE_KEY'),
          ),
        ),
      );
      expect(
        () =>
            load({'SUPABASE_URL': 'ftp://x', 'SUPABASE_PUBLISHABLE_KEY': 'k'}),
        throwsA(isA<PublishingConfigException>()),
      );
      expect(
        () => load({
          'SUPABASE_URL': 'http://x.supabase.co',
          'SUPABASE_PUBLISHABLE_KEY': 'k',
        }),
        throwsA(isA<PublishingConfigException>()),
      );
    });

    test('secret and service-role keys are refused, without echoing them', () {
      String jwt(String role) {
        String part(Map<String, Object> m) =>
            base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
        return '${part({'alg': 'HS256'})}.${part({'role': role})}.sig';
      }

      for (final key in ['sb_secret_ABC', jwt('service_role')]) {
        expect(
          () => load({
            'SUPABASE_URL': 'https://x.supabase.co',
            'SUPABASE_PUBLISHABLE_KEY': key,
          }),
          throwsA(
            isA<PublishingConfigException>().having(
              (e) => e.message,
              'message',
              allOf(contains('refuses privileged keys'), isNot(contains(key))),
            ),
          ),
        );
      }
      // A legacy anon JWT is accepted (fallback variable).
      final anon = load({
        'SUPABASE_URL': 'https://x.supabase.co',
        'SUPABASE_ANON_KEY': jwt('anon'),
      });
      expect(anon.keyVariable, 'SUPABASE_ANON_KEY (legacy)');
    });

    test('.env is read, and the process environment wins', () async {
      final dir = await Directory.systemTemp.createTemp('gitartha_env');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/.env')
        ..writeAsStringSync(
          '# comment\nSUPABASE_URL="https://from-file.supabase.co"\n'
          "SUPABASE_PUBLISHABLE_KEY='sb_publishable_FILE'\n",
        );
      final fromFile = load({}, file: file.path);
      expect(fromFile.host, 'from-file.supabase.co');
      expect(fromFile.publishableKey, 'sb_publishable_FILE');

      final overridden = load({
        'SUPABASE_URL': 'https://from-env.supabase.co/',
      }, file: file.path);
      expect(overridden.url, 'https://from-env.supabase.co');
    });
  });

  test('publishing code never references privileged credentials', () {
    final sources = [
      ...Directory('tool').listSync(recursive: true),
      ...Directory('lib/data/content/publishing').listSync(recursive: true),
    ].whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final f in sources) {
      final text = f.readAsStringSync();
      for (final banned in [
        'SUPABASE_SERVICE_ROLE',
        'SERVICE_ROLE_KEY',
        'SUPABASE_SECRET',
        'DATABASE_URL',
        'postgresql://',
      ]) {
        expect(text, isNot(contains(banned)), reason: '${f.path}: $banned');
      }
    }
  });
}
