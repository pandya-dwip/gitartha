import 'dart:async';
import 'dart:io';

import 'package:gitartha/data/content/publishing/mappers/attribution_supabase_mapper.dart';
import 'package:gitartha/data/content/publishing/mappers/chapter_supabase_mapper.dart';
import 'package:gitartha/data/content/publishing/mappers/shloka_supabase_mapper.dart';
import 'package:gitartha/data/content/publishing/mappers/source_supabase_mapper.dart';
import 'package:gitartha/data/content/publishing/remote_content_store.dart';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';

import 'publishing_config.dart';

/// [RemoteContentStore] over the Supabase REST and Auth APIs, as the
/// signed-in publisher.
///
/// * Uses only the **publishable** key (checked by [PublishingConfig]) and
///   the user's own session. Every request is subject to RLS.
/// * The session lives in memory for this process only. The pure-Dart
///   client persists nothing, and token auto-refresh is off, so no timer
///   keeps the CLI alive. [close] signs out and disposes the client.
/// * Error messages are rewritten into safe text: no tokens, keys or raw
///   auth responses.
class SupabaseRemoteContentStore implements RemoteContentStore {
  SupabaseRemoteContentStore(this.config, {http.Client? httpClient})
    : _client = SupabaseClient(
        config.url,
        config.publishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: httpClient,
      );

  final PublishingConfig config;
  final SupabaseClient _client;

  static const Duration _timeout = Duration(seconds: 30);
  static const int _idChunk = 100;
  static const int _pageSize = 1000;

  @override
  String get targetDescription => config.host;

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(_timeout);
      final user = response.user;
      if (user == null || response.session == null) {
        throw const PublisherAuthException(
          PublisherAuthFailure.unknown,
          'Sign-in did not return a session.',
        );
      }
      return user.id;
    } on PublisherAuthException {
      rethrow;
    } on AuthException catch (e) {
      throw _authFailure(e);
    } on TimeoutException {
      throw const PublisherAuthException(
        PublisherAuthFailure.network,
        'Supabase Auth did not respond in time.',
      );
    } on Object catch (e) {
      if (_isNetworkError(e)) {
        throw const PublisherAuthException(
          PublisherAuthFailure.network,
          'Could not reach Supabase Auth. Check your connection.',
        );
      }
      throw PublisherAuthException(
        PublisherAuthFailure.unknown,
        'Sign-in failed (${e.runtimeType}).',
      );
    }
  }

  @override
  Future<MembershipRecord?> fetchOwnMembership() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _guard(
      () => _client
          .from('app_members')
          .select('user_id, is_accessible')
          .eq('user_id', userId)
          .maybeSingle(),
    );
    if (row == null) return null;
    return MembershipRecord(
      userId: row['user_id']! as String,
      isAccessible: row['is_accessible'] == true,
    );
  }

  @override
  Future<void> verifySchema() async {
    for (final (table, columns) in [
      (ChapterSupabaseMapper.table, ChapterSupabaseMapper.selectColumns),
      (SourceSupabaseMapper.table, SourceSupabaseMapper.selectColumns),
      (ShlokaSupabaseMapper.table, ShlokaSupabaseMapper.selectColumns),
      (
        AttributionSupabaseMapper.table,
        AttributionSupabaseMapper.selectColumns,
      ),
    ]) {
      try {
        await _guard(
          () => _client.from(table).select(columns.join(',')).limit(1),
        );
      } on RemoteStoreException catch (e) {
        if (e.kind == RemoteErrorKind.schemaMismatch) {
          throw RemoteStoreException(
            RemoteErrorKind.schemaMismatch,
            'Supabase table "$table" does not have the expected columns '
            '(${columns.join(', ')}). Is supabase/migrations/0001_initial_'
            'schema.sql applied, including hindi_meaning_note? ${e.message}',
            code: e.code,
          );
        }
        rethrow;
      }
    }
  }

  @override
  Future<List<Map<String, Object?>>> fetchByIds(
    String table,
    List<Object> ids,
    List<String> columns,
  ) async {
    final rows = <Map<String, Object?>>[];
    for (var i = 0; i < ids.length; i += _idChunk) {
      final chunk = ids.sublist(i, (i + _idChunk).clamp(0, ids.length));
      rows.addAll(
        await _paged(
          (from, to) => _client
              .from(table)
              .select(columns.join(','))
              .inFilter('id', chunk)
              .order('id')
              .range(from, to),
        ),
      );
    }
    return rows;
  }

  @override
  Future<List<Map<String, Object?>>> fetchShlokaSlots(List<int> chapterIds) {
    if (chapterIds.isEmpty) return Future.value(const []);
    return _paged(
      (from, to) => _client
          .from(ShlokaSupabaseMapper.table)
          .select('id,chapter_id,verse_number,deleted_at')
          .inFilter('chapter_id', chapterIds)
          .order('id')
          .range(from, to),
    );
  }

  @override
  Future<List<Map<String, Object?>>> fetchAttributions(
    List<String> shlokaIds,
  ) async {
    final rows = <Map<String, Object?>>[];
    for (var i = 0; i < shlokaIds.length; i += _idChunk) {
      final chunk = shlokaIds.sublist(
        i,
        (i + _idChunk).clamp(0, shlokaIds.length),
      );
      rows.addAll(
        await _paged(
          (from, to) => _client
              .from(AttributionSupabaseMapper.table)
              .select(AttributionSupabaseMapper.selectColumns.join(','))
              .inFilter('shloka_id', chunk)
              .order('id')
              .range(from, to),
        ),
      );
    }
    return rows;
  }

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) {
    const allowed = {
      ChapterSupabaseMapper.table,
      SourceSupabaseMapper.table,
      ShlokaSupabaseMapper.table,
    };
    if (!allowed.contains(table)) {
      throw ArgumentError.value(table, 'table', 'not a publishable table');
    }
    // INSERT … ON CONFLICT (id) DO UPDATE. The database trigger keeps
    // created_at and sets updated_at; deleted_at is never sent.
    return _guard(() => _client.from(table).upsert(rows, onConflict: 'id'));
  }

  @override
  Future<void> insertAttributions(List<Map<String, Object?>> rows) => _guard(
    // INSERT … ON CONFLICT (shloka_id, source_id, content_section) DO
    // NOTHING. Needs only the INSERT privilege; never updates or deletes.
    () => _client
        .from(AttributionSupabaseMapper.table)
        .upsert(
          rows,
          onConflict: AttributionSupabaseMapper.conflictTarget,
          ignoreDuplicates: true,
        ),
  );

  @override
  Future<void> close() async {
    try {
      if (_client.auth.currentSession != null) {
        await _client.auth.signOut().timeout(const Duration(seconds: 10));
      }
    } on Object {
      // Best effort: the in-memory session disappears with the process.
    } finally {
      await _client.dispose();
    }
  }

  // ---------------------------------------------------------------------------

  Future<List<Map<String, Object?>>> _paged(
    PostgrestTransformBuilder<List<Map<String, dynamic>>> Function(
      int from,
      int to,
    )
    page,
  ) async {
    final rows = <Map<String, Object?>>[];
    for (var from = 0; ; from += _pageSize) {
      final batch = await _guard(() => page(from, from + _pageSize - 1));
      rows.addAll(batch.map((r) => r.cast<String, Object?>()));
      if (batch.length < _pageSize) return rows;
    }
  }

  /// Runs a request with a timeout and turns failures into
  /// [RemoteStoreException]s with safe messages.
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    } on TimeoutException {
      throw const RemoteStoreException(
        RemoteErrorKind.network,
        'Supabase did not respond within 30 seconds.',
      );
    } on Object catch (e) {
      if (_isNetworkError(e)) {
        throw const RemoteStoreException(
          RemoteErrorKind.network,
          'Could not reach Supabase. Check your connection.',
        );
      }
      rethrow;
    }
  }

  /// Maps PostgREST / Postgres error codes to [RemoteErrorKind]s.
  static RemoteStoreException mapPostgrestError(PostgrestException e) {
    final code = e.code ?? '';
    final message = e.message.length > 300
        ? '${e.message.substring(0, 300)}…'
        : e.message;
    final kind = switch (code) {
      '42501' => RemoteErrorKind.permissionDenied,
      '23503' => RemoteErrorKind.foreignKeyViolation,
      '23505' => RemoteErrorKind.uniqueViolation,
      '23514' => RemoteErrorKind.checkViolation,
      '42703' ||
      '42P01' ||
      'PGRST204' ||
      'PGRST205' ||
      'PGRST200' => RemoteErrorKind.schemaMismatch,
      'PGRST301' ||
      'PGRST302' ||
      'PGRST303' ||
      '401' => RemoteErrorKind.sessionExpired,
      '403' => RemoteErrorKind.permissionDenied,
      '429' => RemoteErrorKind.rateLimited,
      _ when code.startsWith('5') && code.length == 3 =>
        RemoteErrorKind.serviceUnavailable,
      _ => RemoteErrorKind.unknown,
    };
    return RemoteStoreException(kind, switch (kind) {
      RemoteErrorKind.permissionDenied =>
        'Row Level Security rejected the request: $message',
      RemoteErrorKind.sessionExpired =>
        'Your session expired or is invalid. Run the command again.',
      RemoteErrorKind.rateLimited =>
        'Supabase is rate-limiting requests. Wait a minute and re-run.',
      RemoteErrorKind.serviceUnavailable =>
        'Supabase is unavailable right now ($code).',
      _ => message,
    }, code: code.isEmpty ? null : code);
  }

  static PublisherAuthException _authFailure(AuthException e) {
    final code = e.code ?? '';
    if (code == 'invalid_credentials' ||
        (e.statusCode == '400' && code.isEmpty)) {
      return const PublisherAuthException(
        PublisherAuthFailure.invalidCredentials,
        'Invalid email or password.',
      );
    }
    if (code == 'email_not_confirmed') {
      return const PublisherAuthException(
        PublisherAuthFailure.emailNotConfirmed,
        'This account has not confirmed its email address yet. Accept the '
        'invitation email first.',
      );
    }
    if (e is AuthRetryableFetchException) {
      return const PublisherAuthException(
        PublisherAuthFailure.network,
        'Could not reach Supabase Auth. Check your connection.',
      );
    }
    final status = int.tryParse(e.statusCode ?? '');
    if (status != null && status >= 500) {
      return PublisherAuthException(
        PublisherAuthFailure.serviceUnavailable,
        'Supabase Auth is unavailable right now ($status).',
      );
    }
    if (status == 429 || code == 'over_request_rate_limit') {
      return const PublisherAuthException(
        PublisherAuthFailure.serviceUnavailable,
        'Too many sign-in attempts. Wait a few minutes and try again.',
      );
    }
    return PublisherAuthException(
      PublisherAuthFailure.unknown,
      'Sign-in failed${code.isEmpty ? '' : ' ($code)'}.',
    );
  }

  static bool _isNetworkError(Object e) =>
      e is SocketException ||
      e is http.ClientException ||
      e is HandshakeException;
}
