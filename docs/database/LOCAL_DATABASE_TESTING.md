# Gitartha — Local Database Testing

## Running the tests

From the project root:

```sh
flutter pub get
dart run build_runner build        # only needed after changing tables or DAOs
flutter test                       # all tests
flutter test test/unit/data        # local database tests only
flutter test test/drift            # migration / schema snapshot tests only
flutter analyze
```

The tests need no device, network or Supabase. They use an in-memory SQLite database
(`NativeDatabase.memory()`), and one test uses a temporary file. SQLite itself comes
from the `sqlite3` package's build hooks, so nothing has to be installed on the host.

Every test gets a fresh database (`openTestDatabase()` in
`test/unit/data/local/test_database.dart`), and most use a controllable `TestClock`.
Fixtures use obvious placeholder text (`TEST title 1.41`). They are not scripture.

## What is covered

| File | Covers |
|---|---|
| `test/unit/data/local/chapters_shlokas_test.dart` | Chapters inserted and retrieved in order. Chapter id range 1–18. Newer server versions replace the cache and older ones don't. Soft-deleted chapters hidden, together with their verses. `watchChapters`. Shlokas keep the exact Supabase UUID, `hindi_meaning_note` stays separate, the chapter must exist (FK), verses come back in order per chapter. Unique (chapter, verse). Positive verse numbers. Reference consistency CHECK. Soft-deleted shlokas excluded from reading queries but still available by id. A refresh keeps ids and never touches reflections. Batch upserts are all-or-nothing. Search by reference, title and content, with `%` treated literally. Fixed-width UTC timestamps on disk |
| `test/unit/data/local/personal_data_test.dart` | **Reflections:** many per verse with separate ids, and a new answer never overwrites. Editing changes only that entry (`created_at` kept, `updated_at` set). Chronological order with stable ties. Recent reflections newest first. Deleting one keeps the others. Blank answers rejected in Dart and by the SQL CHECK. Clock-skew safety. `watch`. **Notes:** many per verse, notes without a verse, blank title becomes NULL, edit title and content, clear title, delete one, search, FK. **Bookmarks:** add, check, remove. No duplicates (idempotent add plus UNIQUE). Newest-first order |
| `test/unit/data/local/reading_progress_history_test.dart` | Opening creates progress as `opened` and never marks it studied. Reopening updates only `last_opened_at`, and `first_opened_at` is unchanged. Explicit transitions set `studied_at`/`reflected_at` and never downgrade. Marking an unopened verse. `updateStatus(opened)` rejected. One record per verse, and invalid statuses rejected. Chapter progress summaries. **History:** every activity kept in chronological order, recent activity newest first, rapid re-openings de-duplicated, date-range queries, invalid actions rejected |
| `test/unit/data/local/settings_test.dart` | Typed round-trips (string, double, bool, int, JSON). Overwrite, delete and list. Wrong-type reads throw rather than coerce. Secret-like keys refused. Sync metadata storage |
| `test/unit/data/local/integrity_test.dart` | **Schema initialization:** all 11 tables exist and are `STRICT`, `user_version` is the current version (2), all 12 named indexes exist, foreign keys are on. **Foreign keys:** a chapter with verses can't be deleted. A shloka referenced by a reflection, note, bookmark, progress record or history entry can't be deleted, and a tombstone keeps the record. Each personal table requires a cached verse. **Transactions:** an explicit transaction rolls back every write, a failed `markShloka` leaves no progress or history, `cacheContent` is all-or-nothing. **Migrations:** a database from a newer app version is refused with `LocalDatabaseException`. **Persistence:** data written through the production `drift_flutter` connection survives closing and reopening the file |
| `test/unit/data/local/providers_test.dart` | One database instance per container. The repository uses the same instance. Disposal closes the database |
| `test/unit/data/local/converters_test.dart` | Timestamp format, UTC conversion, Supabase-style offsets, text order equal to chronological order. JSON list converter. UUID v4 format and uniqueness |
| `test/drift/app_database/migration_test.dart` | Upgrading v1 → v2 produces exactly the current schema (`migrateAndValidate`). A v1 database holding a reflection, note, bookmark, progress record, history entry, setting and cached verse keeps all of them after the upgrade. A fresh install creates exactly the defined schema (`validateDatabaseSchema`) |

The existing tests (`test/unit/core/config`, `test/widget/app_bootstrap_test.dart`)
still pass. The widget test does not touch the database.

## What is not covered automatically

- **The real documents directory on a device.** Unit tests can't call `path_provider`,
  so the persistence test points the production connection factory at a temporary
  directory instead. On a device, `integration_test/app_launch_test.dart` runs `main()`,
  which opens the real file. Run it with
  `flutter test integration_test -d <device>` when a device or emulator is available.
- **Content pipeline tests** live in `test/unit/data/content/`. See
  `docs/content/CONTENT_IMPORT_PIPELINE.md`.

## Writing new tests

- Use `openTestDatabase(clock: TestClock())`, and close it in `tearDown`.
- Seed content with `seedChapter(db, chapter, verses: n)` or the `*Fixture` helpers.
- Assert constraint failures with `throwsForeignKeyError`, `throwsUniqueError` and
  `throwsCheckError` (`matchers.dart`). They match SQLite's messages without a direct
  `sqlite3` dependency.
- Test through the repository for anything that spans tables, and through DAOs for
  single-table behaviour.
