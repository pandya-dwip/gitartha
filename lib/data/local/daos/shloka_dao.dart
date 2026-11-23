import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../database/tables/local_chapters.dart';
import '../database/tables/local_shlokas.dart';
import 'like_pattern.dart';

part 'shloka_dao.g.dart';

/// Reads, searches and caches shlokas.
///
/// Reading queries return only live content: the shloka is not soft-deleted
/// **and** its chapter is not soft-deleted. Lookups by id can include deleted
/// shlokas, because personal records may still point at them.
@DriftAccessor(tables: [LocalShlokas, LocalChapters])
class ShlokaDao extends DatabaseAccessor<AppDatabase> with _$ShlokaDaoMixin {
  ShlokaDao(super.attachedDatabase);

  Expression<bool> _isLive($LocalShlokasTable s) =>
      s.deletedAt.isNull() &
      s.chapterId.isInQuery(
        selectOnly(localChapters)
          ..addColumns([localChapters.id])
          ..where(localChapters.deletedAt.isNull()),
      );

  SimpleSelectStatement<$LocalShlokasTable, LocalShloka> _liveForChapter(
    int chapterId,
  ) => select(localShlokas)
    ..where((s) => s.chapterId.equals(chapterId) & _isLive(s))
    ..orderBy([(s) => OrderingTerm.asc(s.verseNumber)]);

  /// Live shlokas of [chapterId], in verse order.
  Future<List<LocalShloka>> getShlokasForChapter(int chapterId) =>
      _liveForChapter(chapterId).get();

  /// Emits [getShlokasForChapter] again whenever the shlokas change.
  Stream<List<LocalShloka>> watchShlokasForChapter(int chapterId) =>
      _liveForChapter(chapterId).watch();

  /// The shloka with the Supabase UUID [id], or null. Soft-deleted shlokas
  /// are returned only with [includeDeleted], for example to show the verse
  /// behind an old reflection.
  Future<LocalShloka?> getShloka(String id, {bool includeDeleted = false}) {
    final query = select(localShlokas)..where((s) => s.id.equals(id));
    if (!includeDeleted) query.where(_isLive);
    return query.getSingleOrNull();
  }

  /// The live shloka at [chapterId].[verseNumber], or null.
  Future<LocalShloka?> getShlokaByVerse(int chapterId, int verseNumber) =>
      (select(localShlokas)..where(
            (s) =>
                s.chapterId.equals(chapterId) &
                s.verseNumber.equals(verseNumber) &
                _isLive(s),
          ))
          .getSingleOrNull();

  /// Live shlokas whose reference (exact, e.g. `2.47`), index title or text
  /// contains [query]. Results are in chapter/verse order, at most [limit].
  ///
  /// Uses `LIKE`, which is adequate for 700 verses. A full-text (FTS5) index
  /// can replace it in the search milestone without changing this signature.
  Future<List<LocalShloka>> searchShlokas(String query, {int limit = 50}) {
    final term = query.trim();
    if (term.isEmpty) return Future.value(const []);
    final pattern = containsPattern(term);

    Expression<bool> matches(GeneratedColumn<String> column) =>
        column.like(pattern, escapeChar: likeEscapeChar);

    return (select(localShlokas)
          ..where(
            (s) =>
                _isLive(s) &
                (s.reference.equals(term) |
                    matches(s.indexTitle) |
                    matches(s.indexSummary) |
                    matches(s.sanskritText) |
                    matches(s.transliteration) |
                    matches(s.hindiMeaning) |
                    matches(s.englishMeaning) |
                    matches(s.context) |
                    matches(s.lifeLesson) |
                    matches(s.spiritualMeaning)),
          )
          ..orderBy([
            (s) => OrderingTerm.asc(s.chapterId),
            (s) => OrderingTerm.asc(s.verseNumber),
          ])
          ..limit(limit))
        .get();
  }

  /// Inserts [shloka] with its Supabase UUID, or updates the cached row if
  /// [shloka] is at least as new. The id is never changed or regenerated.
  Future<void> upsertShloka(LocalShloka shloka) =>
      into(localShlokas).insert(shloka, onConflict: _updateIfNotOlder(shloka));

  /// [upsertShloka] for many shlokas, all or nothing. Chapters must be
  /// cached first (foreign key).
  Future<void> upsertShlokas(Iterable<LocalShloka> shlokas) => batch((b) {
    for (final shloka in shlokas) {
      b.insert(localShlokas, shloka, onConflict: _updateIfNotOlder(shloka));
    }
  });

  /// Applies a server tombstone. The row and every personal record that
  /// references it are kept. Returns false if no such shloka is cached.
  Future<bool> markShlokaDeleted(
    String id, {
    required DateTime deletedAt,
    required DateTime updatedAt,
  }) async {
    final count = await (update(localShlokas)..where((s) => s.id.equals(id)))
        .write(
          LocalShlokasCompanion(
            deletedAt: Value(deletedAt),
            updatedAt: Value(updatedAt),
          ),
        );
    return count > 0;
  }

  DoUpdate<$LocalShlokasTable, LocalShloka> _updateIfNotOlder(
    LocalShloka shloka,
  ) => DoUpdate(
    (_) => shloka.toCompanion(false).copyWith(id: const Value.absent()),
    where: (old) => old.updatedAt.isSmallerOrEqualValue(
      formatUtcTimestamp(shloka.updatedAt),
    ),
  );
}
