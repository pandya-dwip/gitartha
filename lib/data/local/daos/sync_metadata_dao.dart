import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/sync_metadata.dart';

part 'sync_metadata_dao.g.dart';

/// Keys used by content sync (lib/features/synchronization). Values never
/// contain credentials or tokens.
abstract final class SyncMetadataKeys {
  /// UTC timestamp of the last fully successful content sync (device clock,
  /// for display only).
  static const String lastSuccessfulContentSyncAt =
      'last_successful_content_sync_at';

  /// Last known sync state: `syncing`, `success` or `failed`.
  static const String contentSyncState = 'content_sync_state';

  /// UTC timestamp (device clock) of the last sync attempt.
  static const String lastContentSyncAttemptAt = 'last_content_sync_attempt_at';

  /// `SyncFailureKind` name of the last failed attempt; removed on success.
  static const String lastContentSyncError = 'last_content_sync_error';

  /// Sync protocol version that wrote the cursors. A different version
  /// invalidates them and forces a full sync.
  static const String contentSyncProtocol = 'content_sync_protocol';

  /// Per-table cursor: `content_cursor.<remote table>`. The value is the
  /// newest server `updated_at` (`created_at` for attributions) applied, as
  /// fixed-width UTC text (see docs/database/SYNC_STRATEGY.md).
  static String contentCursor(String table) => 'content_cursor.$table';
}

/// Plain key/value storage for sync bookkeeping.
@DriftAccessor(tables: [SyncMetadata])
class SyncMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.attachedDatabase);

  Future<String?> getValue(String key) async => (await (select(
    syncMetadata,
  )..where((m) => m.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setValue(String key, String value) =>
      into(syncMetadata).insertOnConflictUpdate(
        SyncMetadataCompanion.insert(
          key: key,
          value: value,
          updatedAt: attachedDatabase.now(),
        ),
      );

  Future<bool> deleteValue(String key) async =>
      await (delete(syncMetadata)..where((m) => m.key.equals(key))).go() > 0;

  Future<List<SyncMetadataEntry>> getAll() => select(syncMetadata).get();
}
