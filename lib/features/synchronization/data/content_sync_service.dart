import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../data/local/daos/sync_metadata_dao.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/database/converters.dart';
import '../domain/sync_result.dart';
import 'content_remote_datasource.dart';
import 'remote_row_mapper.dart';

/// Tunables, in one place.
class SyncConfig {
  const SyncConfig({
    this.pageSize = 500,
    this.overlap = const Duration(minutes: 10),
    this.autoSyncMinInterval = const Duration(minutes: 30),
  });

  /// Rows per request. Must not exceed the project's PostgREST "Max rows"
  /// (Supabase default 1000); pagination stops only on an empty page, so a
  /// lower server cap is still read completely.
  final int pageSize;

  /// Each incremental run re-reads from `checkpoint − overlap`: a row whose
  /// transaction started before the checkpoint but committed after it (so
  /// its `updated_at` is older than rows already seen) is still picked up.
  /// Re-reading is harmless (idempotent upserts).
  final Duration overlap;

  /// Automatic triggers (startup, sign-in, resume) skip a run when the last
  /// successful sync is newer than this. Manual sync ignores it.
  final Duration autoSyncMinInterval;
}

/// What is persisted about past runs (no credentials, ever).
class SyncMetadataSnapshot {
  const SyncMetadataSnapshot({
    this.lastSuccessfulAt,
    this.lastAttemptAt,
    this.state,
    this.lastError,
  });

  final DateTime? lastSuccessfulAt;
  final DateTime? lastAttemptAt;

  /// `syncing`, `success` or `failed`. `syncing` with nothing running means
  /// the app was closed mid-run; the next run simply starts again.
  final String? state;

  /// [SyncFailureKind] name of the last failure.
  final String? lastError;

  bool get neverSynced => lastSuccessfulAt == null;
}

/// Pulls shared scripture (chapters, sources, shlokas, attributions) from
/// Supabase into the local Drift cache.
///
/// Guarantees:
///  * **Read-only towards Supabase**; never touches personal tables.
///  * **Staged, then one transaction:** all pages of all tables are
///    downloaded first (no transaction is open during network calls), then
///    applied together with the new checkpoint in a single Drift
///    transaction. Any failure leaves the previous content and checkpoint.
///  * **Idempotent:** upserts keep server ids and never go backwards
///    (`updated_at`), so overlap re-downloads and retries change nothing.
///  * **Tombstones are updates:** `deleted_at` is copied; rows are never
///    physically deleted, so personal records that reference them survive.
///  * **Single flight:** concurrent calls share the running sync.
class ContentSyncService {
  ContentSyncService({
    required AppDatabase database,
    required ContentRemoteDataSource remote,
    this.config = const SyncConfig(),
  }) : _db = database,
       _remote = remote;

  final AppDatabase _db;
  final ContentRemoteDataSource _remote;
  final SyncConfig config;

  /// Bump when the cursor format or sync semantics change: stored
  /// checkpoints with another version are ignored and a full sync runs.
  static const protocolVersion = '1';

  static const _stateSyncing = 'syncing';
  static const _stateSuccess = 'success';
  static const _stateFailed = 'failed';

  Future<SyncResult>? _inFlight;

  bool get isRunning => _inFlight != null;

  /// Runs one sync, or joins the one already running. [isCancelled] is
  /// polled between pages and before applying (e.g. the user signed out);
  /// a cancelled run applies nothing.
  Future<SyncResult> sync({bool Function()? isCancelled}) => _inFlight ??= _run(
    isCancelled ?? () => false,
  ).whenComplete(() => _inFlight = null);

  Future<SyncMetadataSnapshot> readMetadata() async {
    final meta = _db.syncMetadataDao;
    DateTime? ts(String? v) => v == null ? null : DateTime.tryParse(v);
    return SyncMetadataSnapshot(
      lastSuccessfulAt: ts(
        await meta.getValue(SyncMetadataKeys.lastSuccessfulContentSyncAt),
      ),
      lastAttemptAt: ts(
        await meta.getValue(SyncMetadataKeys.lastContentSyncAttemptAt),
      ),
      state: await meta.getValue(SyncMetadataKeys.contentSyncState),
      lastError: await meta.getValue(SyncMetadataKeys.lastContentSyncError),
    );
  }

  Future<SyncResult> _run(bool Function() isCancelled) async {
    try {
      await _local(() async {
        await _setMeta(SyncMetadataKeys.contentSyncState, _stateSyncing);
        await _setMeta(
          SyncMetadataKeys.lastContentSyncAttemptAt,
          formatUtcTimestamp(_db.now()),
        );
      });
      final cursors = await _local(_readCursors);
      final isFull = cursors == null;

      // 1. Download everything needed, in dependency order (staging).
      final rows = <SyncTable, List<Map<String, dynamic>>>{};
      for (final table in SyncTable.values) {
        rows[table] = await _fetchAll(
          table,
          since: isFull ? null : _lowerBound(cursors[table]),
          isCancelled: isCancelled,
        );
      }
      if (isCancelled()) throw const SyncException(SyncFailureKind.cancelled);

      // 2. Parse strictly before touching SQLite.
      final batch = _Batch(
        chapters: rows[SyncTable.chapters]!
            .map(RemoteRowMapper.chapter)
            .toList(),
        sources: rows[SyncTable.contentSources]!
            .map(RemoteRowMapper.source)
            .toList(),
        shlokas: rows[SyncTable.shlokas]!.map(RemoteRowMapper.shloka).toList(),
        attributions: rows[SyncTable.attributions]!
            .map(RemoteRowMapper.attribution)
            .toList(),
      );
      final newCursors = {
        for (final table in SyncTable.values)
          table: _advance(cursors?[table], table, rows[table]!),
      };

      // 3. Apply + checkpoint, all or nothing.
      final counts = await _local(
        () => _db.transaction(() async {
          final result = {
            SyncTable.chapters: await _applyChapters(batch.chapters),
            SyncTable.contentSources: await _applySources(batch.sources),
            SyncTable.shlokas: await _applyShlokas(batch.shlokas),
            SyncTable.attributions: await _applyAttributions(
              batch.attributions,
              reconcileShlokaIds: isFull
                  ? {for (final s in batch.shlokas) s.id}
                  : null,
            ),
          };
          await _writeCheckpoint(newCursors);
          return result;
        }),
      );

      final changed = counts.values.any((c) => c.changed);
      return SyncResult(
        status: changed ? SyncStatus.success : SyncStatus.noChanges,
        counts: counts,
        isFullSync: isFull,
        finishedAt: _db.now(),
      );
    } on SyncException catch (e) {
      debugPrint('Content sync failed: $e');
      await _recordFailure(e.kind);
      return SyncResult.failed(e.kind, finishedAt: _db.now());
    } on Object catch (e, stack) {
      // A bug, not an expected condition: report it loudly, but keep the
      // app (and the previous cache and checkpoint) intact.
      debugPrint('Content sync crashed (${e.runtimeType}).\n$stack');
      await _recordFailure(SyncFailureKind.unexpected);
      return SyncResult.failed(
        SyncFailureKind.unexpected,
        finishedAt: _db.now(),
      );
    }
  }

  /// All pages of [table]. Stops on an empty page (not a short one), so a
  /// server-side row cap below [SyncConfig.pageSize] cannot truncate it.
  Future<List<Map<String, dynamic>>> _fetchAll(
    SyncTable table, {
    required String? since,
    required bool Function() isCancelled,
  }) async {
    final all = <Map<String, dynamic>>[];
    PageCursor? after;
    while (true) {
      if (isCancelled()) throw const SyncException(SyncFailureKind.cancelled);
      final List<Map<String, dynamic>> page;
      try {
        page = await _remote.fetchPage(
          table,
          since: since,
          after: after,
          limit: config.pageSize,
        );
      } on SyncException {
        rethrow;
      } on Object catch (e) {
        throw SyncException(
          SyncFailureKind.serviceUnavailable,
          '${table.name}: ${e.runtimeType}',
        );
      }
      if (page.isEmpty) return all;
      all.addAll(page);
      final last = page.last;
      final ts = last[table.timestampColumn];
      final id = last['id'];
      if (ts is! String || id == null) {
        throw SyncException(
          SyncFailureKind.invalidRemoteData,
          '${table.name}: row without ${table.timestampColumn}/id',
        );
      }
      try {
        after = (timestamp: normalizeRemoteTimestamp(ts), id: id);
      } on FormatException {
        throw SyncException(
          SyncFailureKind.invalidRemoteData,
          '${table.name}: bad ${table.timestampColumn}',
        );
      }
    }
  }

  // --- checkpoints ---------------------------------------------------------

  /// Per-table cursors, or null when a full sync is required (never synced,
  /// or a checkpoint written by another protocol version).
  Future<Map<SyncTable, String?>?> _readCursors() async {
    final meta = _db.syncMetadataDao;
    final version = await meta.getValue(SyncMetadataKeys.contentSyncProtocol);
    final lastSuccess = await meta.getValue(
      SyncMetadataKeys.lastSuccessfulContentSyncAt,
    );
    if (version != protocolVersion || lastSuccess == null) return null;
    return {
      for (final table in SyncTable.values)
        table: await meta.getValue(
          SyncMetadataKeys.contentCursor(table.remoteName),
        ),
    };
  }

  String? _lowerBound(String? cursor) => cursor == null
      ? null
      : formatUtcTimestamp(DateTime.parse(cursor).subtract(config.overlap));

  /// The newest server timestamp seen for [table] (never moves backwards).
  /// Server time, not the device clock: device clocks can be wrong.
  String? _advance(
    String? previous,
    SyncTable table,
    List<Map<String, dynamic>> rows,
  ) {
    var newest = previous;
    for (final row in rows) {
      final ts = normalizeRemoteTimestamp(row[table.timestampColumn] as String);
      // Fixed-width UTC strings: text order is chronological order.
      if (newest == null || ts.compareTo(newest) > 0) newest = ts;
    }
    return newest;
  }

  Future<void> _writeCheckpoint(Map<SyncTable, String?> cursors) async {
    for (final MapEntry(key: table, value: cursor) in cursors.entries) {
      if (cursor != null) {
        await _setMeta(
          SyncMetadataKeys.contentCursor(table.remoteName),
          cursor,
        );
      }
    }
    await _setMeta(SyncMetadataKeys.contentSyncProtocol, protocolVersion);
    await _setMeta(
      SyncMetadataKeys.lastSuccessfulContentSyncAt,
      formatUtcTimestamp(_db.now()),
    );
    await _setMeta(SyncMetadataKeys.contentSyncState, _stateSuccess);
    await _db.syncMetadataDao.deleteValue(
      SyncMetadataKeys.lastContentSyncError,
    );
  }

  Future<void> _recordFailure(SyncFailureKind kind) async {
    try {
      await _setMeta(SyncMetadataKeys.contentSyncState, _stateFailed);
      await _setMeta(SyncMetadataKeys.lastContentSyncError, kind.name);
    } on Object catch (e) {
      // The result still reports the failure; only the diagnostic is lost.
      debugPrint('Could not record sync failure (${e.runtimeType}).');
    }
  }

  Future<void> _setMeta(String key, String value) =>
      _db.syncMetadataDao.setValue(key, value);

  /// Runs a local database step; any failure becomes `localDatabase`.
  Future<T> _local<T>(Future<T> Function() step) async {
    try {
      return await step();
    } on SyncException {
      rethrow;
    } on Object catch (e) {
      throw SyncException(SyncFailureKind.localDatabase, '${e.runtimeType}');
    }
  }

  // --- applying ------------------------------------------------------------

  Future<TableSyncCounts> _applyChapters(List<LocalChapter> rows) async {
    final existing = <Object, _Version>{};
    for (final chunk in _chunks(rows.map((r) => r.id).toList())) {
      for (final c in await (_db.select(
        _db.localChapters,
      )..where((t) => t.id.isIn(chunk))).get()) {
        existing[c.id] = (updatedAt: c.updatedAt, deletedAt: c.deletedAt);
      }
    }
    final counts = _classify(
      rows,
      existing,
      (r) => r.id,
      (r) => (updatedAt: r.updatedAt, deletedAt: r.deletedAt),
    );
    await _db.chapterDao.upsertChapters(rows);
    return counts;
  }

  Future<TableSyncCounts> _applySources(List<LocalContentSource> rows) async {
    final existing = <Object, _Version>{};
    for (final chunk in _chunks(rows.map((r) => r.id).toList())) {
      for (final s in await (_db.select(
        _db.localContentSources,
      )..where((t) => t.id.isIn(chunk))).get()) {
        existing[s.id] = (updatedAt: s.updatedAt, deletedAt: s.deletedAt);
      }
    }
    final counts = _classify(
      rows,
      existing,
      (r) => r.id,
      (r) => (updatedAt: r.updatedAt, deletedAt: r.deletedAt),
    );
    for (final row in rows) {
      await _db.contentSourceDao.upsertSource(row);
    }
    return counts;
  }

  Future<TableSyncCounts> _applyShlokas(List<LocalShloka> rows) async {
    final existing = <Object, _Version>{};
    for (final chunk in _chunks(rows.map((r) => r.id).toList())) {
      for (final s in await (_db.select(
        _db.localShlokas,
      )..where((t) => t.id.isIn(chunk))).get()) {
        existing[s.id] = (updatedAt: s.updatedAt, deletedAt: s.deletedAt);
      }
    }
    final counts = _classify(
      rows,
      existing,
      (r) => r.id,
      (r) => (updatedAt: r.updatedAt, deletedAt: r.deletedAt),
    );

    // (chapter, verse) is unique locally. If the server moved a verse into a
    // slot that a different cached row still holds, park that row on a
    // unique out-of-range slot (and hide it) so the server's row can land.
    // The parked row keeps its id, so personal records stay attached; its
    // own update, if any, moves it to its real slot.
    for (final row in rows) {
      final local = existing[row.id];
      if (local != null && local.updatedAt.isAfter(row.updatedAt)) continue;
      final holder = await _db.shlokaDao.getShlokaByVerse(
        row.chapterId,
        row.verseNumber,
        includeDeleted: true,
      );
      if (holder != null && holder.id != row.id) {
        await _db.customStatement(
          'UPDATE local_shlokas '
          'SET verse_number = 1000000 + rowid, '
          "reference = chapter_id || '.' || (1000000 + rowid), "
          'deleted_at = COALESCE(deleted_at, ?) '
          'WHERE id = ?',
          [formatUtcTimestamp(_db.now()), holder.id],
        );
      }
    }
    await _db.shlokaDao.upsertShlokas(rows);
    return counts;
  }

  /// Attributions are immutable and have no tombstones: new ones are
  /// inserted (existing ids ignored). Physical deletions on the server are
  /// only visible to a full sync, which then removes local attributions of
  /// server shlokas that the server no longer has ([reconcileShlokaIds]).
  Future<TableSyncCounts> _applyAttributions(
    List<LocalShlokaSourceAttribution> rows, {
    required Set<String>? reconcileShlokaIds,
  }) async {
    final table = _db.localShlokaSourceAttributions;
    Future<int> count() async {
      final n = table.id.count();
      return (await (_db.selectOnly(
        table,
      )..addColumns([n])).getSingle()).read(n)!;
    }

    final before = await count();
    for (final row in rows) {
      // insertOrIgnore: same id, or same (shloka, source, section) under
      // another id, is already present. Foreign keys are still enforced.
      await _db.into(table).insert(row, mode: InsertMode.insertOrIgnore);
    }
    final inserted = await count() - before;

    var removed = 0;
    if (reconcileShlokaIds != null && reconcileShlokaIds.isNotEmpty) {
      final remoteIds = {for (final r in rows) r.id};
      final stale = [
        for (final a in await _db.select(table).get())
          if (reconcileShlokaIds.contains(a.shlokaId) &&
              !remoteIds.contains(a.id))
            a.id,
      ];
      for (final chunk in _chunks(stale)) {
        removed += await (_db.delete(
          table,
        )..where((t) => t.id.isIn(chunk))).go();
      }
    }
    return TableSyncCounts(
      downloaded: rows.length,
      inserted: inserted,
      removed: removed,
    );
  }

  static TableSyncCounts _classify<T>(
    List<T> rows,
    Map<Object, _Version> existing,
    Object Function(T) idOf,
    _Version Function(T) versionOf,
  ) {
    var inserted = 0, updated = 0, softDeleted = 0, restored = 0;
    for (final row in rows) {
      final incoming = versionOf(row);
      final local = existing[idOf(row)];
      if (local == null) {
        inserted++;
        if (incoming.deletedAt != null) softDeleted++;
      } else if (incoming.updatedAt.isAfter(local.updatedAt)) {
        updated++;
        if (incoming.deletedAt != null && local.deletedAt == null) {
          softDeleted++;
        }
        if (incoming.deletedAt == null && local.deletedAt != null) restored++;
      }
      // Equal or older: unchanged (the DAO guard never goes backwards).
    }
    return TableSyncCounts(
      downloaded: rows.length,
      inserted: inserted,
      updated: updated,
      softDeleted: softDeleted,
      restored: restored,
    );
  }

  /// Keeps `IN (...)` lists well below SQLite's variable limit.
  static Iterable<List<T>> _chunks<T>(List<T> items, [int size = 500]) sync* {
    for (var i = 0; i < items.length; i += size) {
      yield items.sublist(i, i + size > items.length ? items.length : i + size);
    }
  }
}

typedef _Version = ({DateTime updatedAt, DateTime? deletedAt});

class _Batch {
  const _Batch({
    required this.chapters,
    required this.sources,
    required this.shlokas,
    required this.attributions,
  });

  final List<LocalChapter> chapters;
  final List<LocalContentSource> sources;
  final List<LocalShloka> shlokas;
  final List<LocalShlokaSourceAttribution> attributions;
}
