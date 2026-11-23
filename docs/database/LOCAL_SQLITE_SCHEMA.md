# Gitartha — Local SQLite Schema (specification)

This is the **design** for the on-device SQLite database, to be implemented later with
Drift. No Dart or Drift code exists yet. The SQL below is the reference DDL that the
Drift table definitions should produce.

## Ground rules

1. **Personal data never leaves the device.** `reflections`, `personal_notes`,
   `bookmarks`, `reading_progress`, `reading_history` and `local_settings` are never sent
   to Supabase, never included in a sync request and never written to analytics or logs.
2. **The cache mirrors Supabase.** `local_chapters` and `local_shlokas` keep the Supabase
   ids (chapter numbers and verse UUIDs) and the same field names, so the sync code is a
   plain upsert.
3. **Cached verses are never physically deleted.** A verse that is soft-deleted on the
   server keeps its local row with `deleted_at` set. Personal rows reference cached
   verses by foreign key, so a user's reflections stay attached to the verse they wrote
   them about, even after it is retired.
4. **Foreign keys are on.** SQLite enforces foreign keys only after
   `PRAGMA foreign_keys = ON`. Run it on every connection (Drift: in `beforeOpen`).
5. **Timestamps** are `TEXT` in ISO 8601 UTC with milliseconds, for example
   `2026-11-23T14:05:09.123Z`. This matches the requested types, sorts correctly as
   text, and is the format Supabase returns. (Drift: set
   `store_date_time_values_as_text: true` in `build.yaml`, or use text columns.)
6. **Ids** for personal rows are UUID v4 strings generated on the device.

## Tables at a glance

| Table | Group | Rows per verse | Synced? |
|---|---|---|---|
| `local_chapters` | Cache | — | Pulled from Supabase |
| `local_shlokas` | Cache | 1 | Pulled from Supabase |
| `sync_state` | Cache bookkeeping | — | Local only |
| `reflections` | Personal | **0..N** (dated entries) | **Never** |
| `personal_notes` | Personal | 0..N | **Never** |
| `bookmarks` | Personal | 0..1 | **Never** |
| `reading_progress` | Personal | 0..5 (one per state) | **Never** |
| `reading_history` | Personal | 0..N (log) | **Never** |
| `local_settings` | Personal | — | **Never** |

```text
local_chapters 1 ──< local_shlokas 1 ──< reflections
                                     ├──< personal_notes
                                     ├──o bookmarks          (unique per shloka)
                                     ├──< reading_progress   (unique per shloka+state)
                                     └──< reading_history
```

---

## Cache tables

### `local_chapters`

```sql
CREATE TABLE local_chapters (
  id             INTEGER PRIMARY KEY CHECK (id BETWEEN 1 AND 18),  -- = chapters.id
  sanskrit_name  TEXT NOT NULL,
  hindi_name     TEXT NOT NULL,
  english_name   TEXT NOT NULL,
  introduction   TEXT,
  overview       TEXT,
  central_theme  TEXT,
  key_topics     TEXT,            -- JSON array of strings, e.g. '["Duty","Grief"]'
  summary        TEXT,
  conclusion     TEXT,
  created_at     TEXT NOT NULL,   -- copied from server
  updated_at     TEXT NOT NULL,   -- copied from server; drives sync comparisons
  deleted_at     TEXT             -- server tombstone; NULL = live
);

CREATE INDEX local_chapters_live_idx ON local_chapters (id) WHERE deleted_at IS NULL;
```

Reading screens query `WHERE deleted_at IS NULL`. Verse counts are derived:
`SELECT count(*) FROM local_shlokas WHERE chapter_id = ? AND deleted_at IS NULL`.

### `local_shlokas`

```sql
CREATE TABLE local_shlokas (
  id                   TEXT PRIMARY KEY,               -- = shlokas.id (UUID)
  chapter_id           INTEGER NOT NULL
                         REFERENCES local_chapters (id) ON DELETE RESTRICT,
  verse_number         INTEGER NOT NULL CHECK (verse_number > 0),
  reference            TEXT NOT NULL,                  -- e.g. '2.47' (copied, not computed)
  index_title          TEXT,
  index_summary        TEXT,
  sanskrit_text        TEXT,
  transliteration      TEXT,
  hindi_meaning        TEXT,
  hindi_meaning_note   TEXT,
  english_meaning      TEXT,
  context              TEXT,
  life_lesson          TEXT,
  spiritual_meaning    TEXT,
  reflection_question  TEXT,
  created_at           TEXT NOT NULL,
  updated_at           TEXT NOT NULL,
  deleted_at           TEXT
);

-- Chapter navigation and verse lookup.
CREATE INDEX local_shlokas_chapter_verse_idx ON local_shlokas (chapter_id, verse_number);
CREATE INDEX local_shlokas_reference_idx     ON local_shlokas (reference);
```

`(chapter_id, verse_number)` is deliberately **not** `UNIQUE` locally. The server
enforces uniqueness, and a single sync batch can renumber two verses (A → 5, B → 6).
SQLite would reject the intermediate state of such a batch because its unique
constraints cannot be deferred. Readers should still treat the pair as unique among
live rows.

A future FTS5 virtual table for offline search should index the text columns of live
rows. That belongs to the search milestone.

### `sync_state`

This table is an addition to the original brief. It stores a cursor per synced entity,
so sync can resume after an interruption.

```sql
CREATE TABLE sync_state (
  entity                   TEXT PRIMARY KEY
                             CHECK (entity IN ('chapters', 'shlokas')),
  cursor_updated_at        TEXT,   -- server updated_at of the last applied row
  cursor_id                TEXT,   -- tie-breaker: id of that row
  last_successful_sync_at  TEXT    -- device clock, for display ("Updated 2 h ago")
);
```

How the cursor is used: [`SYNC_STRATEGY.md`](SYNC_STRATEGY.md).

---

## Personal tables (local only)

Personal rows reference `local_shlokas(id)` with `ON DELETE RESTRICT`. Because cached
verses are never physically deleted (rule 3), this never blocks sync. It turns an
accidental cache purge into a visible error instead of silent data loss.

### `reflections`: personal answers to reflection questions

**Many reflections per verse.** Each answer is its own dated entry. Writing a new answer
never overwrites an old one.

```sql
CREATE TABLE reflections (
  id             TEXT PRIMARY KEY,                    -- UUID v4, generated on device
  shloka_id      TEXT NOT NULL
                   REFERENCES local_shlokas (id) ON DELETE RESTRICT,
  answer         TEXT NOT NULL CHECK (length(trim(answer)) > 0),
  question_text  TEXT,   -- recommended: snapshot of reflection_question when answered
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  CHECK (updated_at >= created_at)
);

-- "All my reflections on this verse, newest first", with no uniqueness on shloka_id.
CREATE INDEX reflections_shloka_created_idx ON reflections (shloka_id, created_at DESC);
-- Journal-style timeline across all verses.
CREATE INDEX reflections_created_idx        ON reflections (created_at DESC);
```

Behaviour:

| Action | SQL shape | Effect |
|---|---|---|
| New answer | `INSERT` with a new UUID, `created_at = updated_at = now` | Always a new row. Never an upsert keyed on `shloka_id` |
| Edit an answer | `UPDATE reflections SET answer = ?, updated_at = now WHERE id = ?` | Only that entry changes. `created_at` is kept |
| Delete an answer | `DELETE FROM reflections WHERE id = ?` | Only that entry is removed |

**Example.** A user answers the question for Chapter 1, Verse 40 on 2026-11-23. Six
months later they revisit it and write a new answer:

```text
id        shloka_id   created_at                 answer
--------  ----------  -------------------------  -----------------------------
7f3c…     <uuid 1.40> 2026-11-23T09:12:00.000Z   "Right now I feel…"
b81e…     <uuid 1.40> 2027-05-24T18:40:00.000Z   "Looking back, I see…"
```

Both entries remain and are listed by date.

`question_text` is optional but recommended. The shared `reflection_question` can be
reworded later on the server, and a snapshot keeps each old answer next to the question
it was actually answering.

`updated_at` must be set by the app's data layer on every edit, not by the UI. A
SQLite trigger can do it as a safety net:

```sql
CREATE TRIGGER reflections_touch AFTER UPDATE OF answer ON reflections
FOR EACH ROW WHEN NEW.updated_at = OLD.updated_at
BEGIN
  UPDATE reflections
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
```

The same pattern applies to `personal_notes` and `bookmarks`.

### `personal_notes`

Multiple private notes per verse.

```sql
CREATE TABLE personal_notes (
  id          TEXT PRIMARY KEY,                       -- UUID v4
  shloka_id   TEXT NOT NULL
                REFERENCES local_shlokas (id) ON DELETE RESTRICT,
  body        TEXT NOT NULL CHECK (length(trim(body)) > 0),
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  CHECK (updated_at >= created_at)
);

CREATE INDEX personal_notes_shloka_updated_idx ON personal_notes (shloka_id, updated_at DESC);
```

### `bookmarks`

A saved verse with an optional label. Each verse can be bookmarked at most once, and the
label can be edited.

```sql
CREATE TABLE bookmarks (
  id          TEXT PRIMARY KEY,                       -- UUID v4
  shloka_id   TEXT NOT NULL UNIQUE
                REFERENCES local_shlokas (id) ON DELETE RESTRICT,
  label       TEXT CHECK (label IS NULL OR length(trim(label)) > 0),
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

CREATE INDEX bookmarks_created_idx ON bookmarks (created_at DESC);
```

Removing a bookmark deletes its row. The `UNIQUE` constraint on `shloka_id` also serves
as its index.

### `reading_progress`

Progress is a set of **independent milestones** per verse, not one linear status.
Opening a verse records `opened` only. It never implies `read`, `studied` or
`reflected`. The app records each state explicitly:

| State | Recorded when (suggested) |
|---|---|
| `opened` | The verse screen is shown |
| `read` | The user scrolls through the meanings, or taps "Mark as read" |
| `studied` | The user opens the context, life lesson and spiritual meaning, or taps "Mark as studied" |
| `reflected` | The user saves a reflection for this verse |
| `bookmarked` | The user bookmarks the verse (a milestone: "has been bookmarked") |

```sql
CREATE TABLE reading_progress (
  shloka_id          TEXT NOT NULL
                       REFERENCES local_shlokas (id) ON DELETE RESTRICT,
  state              TEXT NOT NULL
                       CHECK (state IN ('opened', 'read', 'studied', 'reflected', 'bookmarked')),
  first_recorded_at  TEXT NOT NULL,
  last_recorded_at   TEXT NOT NULL,
  PRIMARY KEY (shloka_id, state),
  CHECK (last_recorded_at >= first_recorded_at)
) WITHOUT ROWID;

-- "How many verses have I studied in chapter N": join to local_shlokas.
CREATE INDEX reading_progress_state_idx ON reading_progress (state, shloka_id);
```

Record a state with an upsert:

```sql
INSERT INTO reading_progress (shloka_id, state, first_recorded_at, last_recorded_at)
VALUES (?, 'studied', :now, :now)
ON CONFLICT (shloka_id, state) DO UPDATE SET last_recorded_at = excluded.last_recorded_at;
```

The `bookmarked` milestone means the verse has been bookmarked at some point. Whether it
is bookmarked *right now* is answered only by `bookmarks`.

### `reading_history`

An append-only log of reading activity (continue reading, recent verses, streaks).

```sql
CREATE TABLE reading_history (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  shloka_id         TEXT NOT NULL
                      REFERENCES local_shlokas (id) ON DELETE RESTRICT,
  opened_at         TEXT NOT NULL,
  duration_seconds  INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0)
);

CREATE INDEX reading_history_opened_idx ON reading_history (opened_at DESC);
CREATE INDEX reading_history_shloka_idx ON reading_history (shloka_id, opened_at DESC);
```

The log grows without bound. Prune it periodically, for example by keeping the last
365 days or the last 5,000 rows. Pruning `reading_history` never changes
`reading_progress`.

### `local_settings`

Key/value preferences.

```sql
CREATE TABLE local_settings (
  key         TEXT PRIMARY KEY,
  value       TEXT NOT NULL,      -- JSON-encoded value
  updated_at  TEXT NOT NULL
) WITHOUT ROWID;
```

Suggested keys: `theme` (`"system"|"light"|"dark"`), `sanskrit_font_scale`,
`body_font_scale`, `show_transliteration`, `show_hindi`, `show_english`, and
`last_opened_shloka_id`. Every value is JSON (`1.2`, `true`, `"dark"`), so types round-trip
correctly.

Authentication tokens are **not** stored here. The Supabase SDK keeps the session in
secure storage.

---

## What is intentionally absent

- No `user_id` column on personal tables. The database belongs to one person on one
  device, and the absence of a user id is a reminder that these rows are never uploaded.
- No server ids or "synced" flags on personal tables, because they are never synced.
- No local copy of `app_members`. The edit permission is fetched live when needed (see
  `SYNC_STRATEGY.md`) and may be held in memory.
- Sources and attributions are not cached yet. Whether they must display offline is an
  open decision (`DATABASE_ARCHITECTURE.md` → "Open decisions").

## Device-level concerns

- Personal data is lost if the app is uninstalled or the device is lost, unless a local
  export feature is added. That is a deliberate product decision.
- If the device needs stronger protection, consider SQLCipher (`sqlcipher_flutter_libs`)
  in place of the bundled SQLite.
- Exclude the database from any analytics or crash-report attachments.
