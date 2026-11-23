/// The publishing pipeline's only view of Supabase.
///
/// The interface is deliberately narrow:
///  * it can sign in as an existing user and read **only that user's own**
///    membership row; there is no method to write `app_members`;
///  * it reads and writes only the four shared-content tables; there are no
///    methods for personal data, because none exists in Supabase;
///  * it never deletes anything.
///
/// The real implementation (`tool/publishing/supabase_remote_content_store.dart`)
/// uses the publishable key and the signed-in user's session, so every read
/// and write is subject to Row Level Security. Tests use an in-memory fake.
abstract interface class RemoteContentStore {
  /// Where content is published, for reports (e.g. the project host).
  String get targetDescription;

  /// Signs in with email and password. Returns the user id. Throws
  /// [PublisherAuthException].
  Future<String> signIn({required String email, required String password});

  /// The signed-in user's own `app_members` row, or null if there is none.
  Future<MembershipRecord?> fetchOwnMembership();

  /// Checks that the remote tables have every column publishing needs.
  /// Throws [RemoteStoreException] with [RemoteErrorKind.schemaMismatch].
  Future<void> verifySchema();

  /// Rows of [table] whose `id` is in [ids] (soft-deleted rows included),
  /// with [columns].
  Future<List<Map<String, Object?>>> fetchByIds(
    String table,
    List<Object> ids,
    List<String> columns,
  );

  /// `id, chapter_id, verse_number, deleted_at` of every shloka in
  /// [chapterIds], to detect conflicts on the unique (chapter, verse) slot.
  Future<List<Map<String, Object?>>> fetchShlokaSlots(List<int> chapterIds);

  /// Every attribution of the given shloka UUIDs.
  Future<List<Map<String, Object?>>> fetchAttributions(List<String> shlokaIds);

  /// Inserts or updates [rows] of `chapters`, `content_sources` or `shlokas`
  /// (conflict target `id`). One request, so one SQL statement: all of
  /// [rows] succeed or none do.
  Future<void> upsert(String table, List<Map<String, Object?>> rows);

  /// Inserts attribution [rows], ignoring rows that already exist (conflict
  /// target `shloka_id, source_id, content_section`). Never updates or
  /// deletes.
  Future<void> insertAttributions(List<Map<String, Object?>> rows);

  /// Ends the session (best effort) and releases resources.
  Future<void> close();
}

class MembershipRecord {
  const MembershipRecord({required this.userId, required this.isAccessible});

  final String userId;
  final bool isAccessible;
}

enum PublisherAuthFailure {
  invalidCredentials,
  emailNotConfirmed,
  network,
  serviceUnavailable,
  unknown,
}

/// Sign-in failed. [message] is safe to show: it never contains the
/// password, tokens or raw server responses.
class PublisherAuthException implements Exception {
  const PublisherAuthException(this.failure, this.message);

  final PublisherAuthFailure failure;
  final String message;

  @override
  String toString() => 'PublisherAuthException(${failure.name}): $message';
}

enum RemoteErrorKind {
  /// RLS or missing privileges rejected the request (SQLSTATE 42501).
  permissionDenied,

  /// The session expired or is invalid (HTTP 401 / JWT errors).
  sessionExpired,

  foreignKeyViolation,
  uniqueViolation,
  checkViolation,

  /// A column or table publishing needs does not exist remotely.
  schemaMismatch,

  rateLimited,
  network,
  serviceUnavailable,
  unknown;

  /// Whether further requests are pointless after this error, so the run
  /// must stop instead of continuing with independent records.
  bool get stopsRun => switch (this) {
    permissionDenied ||
    sessionExpired ||
    schemaMismatch ||
    rateLimited ||
    network ||
    serviceUnavailable => true,
    foreignKeyViolation ||
    uniqueViolation ||
    checkViolation ||
    unknown => false,
  };
}

/// A remote request failed. [message] is safe to show and to store in
/// reports: no keys, tokens or passwords.
class RemoteStoreException implements Exception {
  const RemoteStoreException(this.kind, this.message, {this.code});

  final RemoteErrorKind kind;
  final String message;

  /// SQLSTATE or HTTP status, when known.
  final String? code;

  @override
  String toString() =>
      'RemoteStoreException(${kind.name}${code == null ? '' : ', $code'}): '
      '$message';
}
