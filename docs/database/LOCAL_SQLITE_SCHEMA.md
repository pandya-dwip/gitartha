# Gitartha — Local SQLite Schema

The on-device database, as implemented in Milestone 2 with Drift. The source of truth
is the Dart code in [`lib/data/local/database/tables/`](../../lib/data/local/database/tables/)
and the exported snapshot in
[`drift_schemas/app_database/drift_schema_v1.json`](../../drift_schemas/app_database/drift_schema_v1.json).
This document explains that schema. If the two ever disagree, the code wins.

- **File:** `gitartha.sqlite` in the app's documents directory.
- **Schema version:** 1.
- **Engine:** SQLite, bundled by `sqlite3` through `drift_flutter`.

How the code is organised (DAOs, repository, initialization, migrations) is described in
[`LOCAL_DATABASE_IMPLEMENTATION.md`](LOCAL_DATABASE_IMPLEMENTATION.md). Tests are
described in [`LOCAL_DATABASE_TESTING.md`](LOCAL_DATABASE_TESTING.md).

## Ground rules

1. **Personal data never leaves the device.** `reflections`, `personal_notes`,
   `bookmarks`, `reading_progress`, `reading_history` and `local_settings` are never
   sent to Supabase. No code in this milestone talks to Supabase at all.
2. **The cache mirrors Supabase.** `local_chapters` and `local_shlokas` keep Supabase's
   ids (chapter numbers and verse UUIDs), its field names, and its `created_at`,
   `updated_at` and `deleted_at` values.
3. **Cached scripture is never physically deleted.** A server tombstone sets
   `deleted_at`. Reading queries hide those rows, but personal records stay attached to
   them.
4. **Foreign keys are always enforced.** `PRAGMA foreign_keys = ON` runs on every
   connection, and the app refuses to start if SQLite does not confirm it.
5. **All tables are `STRICT`.** SQLite rejects values of the wrong type instead of
   silently storing them.

## Conventions

### Identifiers

| Data | Id |
|---|---|
| Chapters | Supabase integer id = chapter number 1–18 |
| Shlokas | Supabase UUID, stored as TEXT, exactly as received. Never regenerated |
| Personal records | UUID v4 generated on the device (`generateUuidV4`, secure RNG) |
| Settings, sync metadata | Text key |

All UUID columns have `CHECK (length(id) = 36)`.

### Timestamps

Every timestamp is TEXT in **fixed-width UTC ISO 8601 with microseconds**:

```text
2026-11-23T09:12:00.123456Z      (always 27 characters)
```

- Written only through `UtcTimestampConverter`, which converts to UTC first. Dart code
  works with `DateTime`; the conversion is automatic.
- Fixed width means text order equals chronological order, so `ORDER BY` and range
  queries on the text are correct.
- Microsecond precision preserves Supabase `timestamptz` values exactly. The future
  sync milestone compares them as cursors.
- Convert to local time **only for display**.

### Text

- Optional content is `NULL` when it is missing.
- Personal text (`answer`, note `content`, note `title`) may not be blank:
  `CHECK (length(trim(x, ' \t\n\r')) > 0)`. The DAOs reject blank values earlier, with an
  `ArgumentError`. Text is stored as written and is not trimmed.

## Relationships

```text
local_chapters 1 ──< local_shlokas 1 ──< reflections        (0..N per shloka)
                                    ├──< personal_notes     (0..N; shloka_id nullable)
                                    ├──o bookmarks          (0..1, unique shloka_id)
                                    ├──o reading_progress   (0..1, unique shloka_id)
                                    └──< reading_history    (0..N, append-only)

local_settings, sync_metadata       standalone key/value tables
```

Every foreign key is **`ON DELETE RESTRICT`**:

- A chapter with verses cannot be deleted.
- A shloka referenced by any personal record cannot be deleted.
- Nothing cascades. No cache operation can delete a reflection, note, bookmark,
  progress record or history entry.

Because the cache is updated by upsert and soft deletion only (rule 3), RESTRICT never
blocks normal operation. It only turns a bug that would destroy personal data into an
immediate error.

---

## Cache tables

### `local_chapters`

| Column | Type | Constraints |
|---|---|---|
| `id` | INTEGER | **PK**. `CHECK (id BETWEEN 1 AND 18)` |
| `sanskrit_name` | TEXT | NOT NULL |
| `hindi_name` | TEXT | NOT NULL |
| `english_name` | TEXT | NOT NULL |
| `introduction` | TEXT | nullable |
| `overview` | TEXT | nullable |
| `central_theme` | TEXT | nullable |
| `key_topics` | TEXT | nullable. JSON array of strings, e.g. `["Duty","Grief"]` (Dart: `List<String>`) |
| `summary` | TEXT | nullable |
| `conclusion` | TEXT | nullable |
| `created_at` | TEXT | NOT NULL. Copied from Supabase |
| `updated_at` | TEXT | NOT NULL. Copied from Supabase |
| `deleted_at` | TEXT | nullable. Server tombstone |

**Indexes:** the primary key, and `local_chapters_updated_at_idx (updated_at, id)` for
sync.

The names are NOT NULL because they are NOT NULL in Supabase. A chapter row is only
ever a copy of a server row.

### `local_shlokas`

| Column | Type | Constraints |
|---|---|---|
| `id` | TEXT | **PK**. Supabase UUID |
| `chapter_id` | INTEGER | NOT NULL, FK → `local_chapters(id)` **RESTRICT** |
| `verse_number` | INTEGER | NOT NULL, `CHECK (verse_number > 0)` |
| `reference` | TEXT | NOT NULL, `CHECK (reference = chapter_id \|\| '.' \|\| verse_number)` |
| `index_title`, `index_summary` | TEXT | nullable |
| `sanskrit_text` | TEXT | nullable |
| `transliteration` | TEXT | nullable |
| `hindi_meaning` | TEXT | nullable |
| `hindi_meaning_note` | TEXT | nullable. A separate field, never merged into `hindi_meaning` |
| `english_meaning` | TEXT | nullable |
| `context`, `life_lesson`, `spiritual_meaning`, `reflection_question` | TEXT | nullable |
| `created_at`, `updated_at` | TEXT | NOT NULL. Copied from Supabase |
| `deleted_at` | TEXT | nullable. Server tombstone |

- **Unique:** `(chapter_id, verse_number)`.
- **Indexes:**
  - the unique `(chapter_id, verse_number)` constraint, which serves chapter navigation,
    verse lookup and the `chapter_id` foreign key;
  - `local_shlokas_reference_idx (reference)`;
  - `local_shlokas_updated_at_idx (updated_at, id)`, for sync.

There is no separate index on `verse_number` alone, because every verse query also
filters by chapter. There are no personal columns: answers live in `reflections`.

**"Live" content** is a shloka with `deleted_at IS NULL` **and** a chapter with
`deleted_at IS NULL`. Every reading query (chapter lists, verse lookup, search,
progress summaries) uses this definition. Lookup by id can include retired shlokas
(`includeDeleted: true`), for example to show the verse behind an old reflection.

### `sync_metadata`

| Column | Type | Constraints |
|---|---|---|
| `key` | TEXT | **PK**, not empty |
| `value` | TEXT | NOT NULL |
| `updated_at` | TEXT | NOT NULL |

Reserved keys (`SyncMetadataKeys`) are `last_successful_content_sync_at`,
`content_sync_state` and `content_cursor.<table>`. The table is empty until the sync
milestone. Nothing writes to it yet.

---

## Personal tables (local only)

### `reflections`: personal answers to reflection questions

| Column | Type | Constraints |
|---|---|---|
| `id` | TEXT | **PK**. Device UUID |
| `shloka_id` | TEXT | NOT NULL, FK → `local_shlokas(id)` **RESTRICT**. **Not unique** |
| `answer` | TEXT | NOT NULL, not blank |
| `created_at` | TEXT | NOT NULL |
| `updated_at` | TEXT | NOT NULL, `CHECK (updated_at >= created_at)` |

**Indexes:**

- `reflections_shloka_created_idx (shloka_id, created_at)`: all reflections on a verse,
  in chronological order;
- `reflections_created_idx (created_at)`: recent reflections across all verses.

How reflections behave:

| Action | Effect |
|---|---|
| Answer a question (again) | **New row**, new id. Older answers are never touched |
| Edit an answer | Updates `answer` and `updated_at` of **that row only**. `created_at` is kept |
| Delete an answer | Deletes that row only |
| Read | `getReflectionsForShloka`: oldest first (ties in insertion order). `getRecentReflections`: newest first |

Example: a user answers 1.40 on 2026-11-23, then again six months later. Two rows
exist, each with its own date, and both are listed.

If the device clock moves backwards, `updated_at` is clamped to `created_at`, so an
edit can never break the CHECK.

### `personal_notes`

| Column | Type | Constraints |
|---|---|---|
| `id` | TEXT | **PK**. Device UUID |
| `shloka_id` | TEXT | **nullable**, FK → `local_shlokas(id)` **RESTRICT**. NULL = a note not about any verse |
| `title` | TEXT | nullable. Not blank if present (blank input is stored as NULL) |
| `content` | TEXT | NOT NULL, not blank |
| `created_at`, `updated_at` | TEXT | NOT NULL, `updated_at >= created_at` |

**Indexes:** `personal_notes_shloka_updated_idx (shloka_id, updated_at)` and
`personal_notes_updated_idx (updated_at)`. There can be any number of notes per verse.
Lists are ordered by most recently edited.

### `bookmarks`

| Column | Type | Constraints |
|---|---|---|
| `id` | TEXT | **PK**. Device UUID |
| `shloka_id` | TEXT | NOT NULL, **UNIQUE**, FK → `local_shlokas(id)` **RESTRICT** |
| `created_at` | TEXT | NOT NULL |

**Index:** `bookmarks_created_idx (created_at)`, for listing newest first. The UNIQUE
constraint indexes `shloka_id`.

`addBookmark` is idempotent: bookmarking an already bookmarked verse returns the
existing bookmark. Removing a bookmark deletes the row.

### `reading_progress`

| Column | Type | Constraints |
|---|---|---|
| `id` | TEXT | **PK**. Device UUID |
| `shloka_id` | TEXT | NOT NULL, **UNIQUE**, FK → `local_shlokas(id)` **RESTRICT** |
| `status` | TEXT | NOT NULL, `CHECK (status IN ('opened','read','studied','reflected'))` |
| `first_opened_at` | TEXT | NOT NULL. Never changes after creation |
| `last_opened_at` | TEXT | NOT NULL, `CHECK (last_opened_at >= first_opened_at)` |
| `studied_at` | TEXT | nullable. Set the first time the verse is marked studied |
| `reflected_at` | TEXT | nullable. Set the first time the verse is marked reflected |
| `updated_at` | TEXT | NOT NULL |

There is one row per verse. The status is the **furthest level reached**
(`opened < read < studied < reflected`), and all transitions are explicit:

| Operation | Effect |
|---|---|
| Open the verse (`recordShlokaOpened`) | Creates the row as `opened`, or only updates `last_opened_at`. **Never** changes the status, so opening does not mean studied |
| Mark `read` / `studied` / `reflected` (`markShloka`) | Status becomes at least that level. It never moves backwards. Sets `studied_at` / `reflected_at` the first time |
| Mark an unopened verse | Creates the row (first/last opened = now) at the marked level |

Bookmarking is not a reading status. It lives only in `bookmarks`. Saving a reflection
does not mark the verse `reflected` by itself; the feature code decides whether to call
`markShloka`.

### `reading_history`

| Column | Type | Constraints |
|---|---|---|
| `id` | TEXT | **PK**. Device UUID |
| `shloka_id` | TEXT | NOT NULL, FK → `local_shlokas(id)` **RESTRICT** |
| `action` | TEXT | NOT NULL, `CHECK ("action" IN ('opened','marked_read','marked_studied','marked_reflected'))` |
| `occurred_at` | TEXT | NOT NULL |

**Indexes:**

- `reading_history_shloka_occurred_idx (shloka_id, occurred_at)`: history of one verse;
- `reading_history_occurred_idx (occurred_at)`: recent activity and date ranges.

The table is append-only: rows are never updated, and there are many per verse. An
`opened` entry is written when a verse is opened, except when one was already logged for
the same verse within the last minute (`openedHistoryDedupWindow`). That stops screen
re-entries and rebuilds from flooding the log. Each explicit mark always writes its
`marked_*` entry.

### `local_settings`

| Column | Type | Constraints |
|---|---|---|
| `key` | TEXT | **PK**, not empty |
| `value` | TEXT | NOT NULL. **Always JSON**: `"dark"`, `1.25`, `true`, `{"a":1}` |
| `updated_at` | TEXT | NOT NULL |

Known keys (`LocalSettingKeys`): `theme_mode`, `sanskrit_font_scale`,
`body_font_scale`, `show_transliteration`, `show_hindi`, `show_english` and
`last_opened_shloka_id`.

Credentials are never stored here. The Supabase SDK keeps its session separately, and
secret keys never reach the app. `SettingsDao` rejects keys that look like secrets
(`password`, `token`, `secret`, `api_key`, `anon_key`, `service_role`, `jwt`, …).

---

## Changes from the pre-implementation design

The first version of this document (written with the Supabase schema) was a proposal.
The Milestone 2 specification refined it, and the implementation follows that
specification:

| Area | Earlier proposal | Implemented | Why |
|---|---|---|---|
| `personal_notes` | `body`, `shloka_id` required | `title` (optional) + `content`, `shloka_id` **nullable** | Allows free-standing notes |
| `bookmarks` | Optional `label`, `updated_at` | No label | As specified. A label can be added in a later schema version |
| `reading_progress` | One row per (shloka, state) | One row per shloka, `status` + timestamps | As specified. Simpler queries |
| `reading_history` | Autoincrement id, `duration_seconds` | UUID id, `action`, `occurred_at` | As specified. Records explicit activities |
| Sync bookkeeping | `sync_state` table (entity cursors) | `sync_metadata` key/value | As specified. Cursors become `content_cursor.<table>` keys |
| `local_shlokas (chapter_id, verse_number)` | Deliberately not unique | **UNIQUE** | As specified. See `SYNC_STRATEGY.md` for how renumbering is handled |
| Timestamp format | Millisecond precision | **Microsecond**, fixed width | Preserves Supabase timestamps exactly, and keeps text order chronological |
| FTS5 search | Mentioned for later | `LIKE` search | Enough for 700 verses. FTS5 belongs to the search milestone |
