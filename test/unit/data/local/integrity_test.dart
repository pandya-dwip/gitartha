import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/core/errors/local_database_exception.dart';
import 'package:gitartha/data/local/database/app_database.dart';
import 'package:gitartha/data/local/database/database_connection.dart';
import 'package:gitartha/data/local/repositories/local_database_repository.dart';

import 'matchers.dart';
import 'test_database.dart';

void main() {
  group('schema initialization', () {
    late AppDatabase db;
    setUp(() => db = openTestDatabase());
    tearDown(() => db.close());

    test('creates every table, as STRICT, at schema version 1', () async {
      await db.ensureInitialized();
      final tables = await db
          .customSelect(
            "SELECT name, strict FROM pragma_table_list WHERE schema = 'main' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();
      expect(tables.map((r) => r.read<String>('name')), [
        'bookmarks',
        'local_chapters',
        'local_settings',
        'local_shlokas',
        'personal_notes',
        'reading_history',
        'reading_progress',
        'reflections',
        'sync_metadata',
      ]);
      expect(tables.every((r) => r.read<int>('strict') == 1), isTrue);

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(
        version.read<int>('user_version'),
        AppDatabase.currentSchemaVersion,
      );
    });

    test('creates the expected indexes', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name NOT LIKE 'sqlite_autoindex%' ORDER BY name",
          )
          .get();
      expect(rows.map((r) => r.read<String>('name')), [
        'bookmarks_created_idx',
        'local_chapters_updated_at_idx',
        'local_shlokas_reference_idx',
        'local_shlokas_updated_at_idx',
        'personal_notes_shloka_updated_idx',
        'personal_notes_updated_idx',
        'reading_history_occurred_idx',
        'reading_history_shloka_occurred_idx',
        'reflections_created_idx',
        'reflections_shloka_created_idx',
      ]);
    });

    test('enables foreign key enforcement', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.read<int>('foreign_keys'), 1);
    });
  });

  group('foreign keys', () {
    late AppDatabase db;
    late String shlokaId;

    setUp(() async {
      db = openTestDatabase();
      shlokaId = (await seedChapter(db, 1, verses: 1)).single.id;
    });
    tearDown(() => db.close());

    test('a chapter with verses cannot be deleted', () async {
      await expectLater(
        db.customStatement('DELETE FROM local_chapters WHERE id = 1'),
        throwsForeignKeyError,
      );
    });

    final personalWrites = <String, Future<void> Function(AppDatabase, String)>{
      'reflection': (db, id) =>
          db.reflectionDao.addReflection(shlokaId: id, answer: 'a'),
      'note': (db, id) =>
          db.personalNoteDao.createNote(shlokaId: id, content: 'n'),
      'bookmark': (db, id) => db.bookmarkDao.addBookmark(id),
      'progress': (db, id) => db.readingProgressDao.recordOpening(id),
      'history': (db, id) =>
          db.readingHistoryDao.recordActivity(id, ReadingActivity.opened),
    };

    for (final MapEntry(key: kind, value: write) in personalWrites.entries) {
      test('a shloka with a $kind cannot be physically deleted', () async {
        await write(db, shlokaId);
        await expectLater(
          db.customStatement(
            "DELETE FROM local_shlokas WHERE id = '$shlokaId'",
          ),
          throwsForeignKeyError,
        );
        // ...and a server tombstone keeps the personal record.
        await db.shlokaDao.markShlokaDeleted(
          shlokaId,
          deletedAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        final total = await db
            .customSelect(
              'SELECT (SELECT count(*) FROM reflections) + '
              '(SELECT count(*) FROM personal_notes) + '
              '(SELECT count(*) FROM bookmarks) + '
              '(SELECT count(*) FROM reading_progress) + '
              '(SELECT count(*) FROM reading_history) AS n',
            )
            .getSingle();
        expect(total.read<int>('n'), 1);
      });

      test('a $kind must reference a cached shloka', () async {
        await expectLater(write(db, testUuid(404)), throwsForeignKeyError);
      });
    }
  });

  group('transactions', () {
    late AppDatabase db;
    late LocalDatabaseRepository repo;

    setUp(() async {
      db = openTestDatabase();
      repo = LocalDatabaseRepository(db);
      await seedChapter(db, 1, verses: 1);
    });
    tearDown(() => db.close());

    test('roll back every write when a step fails', () async {
      final shlokaId = (await db.shlokaDao.getShlokasForChapter(1)).single.id;
      await expectLater(
        db.transaction(() async {
          await db.reflectionDao.addReflection(shlokaId: shlokaId, answer: 'a');
          await db.bookmarkDao.addBookmark(shlokaId);
          throw StateError('simulated failure');
        }),
        throwsStateError,
      );
      expect(await db.reflectionDao.getReflectionsForShloka(shlokaId), isEmpty);
      expect(await db.bookmarkDao.isBookmarked(shlokaId), isFalse);
    });

    test(
      'a failed multi-table repository operation leaves nothing behind',
      () async {
        await expectLater(
          repo.markShloka(testUuid(404), ReadingStatus.studied),
          throwsForeignKeyError,
        );
        expect(await repo.getAllProgress(), isEmpty);
        expect(await repo.getRecentHistory(), isEmpty);
      },
    );

    test(
      'cacheContent is all-or-nothing across chapters and shlokas',
      () async {
        await expectLater(
          repo.cacheContent(
            chapters: [chapterFixture(2)],
            shlokas: [shlokaFixture(2, 1), shlokaFixture(9, 1)],
          ),
          throwsForeignKeyError,
        );
        expect(await repo.getChapter(2), isNull);
        expect((await repo.getChapters()).map((c) => c.id), [1]);
      },
    );
  });

  group('migration strategy', () {
    test('refuses to open a database from a newer app version', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) => raw.execute('PRAGMA user_version = 2'),
        ),
      );
      addTearDown(db.close);
      await expectLater(
        db.ensureInitialized(),
        throwsA(
          isA<LocalDatabaseException>().having(
            (e) => e.message,
            'message',
            contains('schema version 2'),
          ),
        ),
      );
    });
  });

  group('persistence', () {
    test('data survives closing and reopening the database file', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final dir = await Directory.systemTemp.createTemp('gitartha_db_test');
      addTearDown(() => dir.delete(recursive: true));
      final options = DriftNativeOptions(
        databaseDirectory: () async => dir.path,
        tempDirectoryPath: () async => dir.path,
      );

      // First "app run": the production connection factory, pointed at a
      // temporary directory instead of the documents directory.
      final first = AppDatabase(openPersistentConnection(native: options));
      await first.ensureInitialized();
      final shlokaId = (await seedChapter(first, 1, verses: 1)).single.id;
      final saved = await first.reflectionDao.addReflection(
        shlokaId: shlokaId,
        answer: 'Persisted answer',
      );
      await first.settingsDao.setString('theme_mode', 'dark');
      await first.close();

      expect(
        File('${dir.path}/$localDatabaseName.sqlite').existsSync(),
        isTrue,
      );

      // Second "app run".
      final second = AppDatabase(openPersistentConnection(native: options));
      addTearDown(second.close);
      await second.ensureInitialized();
      expect(await second.reflectionDao.getReflectionsForShloka(shlokaId), [
        saved,
      ]);
      expect(await second.settingsDao.getString('theme_mode'), 'dark');
      final fk = await second.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fk.read<int>('foreign_keys'), 1);
    });
  });
}
