import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/features/synchronization/data/content_remote_datasource.dart';
import 'package:gitartha/features/synchronization/domain/sync_result.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The real PostgREST adapter over a mocked HTTP layer: verifies the exact
/// queries sent and how failures are classified.
void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late SupabaseClient client;
  late SupabaseContentDataSource source;

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  setUp(() {
    requests = [];
    respond = (_) => json(<Object>[]);
    client = SupabaseClient(
      'https://example-project.supabase.co',
      'sb_publishable_TESTKEY',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
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
    source = SupabaseContentDataSource(client);
  });
  tearDown(() => client.dispose());

  Matcher fails(SyncFailureKind kind) =>
      throwsA(isA<SyncException>().having((e) => e.kind, 'kind', kind));

  test('full read: ascending (updated_at, id), limit, every column', () async {
    await source.fetchPage(SyncTable.shlokas, limit: 500);
    final q = requests.single.url.queryParameters;
    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, '/rest/v1/shlokas');
    expect(q['order'], 'updated_at.asc.nullslast,id.asc.nullslast');
    expect(q['limit'], '500');
    expect(q.containsKey('updated_at'), isFalse, reason: 'no lower bound');
    expect(
      q['select']!.split(','),
      containsAll([
        'hindi_meaning_note',
        'deleted_at',
        'sanskrit_text',
        'reflection_question',
      ]),
    );
  });

  test('incremental read uses >= since', () async {
    await source.fetchPage(
      SyncTable.contentSources,
      since: '2026-03-01T11:50:00.000000Z',
      limit: 100,
    );
    final q = requests.single.url.queryParameters;
    expect(requests.single.url.path, '/rest/v1/content_sources');
    expect(q['updated_at'], 'gte.2026-03-01T11:50:00.000000Z');
  });

  test('next page uses a quoted keyset filter on (timestamp, id)', () async {
    const ts = '2026-03-01T12:00:00.123456Z';
    await source.fetchPage(
      SyncTable.chapters,
      after: (timestamp: ts, id: 7),
      limit: 10,
    );
    expect(
      requests.single.url.queryParameters['or'],
      '(updated_at.gt."$ts",and(updated_at.eq."$ts",id.gt.7))',
    );
  });

  test('attributions page by created_at (they have no updated_at)', () async {
    await source.fetchPage(
      SyncTable.attributions,
      since: '2026-03-01T00:00:00.000000Z',
      limit: 10,
    );
    final q = requests.single.url.queryParameters;
    expect(requests.single.url.path, '/rest/v1/shloka_source_attributions');
    expect(q['created_at'], 'gte.2026-03-01T00:00:00.000000Z');
    expect(q['order'], 'created_at.asc.nullslast,id.asc.nullslast');
  });

  test('returns rows as sent', () async {
    respond = (_) => json([
      {'id': 1, 'updated_at': '2026-03-01T12:00:00+00:00'},
    ]);
    final rows = await source.fetchPage(SyncTable.chapters, limit: 10);
    expect(rows.single['id'], 1);
  });

  final errors = <String, (http.Response, SyncFailureKind)>{
    'expired JWT': (
      json({'code': 'PGRST301', 'message': 'JWT expired'}, 401),
      SyncFailureKind.unauthenticated,
    ),
    'RLS / privilege denial': (
      json({'code': '42501', 'message': 'permission denied'}, 403),
      SyncFailureKind.membershipUnavailable,
    ),
    'missing column (schema mismatch)': (
      json({'code': '42703', 'message': 'column does not exist'}, 400),
      SyncFailureKind.invalidRemoteData,
    ),
    'server error': (
      json({'code': 'XX000', 'message': 'boom'}, 503),
      SyncFailureKind.serviceUnavailable,
    ),
  };
  errors.forEach((name, c) {
    test('maps $name', () async {
      respond = (_) => c.$1;
      await expectLater(
        source.fetchPage(SyncTable.shlokas, limit: 10),
        fails(c.$2),
      );
    });
  });

  test('maps network failure to offline', () async {
    respond = (_) => throw http.ClientException('offline');
    await expectLater(
      source.fetchPage(SyncTable.shlokas, limit: 10),
      fails(SyncFailureKind.offline),
    );
  });

  test('timestamps are normalized to fixed-width UTC', () {
    expect(
      normalizeRemoteTimestamp('2026-03-01T17:30:00.5+05:30'),
      '2026-03-01T12:00:00.500000Z',
    );
    expect(
      normalizeRemoteTimestamp('2026-03-01T12:00:00.123456+00:00'),
      '2026-03-01T12:00:00.123456Z',
    );
  });
}
