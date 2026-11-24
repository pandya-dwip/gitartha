import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/content_ids.dart';
import 'package:gitartha/data/content/importers/chapter_content_importer.dart';
import 'package:gitartha/data/content/importers/content_import_service.dart';
import 'package:gitartha/data/content/importers/import_result.dart';
import 'package:gitartha/data/content/services/file_system_content_source.dart';
import 'package:gitartha/data/local/database/app_database.dart';

import '../local/test_database.dart';
import 'content_fixtures.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<ImportResult> import(
    MapContentSource source, {
    ImportMode mode = ImportMode.draft,
    Iterable<int>? chapters,
  }) => ContentImportService(
    source: source,
    database: db,
  ).importContent(mode: mode, chapterIds: chapters);

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');

  group('draft import', () {
    test('imports one chapter with stable ids and every field', () async {
      final source = MapContentSource(
        chapters: {
          fileFor(1): chapterFile(chapterMeta(1, complete: true), [
            verse(
              1,
              41,
              attributions: [
                {
                  'source_id': testSourceId,
                  'content_section': 'hindi_meaning_note',
                },
              ],
            ),
          ]),
        },
        sources: sourcesFixture(),
      );
      final result = await import(source, chapters: [1]);

      expect(result.status, ImportStatus.succeeded, reason: result.toReport());
      expect(result.chapters.inserted, 1);
      expect(result.verses.inserted, 1);
      expect(result.sources.inserted, 1);
      expect(result.attributionsInserted, 1);

      final id = ContentIds.shloka('chapter_01_verse_041');
      expect(result.shlokaIds, {'chapter_01_verse_041': id});
      final row = (await db.shlokaDao.getShloka(id))!;
      expect(row.reference, '1.41');
      expect(row.chapterId, 1);
      expect(row.verseNumber, 41);
      expect(row.hindiMeaning, 'TEST हिन्दी अर्थ');
      expect(row.hindiMeaningNote, 'TEST wording note');
      expect(row.sanskritText, contains('\n'));
      expect(row.updatedAt, contentRepositoryTimestamp);

      final chapter = (await db.chapterDao.getChapter(1))!;
      expect(chapter.keyTopics, ['TEST topic A', 'TEST topic B']);

      final attribution = (await db.contentSourceDao.getAttributionsForShloka(
        id,
      )).single;
      expect(attribution.contentSection, 'hindi_meaning_note');
      expect(attribution.sourceId, ContentIds.source(testSourceId));
    });

    test('imports several chapters', () async {
      final result = await import(
        MapContentSource(
          chapters: {
            fileFor(1): chapterFile(chapterMeta(1, named: true), [verse(1, 1)]),
            fileFor(2): chapterFile(chapterMeta(2, named: true), [
              verse(2, 1),
              verse(2, 2),
            ]),
          },
        ),
        chapters: [1, 2],
      );
      expect(result.chapters.inserted, 2);
      expect(result.verses.inserted, 3);
      expect(await count('local_shlokas'), 3);
    });

    test('accepts an incomplete chapter, storing blanks as null', () async {
      final result = await import(
        MapContentSource(
          chapters: {
            fileFor(1): chapterFile(chapterMeta(1), [
              verse(
                1,
                41,
                blank: {'index_summary', 'context'},
                hindiNote: null,
              ),
            ]),
          },
        ),
        chapters: [1],
      );
      expect(result.status, ImportStatus.succeeded); // warnings only
      expect(result.validationWarnings, isNotEmpty);
      final row = (await db.shlokaDao.getShloka(
        ContentIds.shloka('chapter_01_verse_041'),
      ))!;
      expect(row.indexSummary, isNull);
      expect(row.context, isNull);
      expect(row.hindiMeaningNote, isNull);
      final chapter = (await db.chapterDao.getChapter(1))!;
      expect(chapter.englishName, ''); // draft only: names not written yet
      expect(chapter.overview, isNull);
      expect(chapter.keyTopics, isNull);
    });

    test('rejects invalid JSON without stopping other chapters', () async {
      final result = await import(
        MapContentSource(
          chapters: {
            fileFor(1): '{"schema_version": ',
            fileFor(2): chapterFile(chapterMeta(2, named: true), [verse(2, 1)]),
          },
        ),
        chapters: [1, 2],
      );
      expect(result.status, ImportStatus.failed);
      expect(result.isSuccess, isFalse);
      expect(result.skipped.first.reason, ImportSkipReason.fileInvalid);
      expect(await db.chapterDao.getChapter(1), isNull);
      expect(await db.chapterDao.getChapter(2), isNotNull);
    });
  });

  group('approved import', () {
    test('imports only complete, approved, sourced verses', () async {
      final result = await import(
        MapContentSource(
          chapters: {
            fileFor(1): chapterFile(
              chapterMeta(1, complete: true, status: 'approved'),
              [
                approvedVerse(1, 1),
                verse(1, 2), // complete but draft: not verified
                verse(1, 3, status: 'approved', blank: {'context'}),
              ],
            ),
          },
          sources: sourcesFixture(),
        ),
        mode: ImportMode.approved,
        chapters: [1],
      );
      expect(result.status, ImportStatus.completedWithRejections);
      expect(result.isSuccess, isFalse);
      expect(result.verses.inserted, 1);
      expect(result.verses.skipped, 2);
      expect(result.skipped.map((s) => s.recordId), [
        'chapter_01_verse_002',
        'chapter_01_verse_003',
      ]);
      expect(await count('local_shlokas'), 1);
      expect(result.attributionsInserted, 3);
      expect((await db.chapterDao.getChapter(1))!.overview, 'TEST overview');
    });

    test('rejects incomplete content entirely', () async {
      final result = await import(
        MapContentSource(
          chapters: {
            fileFor(1): chapterFile(chapterMeta(1, named: true), [
              verse(1, 1, blank: {'context'}),
            ]),
          },
        ),
        mode: ImportMode.approved,
        chapters: [1],
      );
      expect(result.verses.inserted, 0);
      expect(result.verses.skipped, 1);
      expect(result.validationErrors, isNotEmpty);
      expect(await count('local_shlokas'), 0);
      // The chapter is named, so its row exists, but without the unapproved
      // descriptions.
      final chapter = (await db.chapterDao.getChapter(1))!;
      expect(chapter.englishName, 'TEST english name 1');
      expect(chapter.overview, isNull);
    });

    test('a chapter without names cannot be imported', () async {
      final result = await import(
        MapContentSource(
          chapters: {
            fileFor(1): chapterFile(chapterMeta(1), [approvedVerse(1, 1)]),
          },
          sources: sourcesFixture(),
        ),
        mode: ImportMode.approved,
        chapters: [1],
      );
      expect(
        result.skipped.single.reason,
        ImportSkipReason.chapterNamesMissing,
      );
      expect(await count('local_chapters'), 0);
      expect(await count('local_shlokas'), 0);
    });

    test('a fully approved, complete chapter succeeds', () async {
      // Chapter 12 has 20 verses in the 700-verse numbering.
      final result = await import(
        MapContentSource(
          chapters: {
            fileFor(12): chapterFile(
              chapterMeta(12, complete: true, status: 'approved'),
              [for (var v = 1; v <= 20; v++) approvedVerse(12, v)],
            ),
          },
          sources: sourcesFixture(includeUnlicensed: true),
        ),
        mode: ImportMode.approved,
        chapters: [12],
      );
      // The unlicensed source is skipped; everything else imports.
      expect(result.sources.inserted, 1);
      expect(result.sources.skipped, 1);
      expect(result.verses.inserted, 20);
      expect(result.validation!.isValid, isTrue);
      expect(result.validation!.publicationReadyChapters, 1);
      expect(result.status, ImportStatus.completedWithRejections); // source
    });
  });

  group('idempotency and updates', () {
    MapContentSource source() => MapContentSource(
      chapters: {
        fileFor(1): chapterFile(chapterMeta(1, complete: true), [
          verse(1, 40),
          verse(1, 41, attributions: requiredAttributions()),
        ]),
      },
      sources: sourcesFixture(),
    );

    test('re-importing unchanged content changes nothing', () async {
      final s = source();
      await import(s, chapters: [1]);
      final before = await db.select(db.localShlokas).get();

      final again = await import(s, chapters: [1]);
      expect(again.status, ImportStatus.succeeded);
      expect(again.chapters.unchanged, 1);
      expect(again.verses.unchanged, 2);
      expect(again.verses.inserted + again.verses.updated, 0);
      expect(again.sources.unchanged, 1);
      expect(again.attributionsInserted + again.attributionsDeleted, 0);
      expect(await db.select(db.localShlokas).get(), before);
      expect(await count('local_shloka_source_attributions'), 3);
    });

    test('changed content updates the same row, keeping its id', () async {
      final s = source();
      await import(s, chapters: [1]);
      final id = ContentIds.shloka('chapter_01_verse_041');

      s.put(
        fileFor(1),
        chapterFile(chapterMeta(1, complete: true), [
          verse(1, 40),
          verse(
            1,
            41,
            englishMeaning: 'TEST revised meaning',
            attributions: requiredAttributions().sublist(0, 2),
          ),
        ]),
      );
      final result = await import(s, chapters: [1]);

      expect(result.verses.updated, 1);
      expect(result.verses.unchanged, 1);
      expect(result.attributionsDeleted, 1);
      final row = (await db.shlokaDao.getShloka(id))!;
      expect(row.id, id);
      expect(row.englishMeaning, 'TEST revised meaning');
      expect(row.hindiMeaningNote, 'TEST wording note');
      expect(await count('local_shlokas'), 2);
    });

    test('rows that came from the server are never overwritten', () async {
      await db.chapterDao.upsertChapter(chapterFixture(1));
      final id = ContentIds.shloka('chapter_01_verse_041');
      await db.shlokaDao.upsertShloka(
        shlokaFixture(1, 41, id: id, updatedAt: DateTime.utc(2027)),
      );

      final result = await import(source(), chapters: [1]);
      expect(
        result.skipped.map((s) => s.reason),
        containsAll([ImportSkipReason.serverRecordPresent]),
      );
      expect((await db.shlokaDao.getShloka(id))!.updatedAt, DateTime.utc(2027));
    });

    test('an occupied verse slot is skipped, not overwritten', () async {
      await db.chapterDao.upsertChapter(chapterFixture(1));
      await db.shlokaDao.upsertShloka(shlokaFixture(1, 40, id: testUuid(4040)));

      final result = await import(source(), chapters: [1]);
      // (The seeded chapter row counts as server content and is skipped too.)
      final verseSkip = result.skipped.singleWhere(
        (s) => s.recordType == 'shloka',
      );
      expect(verseSkip.reason, ImportSkipReason.verseSlotTaken);
      expect(verseSkip.recordId, 'chapter_01_verse_040');
      expect(result.verses.inserted, 1); // 1.41 still imported
      expect((await db.shlokaDao.getShlokaByVerse(1, 40))!.id, testUuid(4040));
    });
  });

  test('a failed chapter is rolled back completely and reported', () async {
    // Make the database reject verse 2 of chapter 1 mid-transaction.
    await db.customStatement(
      'CREATE TRIGGER fail_verse BEFORE INSERT ON local_shlokas '
      "WHEN NEW.reference = '1.2' BEGIN SELECT RAISE(ABORT, 'simulated failure'); END",
    );
    final result = await import(
      MapContentSource(
        chapters: {
          fileFor(1): chapterFile(chapterMeta(1, named: true), [
            verse(1, 1),
            verse(1, 2),
            verse(1, 3),
          ]),
          fileFor(2): chapterFile(chapterMeta(2, named: true), [verse(2, 1)]),
        },
      ),
      chapters: [1, 2],
    );

    expect(result.status, ImportStatus.failed);
    final failure = result.failures.single;
    expect(failure.transaction, 'chapter 1');
    expect(failure.error, contains('simulated failure'));
    expect(result.verses.failed, 3);
    // Nothing of chapter 1 was written, not even its row or verse 1.1.
    expect(await db.chapterDao.getChapter(1), isNull);
    expect(await db.shlokaDao.getShlokaByVerse(1, 1), isNull);
    // Chapter 2 imported normally.
    expect(await db.shlokaDao.getShlokaByVerse(2, 1), isNotNull);
  });

  test('the result serializes to JSON', () async {
    final result = await import(
      MapContentSource(
        chapters: {
          fileFor(1): chapterFile(chapterMeta(1), [verse(1, 1)]),
        },
      ),
      chapters: [1],
    );
    final json =
        jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;
    expect(json['mode'], 'draft');
    expect(json['status'], 'succeeded');
    expect((json['verses'] as Map)['inserted'], 1);
    expect(json['completedAt'], isNotNull);
    expect(result.toReport(), contains('Verses:   1 inserted'));
  });

  group('the real repository (read-only, into a test database)', () {
    test(
      'draft import loads all 18 chapters and Chapter 1 verses 1-41',
      () async {
        final result = await ContentImportService(
          source: FileSystemContentSource(),
          database: db,
        ).importContent(mode: ImportMode.draft);

        expect(
          result.status,
          ImportStatus.succeeded,
          reason: result.toReport(),
        );
        expect(result.totalFilesDiscovered, 19);
        expect(result.chapters.inserted, 18);
        expect(result.verses.inserted, 41);
        final v = (await db.shlokaDao.getShloka(
          ContentIds.shloka('chapter_01_verse_041'),
        ))!;
        expect(v.reference, '1.41');
        expect(
          v.hindiMeaningNote,
          startsWith('This is a traditional translation'),
        );
        expect(v.indexSummary, isNotNull);

        final again = await ContentImportService(
          source: FileSystemContentSource(),
          database: db,
        ).importContent(mode: ImportMode.draft);
        expect(again.chapters.unchanged, 18);
        expect(again.verses.unchanged, 41);
      },
    );

    test(
      'approved import takes only the approved Chapter 1 and its verses',
      () async {
        final result = await ContentImportService(
          source: FileSystemContentSource(),
          database: db,
        ).importContent(mode: ImportMode.approved);

        expect(result.isSuccess, isFalse);
        expect(result.status, ImportStatus.completedWithRejections);
        // Chapters 2-18 are empty drafts and are left out.
        expect(result.chapters.skipped, 17);
        expect(result.verses.skipped, 0);
        expect(await count('local_chapters'), 1);
        expect(await count('local_shlokas'), 41);
      },
    );
  });
}
