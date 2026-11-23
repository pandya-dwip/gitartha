import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/tables/local_content_sources.dart';
import '../database/tables/local_shloka_source_attributions.dart';

part 'content_source_dao.g.dart';

/// Cached content sources and verse attributions (shared content).
@DriftAccessor(tables: [LocalContentSources, LocalShlokaSourceAttributions])
class ContentSourceDao extends DatabaseAccessor<AppDatabase>
    with _$ContentSourceDaoMixin {
  ContentSourceDao(super.attachedDatabase);

  /// Live (not soft-deleted) sources, by name.
  Future<List<LocalContentSource>> getSources() =>
      (select(localContentSources)
            ..where((s) => s.deletedAt.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .get();

  Future<LocalContentSource?> getSource(String id) => (select(
    localContentSources,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Inserts [source], or updates the cached row if [source] is at least as
  /// new (`updated_at`).
  Future<void> upsertSource(LocalContentSource source) =>
      into(localContentSources).insert(
        source,
        onConflict: DoUpdate(
          (_) => source.toCompanion(false).copyWith(id: const Value.absent()),
          where: (old) => old.updatedAt.isSmallerOrEqualValue(
            formatUtcTimestamp(source.updatedAt),
          ),
        ),
      );

  /// The attributions of [shlokaId], ordered by section and source.
  Future<List<LocalShlokaSourceAttribution>> getAttributionsForShloka(
    String shlokaId,
  ) =>
      (select(localShlokaSourceAttributions)
            ..where((a) => a.shlokaId.equals(shlokaId))
            ..orderBy([
              (a) => OrderingTerm.asc(a.contentSection),
              (a) => OrderingTerm.asc(a.sourceId),
            ]))
          .get();

  /// Makes the attributions of [shlokaId] exactly [desired]: inserts the
  /// missing ones, deletes the ones not in [desired], and leaves matching
  /// rows untouched. Run it inside a transaction.
  Future<({int inserted, int deleted})> replaceAttributionsForShloka(
    String shlokaId,
    List<LocalShlokaSourceAttribution> desired,
  ) async {
    final existing = await getAttributionsForShloka(shlokaId);
    final existingIds = {for (final a in existing) a.id};
    final desiredIds = {for (final a in desired) a.id};

    var deleted = 0;
    final stale = existingIds.difference(desiredIds);
    if (stale.isNotEmpty) {
      deleted = await (delete(
        localShlokaSourceAttributions,
      )..where((a) => a.id.isIn(stale))).go();
    }
    var inserted = 0;
    for (final attribution in desired) {
      if (existingIds.contains(attribution.id)) continue;
      await into(localShlokaSourceAttributions).insert(attribution);
      inserted++;
    }
    return (inserted: inserted, deleted: deleted);
  }
}
