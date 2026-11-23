import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/tables/reading_history.dart';

part 'reading_history_dao.g.dart';

/// Append-only reading activity log. Rows are inserted, read and (in a
/// future retention policy) pruned, but never updated.
///
/// Callers decide what counts as an activity. Record one when the user
/// actually opens or marks a shloka, never from a widget's `build`. The
/// repository also de-duplicates rapid repeated openings.
@DriftAccessor(tables: [ReadingHistory])
class ReadingHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingHistoryDaoMixin {
  ReadingHistoryDao(super.attachedDatabase);

  /// Appends an activity. [occurredAt] defaults to now.
  Future<ReadingHistoryEntry> recordActivity(
    String shlokaId,
    ReadingActivity action, {
    DateTime? occurredAt,
  }) => into(readingHistory).insertReturning(
    ReadingHistoryCompanion.insert(
      id: attachedDatabase.newId(),
      shlokaId: shlokaId,
      action: action,
      occurredAt: occurredAt ?? attachedDatabase.now(),
    ),
  );

  /// The most recent activities across all shlokas, newest first.
  Future<List<ReadingHistoryEntry>> getRecentHistory({int limit = 50}) =>
      (select(readingHistory)
            ..orderBy(_newestFirst)
            ..limit(limit))
          .get();

  /// All activities for [shlokaId], oldest first.
  Future<List<ReadingHistoryEntry>> getHistoryForShloka(String shlokaId) =>
      (select(readingHistory)
            ..where((h) => h.shlokaId.equals(shlokaId))
            ..orderBy(_oldestFirst))
          .get();

  /// Activities with `from <= occurred_at < to`, oldest first.
  Future<List<ReadingHistoryEntry>> getHistoryBetween(
    DateTime from,
    DateTime to,
  ) =>
      (select(readingHistory)
            ..where(
              (h) =>
                  h.occurredAt.isBiggerOrEqualValue(formatUtcTimestamp(from)) &
                  h.occurredAt.isSmallerThanValue(formatUtcTimestamp(to)),
            )
            ..orderBy(_oldestFirst))
          .get();

  /// The latest [action] recorded for [shlokaId], or null.
  Future<ReadingHistoryEntry?> getLatestActivity(
    String shlokaId,
    ReadingActivity action,
  ) =>
      (select(readingHistory)
            ..where(
              (h) =>
                  h.shlokaId.equals(shlokaId) &
                  h.action.equals(action.sqlValue),
            )
            ..orderBy(_newestFirst)
            ..limit(1))
          .getSingleOrNull();

  static final List<OrderingTerm Function($ReadingHistoryTable)> _oldestFirst =
      [(h) => OrderingTerm.asc(h.occurredAt), (h) => OrderingTerm.asc(h.rowId)];

  static final List<OrderingTerm Function($ReadingHistoryTable)> _newestFirst =
      [
        (h) => OrderingTerm.desc(h.occurredAt),
        (h) => OrderingTerm.desc(h.rowId),
      ];
}
