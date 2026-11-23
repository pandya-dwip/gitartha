import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/database/app_database.dart';
import 'package:gitartha/data/local/repositories/local_database_repository.dart';

import 'matchers.dart';
import 'test_database.dart';

void main() {
  late TestClock clock;
  late AppDatabase db;
  late LocalDatabaseRepository repo;
  late List<LocalShloka> verses;

  setUp(() async {
    clock = TestClock();
    db = openTestDatabase(clock: clock);
    repo = LocalDatabaseRepository(db);
    verses = await seedChapter(db, 1, verses: 4);
  });
  tearDown(() => db.close());

  group('reading progress', () {
    test('opening creates progress without marking it studied', () async {
      final id = verses.first.id;
      final progress = await repo.recordShlokaOpened(id);

      expect(progress.status, ReadingStatus.opened);
      expect(progress.firstOpenedAt, clock());
      expect(progress.lastOpenedAt, clock());
      expect(progress.studiedAt, isNull);
      expect(progress.reflectedAt, isNull);
    });

    test('reopening updates last_opened_at only', () async {
      final id = verses.first.id;
      final first = await repo.recordShlokaOpened(id);
      for (var i = 0; i < 5; i++) {
        clock.advance(const Duration(hours: 1));
        await repo.recordShlokaOpened(id);
      }
      final now = (await repo.getProgress(id))!;

      expect(now.id, first.id);
      expect(now.firstOpenedAt, first.firstOpenedAt);
      expect(
        now.lastOpenedAt,
        first.firstOpenedAt.add(const Duration(hours: 5)),
      );
      expect(now.status, ReadingStatus.opened); // still not studied
      expect(now.studiedAt, isNull);
    });

    test(
      'explicit transitions set timestamps and never move backwards',
      () async {
        final id = verses.first.id;
        await repo.recordShlokaOpened(id);
        clock.advance(const Duration(minutes: 10));
        final studied = await repo.markShloka(id, ReadingStatus.studied);
        expect(studied.status, ReadingStatus.studied);
        expect(studied.studiedAt, clock());

        clock.advance(const Duration(minutes: 10));
        final readAfter = await repo.markShloka(id, ReadingStatus.read);
        expect(readAfter.status, ReadingStatus.studied); // no downgrade

        clock.advance(const Duration(minutes: 10));
        final reflected = await repo.markShloka(id, ReadingStatus.reflected);
        expect(reflected.status, ReadingStatus.reflected);
        expect(reflected.reflectedAt, clock());
        expect(reflected.studiedAt, studied.studiedAt); // first time kept
      },
    );

    test('marking an unopened shloka creates its record', () async {
      final progress = await repo.markShloka(verses[1].id, ReadingStatus.read);
      expect(progress.status, ReadingStatus.read);
      expect(progress.firstOpenedAt, clock());
      expect(progress.studiedAt, isNull);
    });

    test('opened is not a status you can set explicitly', () {
      expect(
        () => db.readingProgressDao.updateStatus(
          verses.first.id,
          ReadingStatus.opened,
        ),
        throwsArgumentError,
      );
    });

    test('one record per shloka, valid statuses only', () async {
      final id = verses.first.id;
      await repo.recordShlokaOpened(id);
      ReadingProgressCompanion row(String rowId) =>
          ReadingProgressCompanion.insert(
            id: rowId,
            shlokaId: id,
            status: ReadingStatus.opened,
            firstOpenedAt: clock(),
            lastOpenedAt: clock(),
            updatedAt: clock(),
          );
      await expectLater(
        db.into(db.readingProgress).insert(row(testUuid(5))),
        throwsUniqueError,
      );
      await expectLater(
        db.customStatement("UPDATE reading_progress SET status = 'bookmarked'"),
        throwsCheckError,
      );
    });

    test(
      'chapter summaries count cumulative levels over live verses',
      () async {
        await repo.recordShlokaOpened(verses[0].id);
        await repo.markShloka(verses[1].id, ReadingStatus.read);
        await repo.markShloka(verses[2].id, ReadingStatus.studied);
        await repo.markShloka(verses[3].id, ReadingStatus.reflected);
        await db.chapterDao.upsertChapter(chapterFixture(2));
        await db.shlokaDao.upsertShloka(shlokaFixture(2, 1));

        final summaries = await repo.getChapterProgressSummaries();
        expect(summaries, hasLength(2));
        final ch1 = summaries.first;
        expect(
          [
            ch1.chapterId,
            ch1.totalShlokas,
            ch1.opened,
            ch1.read,
            ch1.studied,
            ch1.reflected,
          ],
          [1, 4, 4, 3, 2, 1],
        );
        final ch2 = summaries.last;
        expect([ch2.chapterId, ch2.totalShlokas, ch2.opened], [2, 1, 0]);

        expect(await repo.getAllProgress(), hasLength(4));
      },
    );
  });

  group('reading history', () {
    test('keeps every activity, in chronological order', () async {
      final id = verses.first.id;
      await repo.recordShlokaOpened(id);
      clock.advance(const Duration(minutes: 2));
      await repo.markShloka(id, ReadingStatus.read);
      clock.advance(const Duration(minutes: 2));
      await repo.recordShlokaOpened(id);
      clock.advance(const Duration(minutes: 2));
      await repo.markShloka(id, ReadingStatus.studied);

      final history = await repo.getHistoryForShloka(id);
      expect(history.map((h) => h.action), [
        ReadingActivity.opened,
        ReadingActivity.markedRead,
        ReadingActivity.opened,
        ReadingActivity.markedStudied,
      ]);
      expect(
        history.map((h) => h.occurredAt),
        orderedEquals([...history.map((h) => h.occurredAt)]..sort()),
      );

      final recent = await repo.getRecentHistory(limit: 2);
      expect(recent.map((h) => h.action), [
        ReadingActivity.markedStudied,
        ReadingActivity.opened,
      ]);
    });

    test('rapid repeated openings are logged once', () async {
      final id = verses.first.id;
      await repo.recordShlokaOpened(id);
      clock.advance(const Duration(seconds: 5));
      await repo.recordShlokaOpened(id);
      clock.advance(const Duration(seconds: 5));
      await repo.recordShlokaOpened(id);

      expect(await repo.getHistoryForShloka(id), hasLength(1));
      // Progress still tracks the latest opening.
      expect(
        (await repo.getProgress(id))!.lastOpenedAt,
        DateTime.utc(2026, 1, 1, 9, 0, 10),
      );

      clock.advance(LocalDatabaseRepository.openedHistoryDedupWindow);
      await repo.recordShlokaOpened(id);
      expect(await repo.getHistoryForShloka(id), hasLength(2));
    });

    test('can be queried by date range', () async {
      final day1 = clock();
      await repo.recordShlokaOpened(verses[0].id);
      clock.advance(const Duration(days: 1));
      await repo.recordShlokaOpened(verses[1].id);
      clock.advance(const Duration(days: 1));
      await repo.recordShlokaOpened(verses[2].id);

      final middle = await repo.getHistoryBetween(
        day1.add(const Duration(hours: 1)),
        day1.add(const Duration(days: 2)),
      );
      expect(middle.map((h) => h.shlokaId), [verses[1].id]);
    });

    test('rejects unknown actions', () async {
      await repo.recordShlokaOpened(verses.first.id);
      await expectLater(
        db.customStatement("UPDATE reading_history SET action = 'bookmarked'"),
        throwsCheckError,
      );
    });
  });
}
