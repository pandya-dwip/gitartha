/// Shared-content sync (Supabase → SQLite): states, typed failures and the
/// structured result of one run. Pure Dart.
library;

enum SyncStatus {
  /// Nothing has happened yet in this app run.
  idle,

  /// Preparing a run (reading checkpoints).
  checking,
  syncing,

  /// Completed, and local content changed.
  success,

  /// Completed; the cache was already up to date.
  noChanges,

  /// The server could not be reached. The cache is still readable.
  offline,

  /// No session, or the session expired during the run.
  unauthenticated,

  /// Signed in, but not a confirmed member (missing, error, loading).
  membershipUnavailable,

  /// Any other failure (server error, bad data, local database).
  failed,
}

/// Why a run failed. [message] is safe to show to users.
enum SyncFailureKind {
  offline('Offline. Showing the scripture saved on this device.'),
  serviceUnavailable(
    'The server is unavailable right now. Showing the scripture saved on '
    'this device.',
  ),
  unauthenticated('Your session has expired. Sign in again to update.'),
  membershipUnavailable('Your account cannot download scripture right now.'),
  invalidRemoteData(
    'The server sent content this version of the app cannot read. Try '
    'again later or update the app.',
  ),
  localDatabase(
    'The update could not be saved on this device. Your saved content is '
    'unchanged.',
  ),
  cancelled('The update was stopped.'),
  unexpected('Updating scripture failed. Your saved content is unchanged.');

  const SyncFailureKind(this.message);

  final String message;

  SyncStatus get status => switch (this) {
    offline => SyncStatus.offline,
    unauthenticated => SyncStatus.unauthenticated,
    membershipUnavailable => SyncStatus.membershipUnavailable,
    serviceUnavailable ||
    invalidRemoteData ||
    localDatabase ||
    cancelled ||
    unexpected => SyncStatus.failed,
  };
}

class SyncException implements Exception {
  const SyncException(this.kind, [this.detail]);

  final SyncFailureKind kind;

  /// Developer diagnostics (never shown to users, never contains tokens).
  final String? detail;

  @override
  String toString() =>
      'SyncException(${kind.name}${detail == null ? '' : ': $detail'})';
}

/// The four synchronized tables, in dependency (apply) order.
enum SyncTable { chapters, contentSources, shlokas, attributions }

/// What one run did to one table.
class TableSyncCounts {
  const TableSyncCounts({
    this.downloaded = 0,
    this.inserted = 0,
    this.updated = 0,
    this.softDeleted = 0,
    this.restored = 0,
    this.removed = 0,
  });

  /// Rows received (including overlap re-downloads).
  final int downloaded;

  /// New local rows.
  final int inserted;

  /// Existing rows that received a newer version (includes soft deletes and
  /// restorations).
  final int updated;

  /// Rows that became tombstones (`deleted_at` set) in this run.
  final int softDeleted;

  /// Tombstones that became live again in this run.
  final int restored;

  /// Attribution rows removed by a full-sync reconciliation.
  final int removed;

  bool get changed => inserted + updated + removed > 0;

  @override
  bool operator ==(Object other) =>
      other is TableSyncCounts &&
      other.downloaded == downloaded &&
      other.inserted == inserted &&
      other.updated == updated &&
      other.softDeleted == softDeleted &&
      other.restored == restored &&
      other.removed == removed;

  @override
  int get hashCode => Object.hash(
    downloaded,
    inserted,
    updated,
    softDeleted,
    restored,
    removed,
  );

  @override
  String toString() =>
      'TableSyncCounts(downloaded: $downloaded, inserted: $inserted, '
      'updated: $updated, softDeleted: $softDeleted, restored: $restored, '
      'removed: $removed)';
}

/// The structured outcome of one sync attempt.
class SyncResult {
  const SyncResult({
    required this.status,
    this.counts = const {},
    this.isFullSync = false,
    this.failure,
    this.finishedAt,
  });

  SyncResult.failed(SyncFailureKind kind, {DateTime? finishedAt})
    : this(status: kind.status, failure: kind, finishedAt: finishedAt);

  final SyncStatus status;
  final Map<SyncTable, TableSyncCounts> counts;

  /// No usable checkpoint existed: everything (incl. tombstones) was fetched.
  final bool isFullSync;

  /// Set when the run did not complete.
  final SyncFailureKind? failure;
  final DateTime? finishedAt;

  bool get succeeded => failure == null;

  bool get changedLocalContent => counts.values.any((c) => c.changed);

  TableSyncCounts operator [](SyncTable table) =>
      counts[table] ?? const TableSyncCounts();

  int get softDeletedTotal =>
      counts.values.fold(0, (sum, c) => sum + c.softDeleted);

  /// User-readable description of the failure, if any.
  String? get message => failure?.message;

  @override
  String toString() =>
      'SyncResult(${status.name}, full: $isFullSync, '
      'failure: ${failure?.name}, counts: $counts)';
}
