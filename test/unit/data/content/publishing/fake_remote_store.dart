import 'package:gitartha/data/content/publishing/remote_content_store.dart';

/// In-memory stand-in for Supabase that behaves like the real schema
/// (supabase/migrations/0001_initial_schema.sql):
///
///  * reads require a membership row, writes require `is_accessible`
///    (RLS), otherwise `permissionDenied` (42501);
///  * foreign keys, the unique (chapter_id, verse_number) slot and the
///    unique attribution triple are enforced;
///  * `created_at` / `updated_at` are set like the `set_row_timestamps`
///    trigger; `deleted_at` is only ever changed by the test itself;
///  * `reference` is generated for shlokas;
///  * an upsert batch is atomic (validated fully before applying);
///  * there is no delete and no membership write: like the real store.
class FakeRemoteStore implements RemoteContentStore {
  FakeRemoteStore({
    Map<String, ({String password, String userId})>? users,
    Map<String, bool>? members,
  }) : users = users ?? {},
       members = members ?? {};

  final Map<String, ({String password, String userId})> users;

  /// userId -> is_accessible. Tests may flip it to simulate a revoked
  /// permission mid-run.
  final Map<String, bool> members;

  final Map<String, Map<String, Map<String, Object?>>> tables = {
    'chapters': {},
    'content_sources': {},
    'shlokas': {},
    'shloka_source_attributions': {},
  };

  /// Every call, in order: `signIn`, `read <table>`, `upsert <table> [ids]`,
  /// `insert attributions [ids]`, `close`.
  final List<String> log = [];

  String? currentUser;
  bool closed = false;
  bool schemaMatches = true;
  int _clock = 0;

  /// Return an exception to make a write fail.
  RemoteStoreException? Function(String table, List<Map<String, Object?>> rows)?
  failWrite;

  List<String> get writes => log
      .where((l) => l.startsWith('upsert') || l.startsWith('insert'))
      .toList();

  String _now() => '2026-01-01T00:00:${(_clock++).toString().padLeft(2, '0')}Z';

  bool get _canRead => currentUser != null && members.containsKey(currentUser);
  bool get _canWrite => currentUser != null && members[currentUser] == true;

  @override
  String get targetDescription => 'fake.supabase.test';

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    log.add('signIn');
    final user = users[email];
    if (user == null || user.password != password) {
      throw const PublisherAuthException(
        PublisherAuthFailure.invalidCredentials,
        'Invalid email or password.',
      );
    }
    return currentUser = user.userId;
  }

  @override
  Future<MembershipRecord?> fetchOwnMembership() async {
    log.add('read app_members');
    final id = currentUser;
    if (id == null || !members.containsKey(id)) return null;
    return MembershipRecord(userId: id, isAccessible: members[id]!);
  }

  @override
  Future<void> verifySchema() async {
    log.add('verifySchema');
    if (!schemaMatches) {
      throw const RemoteStoreException(
        RemoteErrorKind.schemaMismatch,
        'column shlokas.hindi_meaning_note does not exist',
        code: '42703',
      );
    }
  }

  @override
  Future<List<Map<String, Object?>>> fetchByIds(
    String table,
    List<Object> ids,
    List<String> columns,
  ) async {
    log.add('read $table');
    if (!_canRead) return const [];
    final wanted = ids.map((i) => '$i').toSet();
    return [
      for (final row in tables[table]!.values)
        if (wanted.contains('${row['id']}')) Map.of(row),
    ];
  }

  @override
  Future<List<Map<String, Object?>>> fetchShlokaSlots(
    List<int> chapterIds,
  ) async {
    log.add('read shloka slots');
    if (!_canRead) return const [];
    return [
      for (final row in tables['shlokas']!.values)
        if (chapterIds.contains(row['chapter_id'])) Map.of(row),
    ];
  }

  @override
  Future<List<Map<String, Object?>>> fetchAttributions(
    List<String> shlokaIds,
  ) async {
    log.add('read shloka_source_attributions');
    if (!_canRead) return const [];
    return [
      for (final row in tables['shloka_source_attributions']!.values)
        if (shlokaIds.contains(row['shloka_id'])) Map.of(row),
    ];
  }

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    log.add('upsert $table ${rows.map((r) => r['id']).toList()}');
    _checkWrite(table, rows);
    final target = tables[table]!;
    // Validate the whole batch first: one statement, all or nothing.
    for (final row in rows) {
      if (table == 'shlokas') {
        if (!tables['chapters']!.containsKey('${row['chapter_id']}')) {
          throw const RemoteStoreException(
            RemoteErrorKind.foreignKeyViolation,
            'insert or update on table "shlokas" violates foreign key '
            'constraint "shlokas_chapter_id_fkey"',
            code: '23503',
          );
        }
        final clash = target.values.any(
          (s) =>
              s['id'] != row['id'] &&
              s['chapter_id'] == row['chapter_id'] &&
              s['verse_number'] == row['verse_number'],
        );
        if (clash) {
          throw const RemoteStoreException(
            RemoteErrorKind.uniqueViolation,
            'duplicate key value violates unique constraint '
            '"shlokas_chapter_verse_key"',
            code: '23505',
          );
        }
      }
    }
    for (final row in rows) {
      final id = '${row['id']}';
      final existing = target[id];
      final now = _now();
      target[id] = {
        ...?existing,
        ...row,
        'created_at': existing?['created_at'] ?? now,
        'updated_at': now,
        'deleted_at': existing?['deleted_at'],
        if (table == 'shlokas')
          'reference': '${row['chapter_id']}.${row['verse_number']}',
      };
    }
  }

  @override
  Future<void> insertAttributions(List<Map<String, Object?>> rows) async {
    log.add('insert attributions ${rows.map((r) => r['id']).toList()}');
    const table = 'shloka_source_attributions';
    _checkWrite(table, rows);
    for (final row in rows) {
      if (!tables['shlokas']!.containsKey(row['shloka_id']) ||
          !tables['content_sources']!.containsKey(row['source_id'])) {
        throw const RemoteStoreException(
          RemoteErrorKind.foreignKeyViolation,
          'insert on table "shloka_source_attributions" violates a foreign '
          'key constraint',
          code: '23503',
        );
      }
    }
    final target = tables[table]!;
    for (final row in rows) {
      final duplicate = target.values.any(
        (a) =>
            a['shloka_id'] == row['shloka_id'] &&
            a['source_id'] == row['source_id'] &&
            a['content_section'] == row['content_section'],
      );
      if (duplicate) continue; // ON CONFLICT DO NOTHING
      target['${row['id']}'] = {...row, 'created_at': _now()};
    }
  }

  void _checkWrite(String table, List<Map<String, Object?>> rows) {
    final injected = failWrite?.call(table, rows);
    if (injected != null) throw injected;
    if (!_canWrite) {
      throw RemoteStoreException(
        RemoteErrorKind.permissionDenied,
        'Row Level Security rejected the request: new row violates '
        'row-level security policy for table "$table"',
        code: '42501',
      );
    }
  }

  @override
  Future<void> close() async {
    log.add('close');
    closed = true;
    currentUser = null;
  }

  // ----- Test helpers --------------------------------------------------------

  /// Puts a row directly into a table (as if created earlier in Supabase).
  void seed(String table, Map<String, Object?> row) {
    tables[table]!['${row['id']}'] = {
      'created_at': '2025-06-01T00:00:00Z',
      'updated_at': '2025-06-01T00:00:00Z',
      'deleted_at': null,
      ...row,
    };
  }

  int count(String table) => tables[table]!.length;
}
