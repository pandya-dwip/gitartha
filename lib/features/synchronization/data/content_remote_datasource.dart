import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/content/publishing/mappers/attribution_supabase_mapper.dart';
import '../../../data/content/publishing/mappers/chapter_supabase_mapper.dart';
import '../../../data/content/publishing/mappers/shloka_supabase_mapper.dart';
import '../../../data/content/publishing/mappers/source_supabase_mapper.dart';
import '../../../data/local/database/converters.dart';
import '../domain/sync_result.dart';

/// Remote table name, selected columns (shared with the publisher's
/// mappers, so both agree on the schema) and the server-maintained
/// timestamp used for incremental sync.
extension SyncTableSchema on SyncTable {
  String get remoteName => switch (this) {
    SyncTable.chapters => ChapterSupabaseMapper.table,
    SyncTable.contentSources => SourceSupabaseMapper.table,
    SyncTable.shlokas => ShlokaSupabaseMapper.table,
    SyncTable.attributions => AttributionSupabaseMapper.table,
  };

  List<String> get columns => switch (this) {
    SyncTable.chapters => ChapterSupabaseMapper.selectColumns,
    SyncTable.contentSources => SourceSupabaseMapper.selectColumns,
    SyncTable.shlokas => ShlokaSupabaseMapper.selectColumns,
    SyncTable.attributions => AttributionSupabaseMapper.selectColumns,
  };

  /// `shloka_source_attributions` has no `updated_at`: rows are immutable,
  /// so new rows are found by `created_at`.
  String get timestampColumn =>
      this == SyncTable.attributions ? 'created_at' : 'updated_at';
}

/// The position after the last row of a page: keyset pagination on
/// `(timestamp, id)`. [timestamp] is normalized UTC ISO 8601 with
/// microseconds (`...Z`).
typedef PageCursor = ({String timestamp, Object id});

/// Reads shared-content rows from Supabase, one ordered page at a time.
abstract interface class ContentRemoteDataSource {
  /// Rows of [table] ordered by `(timestamp, id)` ascending, at most
  /// [limit] of them:
  ///  * with [after]: strictly after that `(timestamp, id)` position;
  ///  * otherwise, with [since]: `timestamp >= since`;
  ///  * otherwise: from the beginning (all rows, tombstones included).
  ///
  /// Throws [SyncException] on any failure.
  Future<List<Map<String, dynamic>>> fetchPage(
    SyncTable table, {
    String? since,
    PageCursor? after,
    required int limit,
  });
}

/// [ContentRemoteDataSource] over PostgREST, as the signed-in member: the
/// publishable key plus the user's session, so RLS applies to every row.
/// Read-only: this class never writes.
class SupabaseContentDataSource implements ContentRemoteDataSource {
  SupabaseContentDataSource(this._client);

  final SupabaseClient _client;

  static const _timeout = Duration(seconds: 30);

  @override
  Future<List<Map<String, dynamic>>> fetchPage(
    SyncTable table, {
    String? since,
    PageCursor? after,
    required int limit,
  }) async {
    final ts = table.timestampColumn;
    var query = _client.from(table.remoteName).select(table.columns.join(','));
    if (after != null) {
      // Timestamps contain PostgREST-reserved characters (`.`, `:`), so
      // they are quoted inside the logic tree.
      final at = '"${after.timestamp}"';
      query = query.or('$ts.gt.$at,and($ts.eq.$at,id.gt.${after.id})');
    } else if (since != null) {
      query = query.gte(ts, since);
    }
    try {
      return await query
          .order(ts, ascending: true)
          .order('id', ascending: true)
          .limit(limit)
          .timeout(_timeout);
    } on PostgrestException catch (e) {
      throw SyncException(_kindFor(e), 'PostgREST ${e.code} on ${table.name}');
    } on AuthException catch (e) {
      // The client could not refresh the session before the request.
      throw SyncException(
        SyncFailureKind.unauthenticated,
        'auth ${e.statusCode} on ${table.name}',
      );
    } on TimeoutException {
      throw SyncException(SyncFailureKind.offline, 'timeout on ${table.name}');
    } on SocketException {
      throw const SyncException(SyncFailureKind.offline, 'socket');
    } on http.ClientException {
      throw const SyncException(SyncFailureKind.offline, 'client');
    }
  }

  static SyncFailureKind _kindFor(PostgrestException e) {
    final code = e.code ?? '';
    // Expired / invalid JWT.
    if (code == 'PGRST301' || code == 'PGRST302' || code == '401') {
      return SyncFailureKind.unauthenticated;
    }
    if (code == '42501' || code == '403') {
      return SyncFailureKind.membershipUnavailable;
    }
    // Missing table/column: the server schema is not what this app expects.
    if (code == '42P01' || code == '42703' || code.startsWith('PGRST2')) {
      return SyncFailureKind.invalidRemoteData;
    }
    return SyncFailureKind.serviceUnavailable;
  }
}

/// Converts a PostgREST `timestamptz` (e.g. `2026-01-01T09:00:00.123456+00:00`)
/// to the fixed-width UTC form used for cursors and SQLite (`...Z`).
String normalizeRemoteTimestamp(String value) =>
    formatUtcTimestamp(DateTime.parse(value));
