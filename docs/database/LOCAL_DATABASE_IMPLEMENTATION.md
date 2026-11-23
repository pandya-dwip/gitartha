# Gitartha — Local Database Implementation

How the on-device database is built: code layout, responsibilities, startup, migrations,
and how the next milestone (pull sync) plugs in. The schema itself is documented in
[`LOCAL_SQLITE_SCHEMA.md`](LOCAL_SQLITE_SCHEMA.md), and the tests in
[`LOCAL_DATABASE_TESTING.md`](LOCAL_DATABASE_TESTING.md).

## Stack

| Package | Version (locked) | Role |
|---|---|---|
| `drift` | 2.34.0 | ORM, typed queries, migrations |
| `drift_flutter` | 0.3.1 | Opens the database file on Flutter (bundles SQLite via `sqlite3`) |
| `drift_dev` + `build_runner` (dev) | 2.34.0 / 2.15.1 | Code generation, schema snapshots, migration test tools |

No packages were added in this milestone: all of the above were already in
`pubspec.yaml`. `path_provider` is used only indirectly, through `drift_flutter`. UUIDs
come from a small local helper (`lib/core/utils/uuid.dart`) rather than a package.

## Code layout

```text
lib/
├── main.dart                          opens the database before the first frame
├── core/
│   ├── errors/local_database_exception.dart
│   └── utils/uuid.dart                generateUuidV4() for device-created records
└── data/local/
    ├── local_database_providers.dart  appDatabaseProvider, localDatabaseRepositoryProvider
    ├── database/
    │   ├── app_database.dart          @DriftDatabase: tables, DAOs, version, migrations
    │   ├── app_database.g.dart        generated
    │   ├── database_connection.dart   persistent file connection (drift_flutter)
    │   ├── converters.dart            UTC timestamps, JSON string lists, enums
    │   └── tables/                    one file per table (11)
    ├── daos/                          one DAO per table (+ helpers), each with .g.dart
    │   ├── chapter_dao.dart           shloka_dao.dart        reflection_dao.dart
    │   ├── personal_note_dao.dart     bookmark_dao.dart      reading_progress_dao.dart
    │   ├── reading_history_dao.dart   settings_dao.dart      sync_metadata_dao.dart
    │   ├── like_pattern.dart          (escaped LIKE patterns for search)
    │   └── validation.dart            (blank-text and clock-skew guards)
    └── repositories/
        └── local_database_repository.dart

drift_schemas/app_database/drift_schema_v1.json   exported schema snapshot (commit it)
test/drift/app_database/                          migration tests + generated schema helpers
build.yaml                                        drift_dev options (databases, schema/test dirs)
```

Generated files (`*.g.dart`, `test/drift/**/generated/`) are produced by tools and never
edited by hand. They are committed, so the project builds without running the
generator first, and they are excluded from analysis.

## Responsibilities

| Layer | Does | Does not |
|---|---|---|
| **Tables** (`tables/`) | Columns, types, keys, CHECKs, foreign keys, indexes | Queries |
| **DAOs** (`daos/`) | Typed queries and writes for one table (joins where needed). Input validation. Per-operation transactions | Operations that span several tables. Business rules |
| **Repository** (`LocalDatabaseRepository`) | The only API feature code uses. Delegates to DAOs. Runs multi-table operations in one transaction | UI state. Networking |
| **`AppDatabase`** | Registers tables and DAOs, schema version, migration strategy, foreign-key pragma, clock and id injection | Feature logic |

Presentation code must use `localDatabaseRepositoryProvider` and must never import
tables or DAOs.

### DAOs

| DAO | Main operations |
|---|---|
| `ChapterDao` | `getChapters`, `watchChapters`, `getChapter`, `upsertChapter(s)`, `markChapterDeleted` |
| `ShlokaDao` | `getShlokasForChapter`, `watchShlokasForChapter`, `getShloka` (by UUID, optionally including deleted), `getShlokaByVerse`, `searchShlokas`, `upsertShloka(s)`, `markShlokaDeleted` |
| `ReflectionDao` | `addReflection`, `updateReflection`, `deleteReflection`, `getReflection`, `getReflectionsForShloka`, `watchReflectionsForShloka`, `getRecentReflections` |
| `PersonalNoteDao` | `createNote`, `updateNote`, `deleteNote`, `getNote`, `getNotesForShloka`, `watchNotesForShloka`, `getAllNotes`, `searchNotes` |
| `BookmarkDao` | `addBookmark` (idempotent), `removeBookmark`, `isBookmarked`, `watchIsBookmarked`, `getBookmarks`, `watchBookmarks` |
| `ReadingProgressDao` | `recordOpening`, `updateStatus`, `getProgress`, `watchProgress`, `getAllProgress`, `getChapterProgressSummaries`, `watchChapterProgressSummaries` |
| `ReadingHistoryDao` | `recordActivity`, `getRecentHistory`, `getHistoryForShloka`, `getHistoryBetween`, `getLatestActivity` |
| `SettingsDao` | `setValue`/`getValue`/`watchValue`/`deleteValue`/`getAll`, plus typed `get/setString`, `Bool`, `Int`, `Double`, `Json` |
| `SyncMetadataDao` | `getValue`/`setValue`/`deleteValue`/`getAll` (storage only, no sync logic) |
| `ContentSourceDao` (v2) | `getSources`, `getSource`, `upsertSource`, `getAttributionsForShloka`, `replaceAttributionsForShloka` |

Notes:

- **Cache upserts** (`upsertChapter(s)` / `upsertShloka(s)`) use
  `INSERT … ON CONFLICT(id) DO UPDATE … WHERE cached.updated_at <= incoming.updated_at`.
  They keep the server id, never let an older version overwrite a newer one, and never
  touch personal tables. Batch variants are all-or-nothing.
- **Search** (`searchShlokas`, `searchNotes`) uses `LIKE` with escaped `%`, `_` and `\`,
  so user input can't act as a wildcard. SQLite's `LIKE` is case-insensitive for ASCII
  only. Devanagari has no case.
- **Live content:** shloka reading queries exclude soft-deleted shlokas **and** shlokas
  of soft-deleted chapters.

### Repository

`LocalDatabaseRepository` (`lib/data/local/repositories/`) exposes everything above
under one class, plus these cross-table operations, each in one transaction:

| Method | Does |
|---|---|
| `recordShlokaOpened(id)` | Progress `recordOpening`, plus an `opened` history entry (de-duplicated within `openedHistoryDedupWindow` = 1 minute) |
| `markShloka(id, status)` | Progress `updateStatus`, plus the matching `marked_*` history entry |
| `cacheContent(chapters:, shlokas:)` | Upserts chapters, then shlokas. Used by the future sync |

It re-exports the row types (`LocalChapter`, `LocalShloka`, `Reflection`,
`PersonalNote`, `Bookmark`, `ReadingProgressEntry`, `ReadingHistoryEntry`), the enums
(`ReadingStatus`, `ReadingActivity`), `ChapterProgressSummary`, `LocalSettingKeys` and
Drift's `Value`, so callers need only one import.

> **Deliberate simplification:** the repository returns Drift's generated row classes,
> which are immutable value objects, instead of separate domain entities. This avoids
> nine parallel entity classes and their mappers before any feature uses them. When a
> feature milestone introduces domain entities (`PROJECT_ARCHITECTURE.md` → domain
> layer), the mapping belongs in that feature's data layer, on top of this repository.

### Errors

Nothing is swallowed:

- Invalid input (a blank answer, a secret-like setting key, `updateStatus(opened)`)
  throws `ArgumentError` before SQL runs.
- Constraint violations (foreign key, unique, CHECK) surface as the underlying SQLite
  exception, and any surrounding transaction rolls back.
- A wrongly typed setting value throws `FormatException`. Values are never silently
  coerced.
- Startup or migration failures throw `LocalDatabaseException`, with the original
  `cause` attached.
- "Not found" is a `null` or `false` return value, not an exception.

### Time and ids

`AppDatabase(executor, {clock, idGenerator})` takes an injectable clock (UTC) and id
generator. Production uses `DateTime.now().toUtc()` and `generateUuidV4()`, and tests
use a controllable clock. DAOs never call `DateTime.now()` directly.

## Initialization and lifecycle

```text
main()
  WidgetsFlutterBinding.ensureInitialized()
  config = AppConfig.load()
  container = ProviderContainer(overrides: [appConfigProvider])
  await container.read(appDatabaseProvider).ensureInitialized()
      → drift_flutter resolves <documents>/gitartha.sqlite
      → opens it in a background isolate
      → onCreate (first run) or onUpgrade (version change)
      → beforeOpen: PRAGMA foreign_keys = ON (verified)
  runApp(UncontrolledProviderScope(container: container, child: GitarthaApp()))
```

- **One instance:** `appDatabaseProvider` is a plain (not auto-disposed) Riverpod
  `Provider`, read through the single root container. The same `AppDatabase` serves the
  whole app run, so there is never a second connection to the file.
- **Disposal:** the provider registers `ref.onDispose(db.close)`. The database closes
  when the container is disposed, and the OS reclaims it if the process is killed.
  SQLite's journal keeps committed data safe either way.
- **Failure:** if the file can't be opened or migrated, `ensureInitialized` throws
  `LocalDatabaseException` and startup stops with a clear error. There is no UI fallback
  in this milestone.
- **Persistence:** the file lives in the app's documents directory. It survives
  restarts and app updates, and is deleted only on uninstall or "clear data".
- **Tests** override `appDatabaseProvider` with `AppDatabase(NativeDatabase.memory())`.
  Production never uses an in-memory database.

## Migration strategy

- `AppDatabase.currentSchemaVersion = 2`. `onCreate` creates all tables and indexes.
- `onUpgrade` runs the generated `stepByStep` helper (`app_database.steps.dart`):
  - **v1 → v2** (Milestone 3): `createTable(localContentSources)`,
    `createTable(localShlokaSourceAttributions)` and their two indexes. This step is
    purely additive.
- Before stepping, `onUpgrade` refuses what it can't do safely:
  - **Downgrade** (database newer than the app): `LocalDatabaseException`, "update the
    app". Data is left untouched.
  - **Unknown upgrade path:** `LocalDatabaseException`. There is never a silent
    "drop and recreate".
- Snapshots `drift_schemas/app_database/drift_schema_v1.json` and `_v2.json` are
  exported. `test/drift/app_database/migration_test.dart` upgrades a v1 database that
  holds one of every personal record, then checks that the result equals a fresh v2
  schema and that every record survived.

**To change the schema** (next: v3):

1. Edit the table classes.
2. Bump `currentSchemaVersion`.
3. Run `dart run build_runner build`, then `dart run drift_dev make-migrations`. This
   exports the new snapshot, regenerates `app_database.steps.dart`, and regenerates the
   test helpers in `test/drift/app_database/generated/`.
4. Add the step to `stepByStep(...)` in `AppDatabase`, with additive
   operations such as `m.addColumn(...)` and `m.createTable(...)`. Never drop or recreate
   tables that hold personal data. When a table must be rebuilt, use
   `m.alterTable(TableMigration(...))`, which copies the rows.
5. Fill in the generated test, including a data-integrity check that existing
   reflections and notes survive the upgrade, and run `flutter test`.

## Preparing for sync (next milestone)

The local database already provides everything the pull-sync procedure in
[`SYNC_STRATEGY.md`](SYNC_STRATEGY.md) needs:

| Sync step | Local support |
|---|---|
| Read cache while offline | `getChapters`, `getShlokasForChapter`, and other live-content queries |
| Apply a page of server rows | `cacheContent(chapters:, shlokas:)`: one transaction, keeps ids, never goes backwards, chapters before shlokas |
| Apply tombstones | Upserted rows carry `deleted_at`. `markChapterDeleted` / `markShlokaDeleted` also exist |
| Keep personal data intact | No cache path deletes rows, and every personal foreign key is RESTRICT |
| Store cursors and last sync time | `sync_metadata` (`SyncMetadataKeys`) |
| Compare server timestamps | Microsecond UTC text, the same precision as Postgres |

Not implemented yet, on purpose: the Supabase client, authentication, fetching, cursor
logic, scheduling, and JSON import.

## Known limitations

- **Device backups.** Android Auto Backup (enabled by default) and iOS device backups
  may include the documents directory, and therefore personal data, in the user's
  **own** Google/iCloud backup. That is not Gitartha's server, but if personal data
  must stay strictly on the device, set `android:allowBackup="false"` (or a
  backup-rules file) and exclude the file from iCloud backup. **Decision needed.**
- **Encryption at rest.** The file is not encrypted. SQLCipher could be adopted later if
  required.
- **Search** is `LIKE`-based. FTS5 is planned for the search milestone.
- **Web** is not supported. The project targets Android and iOS, and `drift_flutter` on
  the web would need additional WASM assets.
- **Verse renumbering** during sync must respect the local UNIQUE
  `(chapter_id, verse_number)` constraint (see `SYNC_STRATEGY.md`).
- **History retention.** `reading_history` grows without bound. A pruning policy is a
  later decision.
