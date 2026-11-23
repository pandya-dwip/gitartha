import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/local_chapters.dart';
import '../database/tables/local_shlokas.dart';
import '../database/tables/reading_progress.dart';
import 'validation.dart';

part 'reading_progress_dao.g.dart';

/// Progress through one chapter, counted over its live shlokas.
///
/// Status levels are cumulative: a `studied` shloka also counts as `read`
/// and `opened`.
class ChapterProgressSummary {
  const ChapterProgressSummary({
    required this.chapterId,
    required this.totalShlokas,
    required this.opened,
    required this.read,
    required this.studied,
    required this.reflected,
  });

  final int chapterId;

  /// Live shlokas currently cached for the chapter.
  final int totalShlokas;
  final int opened;
  final int read;
  final int studied;
  final int reflected;

  @override
  String toString() =>
      'ChapterProgressSummary(chapter $chapterId: $opened opened, $read read, '
      '$studied studied, $reflected reflected of $totalShlokas)';
}

/// One progress record per shloka.
///
/// Transitions are explicit:
///
/// | Call                       | Effect                                       |
/// |----------------------------|----------------------------------------------|
/// | [recordOpening]            | Creates the record as `opened`, or only updates `last_opened_at`. Never changes the status |
/// | [updateStatus] `read`      | Status becomes at least `read`               |
/// | [updateStatus] `studied`   | Status becomes at least `studied`; sets `studied_at` the first time |
/// | [updateStatus] `reflected` | Status becomes `reflected`; sets `reflected_at` the first time |
///
/// The status never moves backwards. Marking a `studied` shloka as `read`
/// keeps it `studied`. `first_opened_at` never changes after creation.
@DriftAccessor(tables: [ReadingProgress, LocalShlokas, LocalChapters])
class ReadingProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingProgressDaoMixin {
  ReadingProgressDao(super.attachedDatabase);

  /// Records that [shlokaId] was opened. Does not mark it read or studied.
  Future<ReadingProgressEntry> recordOpening(String shlokaId) => transaction(
    () async {
      final now = attachedDatabase.now();
      final existing = await getProgress(shlokaId);
      if (existing == null) {
        return into(readingProgress).insertReturning(
          ReadingProgressCompanion.insert(
            id: attachedDatabase.newId(),
            shlokaId: shlokaId,
            status: ReadingStatus.opened,
            firstOpenedAt: now,
            lastOpenedAt: now,
            updatedAt: now,
          ),
        );
      }
      final at = notEarlierThan(now, existing.firstOpenedAt);
      return _write(
        existing.id,
        ReadingProgressCompanion(lastOpenedAt: Value(at), updatedAt: Value(at)),
      );
    },
  );

  /// Explicitly marks [shlokaId] as [status] (`read`, `studied` or
  /// `reflected`). Creates the record if the shloka was never opened.
  ///
  /// Throws [ArgumentError] for [ReadingStatus.opened]; use [recordOpening].
  Future<ReadingProgressEntry> updateStatus(
    String shlokaId,
    ReadingStatus status,
  ) {
    if (status == ReadingStatus.opened) {
      throw ArgumentError.value(
        status,
        'status',
        'use recordOpening() to record that a shloka was opened',
      );
    }
    return transaction(() async {
      final now = attachedDatabase.now();
      final existing =
          await getProgress(shlokaId) ?? await recordOpening(shlokaId);
      final at = notEarlierThan(now, existing.firstOpenedAt);
      final next = status.rank > existing.status.rank
          ? status
          : existing.status;
      return _write(
        existing.id,
        ReadingProgressCompanion(
          status: Value(next),
          studiedAt:
              status == ReadingStatus.studied && existing.studiedAt == null
              ? Value(at)
              : const Value.absent(),
          reflectedAt:
              status == ReadingStatus.reflected && existing.reflectedAt == null
              ? Value(at)
              : const Value.absent(),
          updatedAt: Value(at),
        ),
      );
    });
  }

  Future<ReadingProgressEntry> _write(
    String id,
    ReadingProgressCompanion changes,
  ) async {
    final rows = await (update(
      readingProgress,
    )..where((p) => p.id.equals(id))).writeReturning(changes);
    return rows.single;
  }

  Future<ReadingProgressEntry?> getProgress(String shlokaId) => (select(
    readingProgress,
  )..where((p) => p.shlokaId.equals(shlokaId))).getSingleOrNull();

  Stream<ReadingProgressEntry?> watchProgress(String shlokaId) => (select(
    readingProgress,
  )..where((p) => p.shlokaId.equals(shlokaId))).watchSingleOrNull();

  /// Every progress record, most recently opened first.
  Future<List<ReadingProgressEntry>> getAllProgress() => (select(
    readingProgress,
  )..orderBy([(p) => OrderingTerm.desc(p.lastOpenedAt)])).get();

  /// Per-chapter progress over live shlokas of live chapters, in chapter
  /// order. Chapters with no cached shlokas are omitted.
  Future<List<ChapterProgressSummary>> getChapterProgressSummaries() =>
      _summaryQuery().map(_toSummary).get();

  Stream<List<ChapterProgressSummary>> watchChapterProgressSummaries() =>
      _summaryQuery().map(_toSummary).watch();

  late final Expression<int> _total = localShlokas.id.count();
  late final Expression<int> _opened = readingProgress.id.count();
  late final Expression<int> _read = _countAtLeast(ReadingStatus.read);
  late final Expression<int> _studied = _countAtLeast(ReadingStatus.studied);
  late final Expression<int> _reflected = _countAtLeast(
    ReadingStatus.reflected,
  );

  Expression<int> _countAtLeast(ReadingStatus level) =>
      readingProgress.id.count(
        filter: readingProgress.status.isIn([
          for (final s in ReadingStatus.values)
            if (s.rank >= level.rank) s.sqlValue,
        ]),
      );

  JoinedSelectStatement<HasResultSet, dynamic> _summaryQuery() =>
      selectOnly(localShlokas).join([
          leftOuterJoin(
            readingProgress,
            readingProgress.shlokaId.equalsExp(localShlokas.id),
            useColumns: false,
          ),
        ])
        ..addColumns([
          localShlokas.chapterId,
          _total,
          _opened,
          _read,
          _studied,
          _reflected,
        ])
        ..where(
          localShlokas.deletedAt.isNull() &
              localShlokas.chapterId.isInQuery(
                selectOnly(localChapters)
                  ..addColumns([localChapters.id])
                  ..where(localChapters.deletedAt.isNull()),
              ),
        )
        ..groupBy([localShlokas.chapterId])
        ..orderBy([OrderingTerm.asc(localShlokas.chapterId)]);

  ChapterProgressSummary _toSummary(TypedResult row) => ChapterProgressSummary(
    chapterId: row.read(localShlokas.chapterId)!,
    totalShlokas: row.read(_total)!,
    opened: row.read(_opened)!,
    read: row.read(_read)!,
    studied: row.read(_studied)!,
    reflected: row.read(_reflected)!,
  );
}
