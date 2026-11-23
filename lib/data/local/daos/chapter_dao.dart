import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/tables/local_chapters.dart';

part 'chapter_dao.g.dart';

/// Reads and caches chapters.
///
/// Reading queries hide soft-deleted chapters. Cache writes keep Supabase's
/// ids and timestamps and never replace a newer cached row with an older one.
@DriftAccessor(tables: [LocalChapters])
class ChapterDao extends DatabaseAccessor<AppDatabase> with _$ChapterDaoMixin {
  ChapterDao(super.attachedDatabase);

  SimpleSelectStatement<$LocalChaptersTable, LocalChapter> _liveChapters() =>
      select(localChapters)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.id)]);

  /// All chapters that have not been soft-deleted, in chapter order.
  Future<List<LocalChapter>> getChapters() => _liveChapters().get();

  /// Emits [getChapters] again whenever the chapters change.
  Stream<List<LocalChapter>> watchChapters() => _liveChapters().watch();

  /// The chapter with [id], or null. Soft-deleted chapters are returned only
  /// with [includeDeleted].
  Future<LocalChapter?> getChapter(int id, {bool includeDeleted = false}) {
    final query = select(localChapters)..where((c) => c.id.equals(id));
    if (!includeDeleted) query.where((c) => c.deletedAt.isNull());
    return query.getSingleOrNull();
  }

  /// Inserts [chapter], or updates the cached row if [chapter] is at least as
  /// new (`updated_at`). An older version never overwrites a newer one.
  Future<void> upsertChapter(LocalChapter chapter) => into(
    localChapters,
  ).insert(chapter, onConflict: _updateIfNotOlder(chapter));

  /// [upsertChapter] for many chapters, all or nothing.
  Future<void> upsertChapters(Iterable<LocalChapter> chapters) => batch((b) {
    for (final chapter in chapters) {
      b.insert(localChapters, chapter, onConflict: _updateIfNotOlder(chapter));
    }
  });

  /// Applies a server tombstone: the chapter stays cached, hidden from reading
  /// queries. Returns false if no such chapter is cached.
  Future<bool> markChapterDeleted(
    int id, {
    required DateTime deletedAt,
    required DateTime updatedAt,
  }) async {
    final count = await (update(localChapters)..where((c) => c.id.equals(id)))
        .write(
          LocalChaptersCompanion(
            deletedAt: Value(deletedAt),
            updatedAt: Value(updatedAt),
          ),
        );
    return count > 0;
  }

  DoUpdate<$LocalChaptersTable, LocalChapter> _updateIfNotOlder(
    LocalChapter chapter,
  ) => DoUpdate(
    (_) => chapter.toCompanion(false).copyWith(id: const Value.absent()),
    where: (old) => old.updatedAt.isSmallerOrEqualValue(
      formatUtcTimestamp(chapter.updatedAt),
    ),
  );
}
