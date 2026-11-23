import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/database/app_database.dart';

import 'matchers.dart';
import 'test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  group('chapters', () {
    test('are inserted and retrieved in chapter order', () async {
      await db.chapterDao.upsertChapters([
        chapterFixture(3),
        chapterFixture(1),
        chapterFixture(2),
      ]);

      final chapters = await db.chapterDao.getChapters();
      expect(chapters.map((c) => c.id), [1, 2, 3]);

      final one = await db.chapterDao.getChapter(1);
      expect(one!.englishName, 'TEST english name 1');
      expect(one.keyTopics, ['TEST topic A', 'TEST topic B']);
      expect(one.introduction, isNull);
    });

    test('only accept ids 1 to 18', () async {
      await db.chapterDao.upsertChapter(chapterFixture(18));
      await expectLater(
        db.chapterDao.upsertChapter(chapterFixture(19)),
        throwsCheckError,
      );
      await expectLater(
        db.chapterDao.upsertChapter(chapterFixture(0)),
        throwsCheckError,
      );
    });

    test(
      'newer server versions replace the cache, older ones do not',
      () async {
        await db.chapterDao.upsertChapter(
          chapterFixture(1, updatedAt: DateTime.utc(2025, 6), overview: 'v2'),
        );
        await db.chapterDao.upsertChapter(
          chapterFixture(1, updatedAt: DateTime.utc(2025, 5), overview: 'old'),
        );
        expect((await db.chapterDao.getChapter(1))!.overview, 'v2');

        await db.chapterDao.upsertChapter(
          chapterFixture(1, updatedAt: DateTime.utc(2025, 7), overview: 'v3'),
        );
        final chapter = (await db.chapterDao.getChapter(1))!;
        expect(chapter.overview, 'v3');
        expect(chapter.updatedAt, DateTime.utc(2025, 7));
      },
    );

    test('soft-deleted chapters are hidden but kept', () async {
      await seedChapter(db, 1);
      await db.chapterDao.upsertChapter(chapterFixture(2));

      final marked = await db.chapterDao.markChapterDeleted(
        1,
        deletedAt: DateTime.utc(2025, 8),
        updatedAt: DateTime.utc(2025, 8),
      );

      expect(marked, isTrue);
      expect((await db.chapterDao.getChapters()).map((c) => c.id), [2]);
      expect(await db.chapterDao.getChapter(1), isNull);
      final tombstone = await db.chapterDao.getChapter(1, includeDeleted: true);
      expect(tombstone!.deletedAt, DateTime.utc(2025, 8));
      // Verses of a deleted chapter are not readable either.
      expect(await db.shlokaDao.getShlokasForChapter(1), isEmpty);
    });

    test('watchChapters emits on change', () async {
      final emissions = db.chapterDao.watchChapters().map(
        (list) => list.map((c) => c.id).toList(),
      );
      final expectation = expectLater(
        emissions,
        emitsInOrder([
          <int>[],
          [1],
        ]),
      );
      await pumpEventQueue();
      await db.chapterDao.upsertChapter(chapterFixture(1));
      await expectation;
    });
  });

  group('shlokas', () {
    test('keep the exact Supabase UUID and all content fields', () async {
      await db.chapterDao.upsertChapter(chapterFixture(1));
      const supabaseId = '3f2a9c1e-7b4d-4e8a-9c0b-1d2e3f4a5b6c';
      await db.shlokaDao.upsertShloka(shlokaFixture(1, 41, id: supabaseId));

      final shloka = (await db.shlokaDao.getShloka(supabaseId))!;
      expect(shloka.id, supabaseId);
      expect(shloka.reference, '1.41');
      expect(shloka.hindiMeaning, 'TEST hindi meaning');
      expect(shloka.hindiMeaningNote, 'TEST hindi wording note');
      expect(shloka.sanskritText, isNull);
    });

    test('belong to an existing chapter', () async {
      await expectLater(
        db.shlokaDao.upsertShloka(shlokaFixture(5, 1)),
        throwsForeignKeyError,
      );
    });

    test('are returned per chapter in verse order', () async {
      await seedChapter(db, 1, verses: 3);
      await db.chapterDao.upsertChapter(chapterFixture(2));
      await db.shlokaDao.upsertShlokas([
        shlokaFixture(2, 2),
        shlokaFixture(2, 1),
      ]);

      final ch2 = await db.shlokaDao.getShlokasForChapter(2);
      expect(ch2.map((s) => s.reference), ['2.1', '2.2']);
      expect(ch2.every((s) => s.chapterId == 2), isTrue);

      final verse = await db.shlokaDao.getShlokaByVerse(1, 3);
      expect(verse!.reference, '1.3');
    });

    test('chapter and verse number are unique together', () async {
      await seedChapter(db, 1, verses: 1);
      await expectLater(
        db.shlokaDao.upsertShloka(shlokaFixture(1, 1, id: testUuid(999))),
        throwsUniqueError,
      );
    });

    test('verse numbers must be positive and reference consistent', () async {
      await db.chapterDao.upsertChapter(chapterFixture(1));
      await expectLater(
        db.shlokaDao.upsertShloka(shlokaFixture(1, 0)),
        throwsCheckError,
      );
      await expectLater(
        db.shlokaDao.upsertShloka(
          shlokaFixture(1, 4).copyWith(reference: '1.5'),
        ),
        throwsCheckError,
      );
    });

    test('soft-deleted shlokas are excluded from reading queries', () async {
      final verses = await seedChapter(db, 1, verses: 3);
      final deletedId = verses[1].id;

      await db.shlokaDao.markShlokaDeleted(
        deletedId,
        deletedAt: DateTime.utc(2025, 9),
        updatedAt: DateTime.utc(2025, 9),
      );

      final live = await db.shlokaDao.getShlokasForChapter(1);
      expect(live.map((s) => s.verseNumber), [1, 3]);
      expect(await db.shlokaDao.getShlokaByVerse(1, 2), isNull);
      expect(await db.shlokaDao.getShloka(deletedId), isNull);
      expect(await db.shlokaDao.searchShlokas('1.2'), isEmpty);

      final tombstone = await db.shlokaDao.getShloka(
        deletedId,
        includeDeleted: true,
      );
      expect(tombstone!.deletedAt, DateTime.utc(2025, 9));
    });

    test('a refresh keeps ids and never touches personal data', () async {
      final verses = await seedChapter(db, 1, verses: 1);
      final id = verses.single.id;
      final reflection = await db.reflectionDao.addReflection(
        shlokaId: id,
        answer: 'My answer',
      );

      await db.shlokaDao.upsertShloka(
        shlokaFixture(
          1,
          1,
          updatedAt: DateTime.utc(2025, 10),
          englishMeaning: 'TEST revised meaning',
        ),
      );
      // A tombstone from the server, too.
      await db.shlokaDao.upsertShloka(
        shlokaFixture(
          1,
          1,
          updatedAt: DateTime.utc(2025, 11),
          deletedAt: DateTime.utc(2025, 11),
        ),
      );

      final cached = await db.select(db.localShlokas).get();
      expect(cached.single.id, id);
      expect(cached.single.deletedAt, DateTime.utc(2025, 11));
      expect(await db.reflectionDao.getReflection(reflection.id), reflection);
    });

    test('batch upserts are all-or-nothing', () async {
      await db.chapterDao.upsertChapter(chapterFixture(1));
      await expectLater(
        db.shlokaDao.upsertShlokas([
          shlokaFixture(1, 1),
          shlokaFixture(1, 2),
          shlokaFixture(7, 1), // chapter 7 is not cached
        ]),
        throwsForeignKeyError,
      );
      expect(await db.select(db.localShlokas).get(), isEmpty);
    });

    test('search matches reference, title and content literally', () async {
      await db.chapterDao.upsertChapter(chapterFixture(2));
      await db.shlokaDao.upsertShlokas([
        shlokaFixture(2, 47, indexTitle: 'TEST Duty without attachment'),
        shlokaFixture(2, 48, englishMeaning: 'TEST 100% steady'),
        shlokaFixture(2, 49),
      ]);

      Future<List<String>> refs(String q) async =>
          (await db.shlokaDao.searchShlokas(
            q,
          )).map((s) => s.reference).toList();

      expect(await refs('2.47'), ['2.47']);
      expect(await refs('attachment'), ['2.47']);
      expect(await refs('ATTACHMENT'), ['2.47']); // ASCII case-insensitive
      expect(await refs('100%'), ['2.48']);
      expect(await refs('%'), ['2.48']); // % is literal, not a wildcard
      expect(await refs('   '), isEmpty);
    });
  });

  test('timestamps are stored as fixed-width UTC text', () async {
    await db.chapterDao.upsertChapter(
      chapterFixture(1, updatedAt: DateTime.utc(2025, 3, 4, 5, 6, 7, 8, 9)),
    );
    final row = await db
        .customSelect('SELECT updated_at FROM local_chapters')
        .getSingle();
    expect(row.read<String>('updated_at'), '2025-03-04T05:06:07.008009Z');
  });
}
