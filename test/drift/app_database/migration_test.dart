import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/data/local/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

/// Migration tests, built on Drift's schema snapshots in `drift_schemas/`.
///
/// When the schema changes:
///   1. bump `AppDatabase.currentSchemaVersion`;
///   2. run `dart run build_runner build` and
///      `dart run drift_dev make-migrations` (exports the new snapshot and
///      regenerates `app_database.steps.dart` and `generated/`);
///   3. implement the step in `AppDatabase` and add tests here.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('upgrading from v1 produces exactly the current schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);
  });

  test('v1 → v2 keeps every personal record and cached verse', () async {
    final schema = await verifier.schemaAt(1);

    // A v1 database with content and one of each personal record.
    final old = v1.DatabaseAtV1(schema.newConnection());
    const shloka = '00000000-0000-4000-8000-000000001041';
    const t = '2026-01-01T09:00:00.000000Z';
    await old.customStatement('PRAGMA foreign_keys = ON');
    for (final sql in [
      "INSERT INTO local_chapters (id, sanskrit_name, hindi_name, english_name, created_at, updated_at) VALUES (1, 'TEST', 'TEST', 'TEST', '$t', '$t')",
      "INSERT INTO local_shlokas (id, chapter_id, verse_number, reference, hindi_meaning_note, created_at, updated_at) VALUES ('$shloka', 1, 41, '1.41', 'TEST note', '$t', '$t')",
      "INSERT INTO reflections VALUES ('00000000-0000-4000-8000-0000000000a1', '$shloka', 'My answer', '$t', '$t')",
      "INSERT INTO personal_notes VALUES ('00000000-0000-4000-8000-0000000000a2', '$shloka', NULL, 'My note', '$t', '$t')",
      "INSERT INTO bookmarks VALUES ('00000000-0000-4000-8000-0000000000a3', '$shloka', '$t')",
      "INSERT INTO reading_progress VALUES ('00000000-0000-4000-8000-0000000000a4', '$shloka', 'studied', '$t', '$t', '$t', NULL, '$t')",
      "INSERT INTO reading_history VALUES ('00000000-0000-4000-8000-0000000000a5', '$shloka', 'opened', '$t')",
      """INSERT INTO local_settings VALUES ('theme_mode', '"dark"', '$t')""",
    ]) {
      await old.customStatement(sql);
    }
    await old.close();

    // Open it with the current app: migrates to the current version.
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, AppDatabase.currentSchemaVersion);

    expect(
      (await db.reflectionDao.getReflectionsForShloka(shloka)).single.answer,
      'My answer',
    );
    expect(
      (await db.personalNoteDao.getNotesForShloka(shloka)).single.content,
      'My note',
    );
    expect(await db.bookmarkDao.isBookmarked(shloka), isTrue);
    expect(
      (await db.readingProgressDao.getProgress(shloka))!.status.sqlValue,
      'studied',
    );
    expect(
      await db.readingHistoryDao.getHistoryForShloka(shloka),
      hasLength(1),
    );
    expect(await db.settingsDao.getString('theme_mode'), 'dark');
    expect(
      (await db.shlokaDao.getShloka(shloka))!.hindiMeaningNote,
      'TEST note',
    );
    // The v2 tables exist and start empty.
    expect(await db.contentSourceDao.getSources(), isEmpty);
    expect(await db.contentSourceDao.getAttributionsForShloka(shloka), isEmpty);
  });

  test(
    'a fresh install (onCreate) produces exactly the defined schema',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.validateDatabaseSchema();
    },
  );
}
