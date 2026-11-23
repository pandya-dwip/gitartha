# Gitartha — Content Import Pipeline

Imports validated content from the repository into the **local Drift database**.
Nothing is published to Supabase. Nothing runs automatically at app startup.

```text
ContentSource → ContentValidationService (draft | strict)
             → eligible records → ChapterContentImporter (one transaction per chapter)
             → local cache tables → ImportResult
```

## Code

| Class | File | Role |
|---|---|---|
| `ContentRepository` | `lib/data/content/repositories/content_repository.dart` | Entry point: `validate()`, `importDraft()`, `importApproved()` |
| `ContentImportService` | `lib/data/content/importers/content_import_service.dart` | Orchestration: validate, sources transaction, then one transaction per chapter |
| `ChapterContentImporter` | `lib/data/content/importers/chapter_content_importer.dart` | Model → row mapping, diffing and writing |
| `ImportResult` | `lib/data/content/importers/import_result.dart` | Counts, skips, failures, status, `toJson()` |
| `contentRepositoryProvider` | `lib/data/content/content_providers.dart` | Riverpod: bundled assets + the app database |

## Import modes

| | `draft` (`importDraft`) | `approved` (`importApproved`) |
|---|---|---|
| Validation mode | `draft` | `strict` |
| Verse eligible when | it has no errors (incomplete is fine) | complete **and** `approved` **and** sourced with verified licences **and** error-free |
| Chapter row | always (names may be `''`) | only when all three names exist (NOT NULL) |
| Chapter descriptions | as written | only when the chapter metadata is `approved` and complete. Otherwise NULL |
| Sources | every valid source | only sources with a verified licence |
| Purpose | local development and testing | content the app may show as verified |

The presence of text never makes a verse eligible for approved import. Only the
reviewer's `review_status: "approved"` does, and the validator confirms the claim
(complete, attributions present, sources licensed).

The Supabase schema has **no review-status column**, and none was added. The review
state lives in the JSON and acts as an import gate. Whether Supabase should store
editorial metadata is a future content-management decision.

## Database mapping

| JSON | Local table.column | Rule |
|---|---|---|
| `chapter.id` | `local_chapters.id` | as is |
| `chapter.*_name` | `local_chapters.*_name` | `''` if empty (draft only) |
| `chapter.introduction` … `conclusion` | same names | `""` → NULL. Approved mode: NULL unless the metadata is approved |
| `chapter.key_topics` | `local_chapters.key_topics` (JSON text) | `[]` → NULL |
| *(file's chapter id)* | `local_shlokas.chapter_id` | from the file |
| `verse.id` | `local_shlokas.id` | `ContentIds.shloka(verse.id)` (UUID v5) |
| `verse.verse_number`, `reference` | same | as is (reference checked by CHECK) |
| `verse.index_title` … `reflection_question`, incl. `hindi_meaning_note` | same names | `""` → NULL. Note kept separate |
| `verse.source_attributions[]` | `local_shloka_source_attributions` | id `ContentIds.attribution(…)`, `source_id` = `ContentIds.source(key)` |
| `sources[]` | `local_content_sources` | id `ContentIds.source(key)`, `""` → NULL |
| `review_status`, `schema_version` | — | import gate / format check only |
| *(none)* | `created_at`, `updated_at` | `1970-01-01T00:00:00Z` (`contentRepositoryTimestamp`), see below |

### Schema gap resolved: sources and attributions

Before this milestone the local database had no place for sources or attributions,
and `source_attributions` would have been dropped. To avoid losing information, schema
**version 2** adds two cache tables that mirror Supabase's `content_sources` and
`shloka_source_attributions`. The upgrade is additive only: a `stepByStep` migration
creates the two tables and their indexes, and it is tested with existing personal
data. See `docs/database/LOCAL_SQLITE_SCHEMA.md`.

### Timestamps

The JSON has no timestamps. Every imported row gets the fixed timestamp
`1970-01-01T00:00:00Z`:

- **idempotency:** unchanged content produces identical rows;
- **provenance:** the row came from the repository, with no server revision;
- **sync-safety:** any real Supabase row is newer, so the cache's never-go-backwards
  rule lets server content replace it later. The importer does the reverse check too: a
  cached row with any other timestamp came from the server and is **never
  overwritten** (`SERVER_RECORD_PRESENT`).

## Idempotency and updates

For every record the importer compares the target row with the cached one:

| Cached row | Action | Counted as |
|---|---|---|
| none | insert | inserted |
| identical | nothing | unchanged |
| differs, repository timestamp | update in place (same id) | updated |
| differs, server timestamp | skip | skipped `SERVER_RECORD_PRESENT` |
| a different id occupies the chapter/verse slot | skip | skipped `VERSE_SLOT_TAKEN` |

Attributions are made to match the file. Missing ones are inserted and removed ones
are deleted. They are shared content, never personal data.

Re-importing unchanged files reports every record as `unchanged` and writes nothing.

**Verses are never deleted.** A verse removed from the JSON stays in the cache, together
with the personal data attached to it. Retiring a verse is a server-side soft delete,
the sync milestone's job.

## Personal data

The importer reads and writes only `local_chapters`, `local_shlokas`,
`local_content_sources` and `local_shloka_source_attributions`. It never touches
reflections, notes, bookmarks, reading progress, reading history or settings:

- nothing cascades (every foreign key is RESTRICT);
- nothing is dropped or recreated;
- importing never logs reading activity.

`test/unit/data/content/personal_data_protection_test.dart` snapshots every personal
table and asserts it is identical after an update, repeated imports in both modes, a
failed import, and the removal of a verse from the files.

## Transactions and failures

- Sources are imported in one transaction, and each chapter (row, verses and
  attributions) in its own transaction.
- If a chapter fails, its transaction rolls back completely (no partial chapter), the
  failure is recorded as `ImportFailure(transaction: 'chapter N', fileName, error)`, and
  the other chapters still import.
- Counts are added to the result only after a commit.

## ImportResult

`mode`, `startedAt`, `completedAt`, `totalFilesDiscovered`, `chaptersProcessed`,
`versesProcessed`, and per-kind counts (`chapters`, `verses`, `sources`: inserted /
updated / unchanged / skipped / failed). Also `attributionsInserted` and
`attributionsDeleted`, `skipped` (record, reason code, message), `failures`, the
validation errors and warnings, and `shlokaIds` (content id → UUID). It provides
`toJson()` and `toReport()`.

| `status` | When |
|---|---|
| `succeeded` | Validation passed in the mode used, and nothing was skipped or failed |
| `completedWithRejections` | No failures, but validation errors or skipped records |
| `failed` | A transaction failed, or files were unusable (invalid JSON, schema errors, missing files) |

`isSuccess` is true only for `succeeded`. An import is never reported as successful
when validation failed.

Skip reasons: `FILE_INVALID`, `VALIDATION_FAILED`, `CHAPTER_NAMES_MISSING`,
`SERVER_RECORD_PRESENT`, `VERSE_SLOT_TAKEN`, `UNVERIFIED_SOURCE` and
`SOURCES_UNAVAILABLE`.

## Running an import

From code (for example a future developer screen, or a test):

```dart
final content = ref.read(contentRepositoryProvider);   // bundled assets + app DB

final draft = await content.importDraft();             // local development only
print(draft.toReport());

final approved = await content.importApproved(chapterIds: [1]);
if (!approved.isSuccess) print(approved.toJson());
```

Against a throwaway database (as the tests do):

```dart
final db = AppDatabase(NativeDatabase.memory());
final result = await ContentImportService(
  source: FileSystemContentSource(),       // or AssetBundleContentSource()
  database: db,
).importContent(mode: ImportMode.draft);
```

There is no CLI for importing on purpose. The CLI is validation-only, so it can never
write to a real device database.

### Current results (real repository, test database)

| Import | Result |
|---|---|
| Draft | `succeeded`: 18 chapters and 1 verse (1.41, UUID `8c555087-…`) inserted. Re-import: 18 + 1 unchanged |
| Approved | `completedWithRejections`, with nothing imported: no chapter has names, and 1.41 is a `draft` |

## Tests

```sh
flutter test test/unit/data/content     # parsing, schema, semantics, import, personal data, assets
flutter test test/drift                 # schema snapshots and v1 → v2 migration
```
