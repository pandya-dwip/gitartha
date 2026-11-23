import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/content/content_ids.dart';
import 'package:gitartha/data/content/importers/content_import_service.dart';
import 'package:gitartha/data/content/importers/import_result.dart';
import 'package:gitartha/data/local/database/app_database.dart';
import 'package:gitartha/data/local/repositories/local_database_repository.dart';

import '../local/test_database.dart';
import 'content_fixtures.dart';

/// Mandatory: re-importing shared scripture must never delete or change
/// reflections, notes, bookmarks, reading progress, reading history or
/// settings.
void main() {
  late TestClock clock;
  late AppDatabase db;
  late LocalDatabaseRepository repo;
  late MapContentSource source;
  final shlokaId = ContentIds.shloka('chapter_01_verse_041');

  Map<String, Object?> chapterOne({String english = 'TEST english meaning'}) =>
      chapterFile(chapterMeta(1, complete: true, status: 'approved'), [
        approvedVerse(1, 40),
        approvedVerse(1, 41, englishMeaning: english),
      ]);

  Future<ImportResult> import([ImportMode mode = ImportMode.draft]) =>
      ContentImportService(
        source: source,
        database: db,
      ).importContent(mode: mode, chapterIds: [1]);

  /// Every personal table, row by row, for exact before/after comparison.
  Future<Map<String, List<Object>>> personalSnapshot() async => {
    'reflections': await db.select(db.reflections).get(),
    'personal_notes': await db.select(db.personalNotes).get(),
    'bookmarks': await db.select(db.bookmarks).get(),
    'reading_progress': await db.select(db.readingProgress).get(),
    'reading_history': await db.select(db.readingHistory).get(),
    'local_settings': await db.select(db.localSettings).get(),
  };

  setUp(() async {
    clock = TestClock();
    db = openTestDatabase(clock: clock);
    repo = LocalDatabaseRepository(db);
    source = MapContentSource(
      chapters: {fileFor(1): chapterOne()},
      sources: sourcesFixture(),
    );
    final first = await import();
    expect(first.verses.inserted, 2);

    // One of every kind of personal record, attached to verse 1.41.
    await repo.addReflection(shlokaId: shlokaId, answer: 'My first answer');
    clock.advance(const Duration(days: 30));
    await repo.addReflection(shlokaId: shlokaId, answer: 'My second answer');
    await repo.createNote(shlokaId: shlokaId, title: 'Mine', content: 'A note');
    await repo.createNote(content: 'A note about nothing in particular');
    await repo.addBookmark(shlokaId);
    await repo.recordShlokaOpened(shlokaId);
    await repo.markShloka(shlokaId, ReadingStatus.studied);
    await repo.setSetting(LocalSettingKeys.themeMode, 'dark');
  });
  tearDown(() => db.close());

  test('personal records survive an update of their shloka', () async {
    final before = await personalSnapshot();
    expect(before.values.every((rows) => rows.isNotEmpty), isTrue);

    clock.advance(const Duration(days: 1));
    source.put(fileFor(1), chapterOne(english: 'TEST revised meaning'));
    final result = await import();

    expect(result.verses.updated, 1);
    expect(
      (await db.shlokaDao.getShloka(shlokaId))!.englishMeaning,
      'TEST revised meaning',
    );
    expect(await personalSnapshot(), before);
  });

  test(
    'personal records survive repeated unchanged imports, in both modes',
    () async {
      final before = await personalSnapshot();
      for (var i = 0; i < 3; i++) {
        final draft = await import();
        expect(draft.verses.unchanged, 2);
      }
      final approved = await import(ImportMode.approved);
      expect(approved.verses.unchanged, 2);

      expect(await personalSnapshot(), before);
      // Importing never logs reading activity.
      expect(await repo.getHistoryForShloka(shlokaId), hasLength(2));
    },
  );

  test('a failed re-import leaves personal records untouched', () async {
    final before = await personalSnapshot();
    await db.customStatement(
      'CREATE TRIGGER fail_update BEFORE UPDATE ON local_shlokas '
      "BEGIN SELECT RAISE(ABORT, 'simulated failure'); END",
    );
    source.put(fileFor(1), chapterOne(english: 'TEST revised meaning'));

    final result = await import();
    expect(result.status, ImportStatus.failed);
    expect(await personalSnapshot(), before);
    expect(
      (await db.shlokaDao.getShloka(shlokaId))!.englishMeaning,
      'TEST english meaning',
    );
  });

  test(
    'removing a verse from the files does not delete it or its data',
    () async {
      final before = await personalSnapshot();
      source.put(
        fileFor(1),
        chapterFile(chapterMeta(1, complete: true, status: 'approved'), [
          approvedVerse(1, 40),
        ]),
      );
      await import();

      expect(await db.shlokaDao.getShloka(shlokaId), isNotNull);
      expect(await personalSnapshot(), before);
    },
  );
}
