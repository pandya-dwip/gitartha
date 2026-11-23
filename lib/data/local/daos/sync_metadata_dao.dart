import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/sync_metadata.dart';

part 'sync_metadata_dao.g.dart';

/// Keys reserved for the future content-sync milestone.
abstract final class SyncMetadataKeys {
  /// UTC timestamp of the last fully successful content sync (device clock,
  /// for display only).
  static const String lastSuccessfulContentSyncAt =
      'last_successful_content_sync_at';

  /// Last known sync state, e.g. `idle`, `failed`.
  static const String contentSyncState = 'content_sync_state';

  /// Per-table cursor prefix: `content_cursor.<table>`. The value is the
  /// server's `updated_at` and id of the last applied row (see
  /// docs/database/SYNC_STRATEGY.md).
  static String contentCursor(String table) => 'content_cursor.$table';
}

/// Plain key/value storage for sync bookkeeping. This milestone has no sync
/// logic; this only provides storage for it.
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
