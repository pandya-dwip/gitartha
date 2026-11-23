# Gitartha — Database Architecture

Gitartha keeps data in two places, and the split between them is the central design
decision:

| | Supabase (PostgreSQL) | On-device SQLite (Drift) |
|---|---|---|
| **Holds** | Shared scripture content and who may edit it | A cache of that content, plus **all personal data** |
| **Written by** | Members whose `is_accessible = true`, and the project owner | The app, on behalf of the one person using the device |
| **Read by** | Every authorized member, during sync | The app's screens. Every screen reads from here. |
| **Leaves the device?** | Not applicable | **Never.** Personal data is not uploaded. |
| **Defined in** | [`supabase/migrations/0001_initial_schema.sql`](../../supabase/migrations/0001_initial_schema.sql) | [`lib/data/local/`](../../lib/data/local/) (Drift), explained in [`LOCAL_SQLITE_SCHEMA.md`](LOCAL_SQLITE_SCHEMA.md) |

```text
                    ┌──────────────────────────── Supabase ─────────────────────────────┐
                    │  auth.users ──1:1──► app_members (is_accessible)                  │
                    │                                                                   │
                    │  chapters ──1:N──► shlokas ──1:N──► shloka_source_attributions    │
                    │                                            ▲                      │
                    │                         content_sources ───┘ 1:N                  │
                    │                                                                   │
                    │  RLS on every table · anon role has no privileges                 │
                    └───────────────────────────────▲───────────────────────────────────┘
                                                    │  pull-only sync (HTTPS, user JWT)
                                                    │  chapters + shlokas changed since cursor
┌───────────────────────────────── Device (SQLite / Drift) ─────────────────────────────────┐
│  CACHE (mirrors Supabase)              PERSONAL (local only, never synced)                │
│  local_chapters ──1:N──► local_shlokas ◄── reflections      (many per shloka, dated)      │
│                                        ◄── personal_notes   (many per shloka)             │
│                                        ◄── bookmarks        (one per shloka)              │
│                                        ◄── reading_progress (one per shloka, status)      │
│                                        ◄── reading_history  (activity log)                │
│  sync_metadata (cursors)                   local_settings   (theme, font size, …)         │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

## Why the split

1. **Privacy.** Reflection answers, notes and bookmarks can be deeply personal. If they
   are never sent to a server, a server breach, a misconfigured policy or a legal request
   cannot expose them. The Supabase schema has no table or column for personal data, and
   the test suite checks this.
2. **Offline-first reading.** Scripture is read from SQLite, so the app works with no
   network. Supabase is only the source the cache is refreshed from.
3. **Small, predictable server surface.** The server holds about 718 content rows
   (18 chapters and 700 verses) plus sources. Five tables and a single permission flag
   are easy to reason about and to audit.

The trade-off is that personal data exists only on the device. Uninstalling the app or
losing the phone loses it, unless a local export/backup feature is added later (see
"Open decisions").

## Supabase side

### Tables

| Table | Purpose | Key |
|---|---|---|
| `app_members` | Who is authorized, and whether they may edit | `user_id` → `auth.users.id` |
| `chapters` | The 18 chapters | `id` = chapter number 1–18 |
| `shlokas` | The verses and their explanations | `id` UUID; unique `(chapter_id, verse_number)` |
| `content_sources` | Translations, commentaries and references, with licences | `id` UUID |
| `shloka_source_attributions` | Which source backs which section of which verse | `id` UUID; unique `(shloka_id, source_id, content_section)` |

Full column-level detail is in [`DATABASE_TABLES.md`](DATABASE_TABLES.md).

### Access model

There is exactly one application-level permission: `app_members.is_accessible`.

| Who | Can read shared content | Can write shared content | Can change permissions |
|---|---|---|---|
| Not signed in (`anon`) | No | No | No |
| Signed in, no `app_members` row | No | No | No |
| Member, `is_accessible = false` (the default) | Yes | No | No |
| Member, `is_accessible = true` | Yes | Yes (add, update, soft delete) | No |
| Project owner (SQL Editor) / service role | Yes | Yes | **Yes** |

PostgreSQL enforces all of this through grants, RLS policies and triggers. The Flutter
UI may hide edit buttons for convenience, but the UI is not what keeps anyone out.
Details: [`RLS_SECURITY.md`](RLS_SECURITY.md).

### Content lifecycle

- **Incremental.** Every table can start empty. Chapters and verses are added and filled
  in over time. All explanation fields are nullable.
- **Soft deletion.** Chapters, verses and sources are never physically deleted by
  clients. Setting `deleted_at` creates a *tombstone* that offline devices discover on
  their next sync.
- **Stable identifiers.** Chapter ids are the chapter numbers. Verse UUIDs never change,
  and a trigger enforces this. That matters because personal data on devices references
  them.
- **Server-owned timestamps.** `created_at` and `updated_at` are set by a trigger and
  never taken from the client, so sync cursors can be trusted.

## Device side

The SQLite database has two groups of tables:

- **Cache:** `local_chapters` and `local_shlokas` mirror the Supabase rows (same ids,
  same fields, including `deleted_at`), and `sync_metadata` stores the sync cursors.
- **Personal:** `reflections`, `personal_notes`, `bookmarks`, `reading_progress`,
  `reading_history` and `local_settings`. These reference cached verses by their
  Supabase UUID and are never uploaded.

Cached verses are **never physically deleted**, even after they are tombstoned on the
server. That keeps personal reflections attached to the verse they were written about.

See [`LOCAL_SQLITE_SCHEMA.md`](LOCAL_SQLITE_SCHEMA.md) and
[`SYNC_STRATEGY.md`](SYNC_STRATEGY.md).

## File map

```text
supabase/
├── migrations/0001_initial_schema.sql   executable schema (review, then run in SQL Editor)
├── config/DATABASE_SETUP.md             how to apply it + Auth (invite-only) settings
└── seed/README.md                       how future scripture seed data must be organized
docs/database/
├── DATABASE_ARCHITECTURE.md             this file
├── DATABASE_TABLES.md                   every table, column, constraint, index, trigger
├── RLS_SECURITY.md                      every grant/policy; granting & revoking editors
├── LOCAL_SQLITE_SCHEMA.md               on-device Drift schema (cache + personal data)
├── LOCAL_DATABASE_IMPLEMENTATION.md     Drift code layout, DAOs, repository, migrations
├── LOCAL_DATABASE_TESTING.md            how the local database is tested
└── SYNC_STRATEGY.md                     pull-based incremental sync procedure
```

## Open decisions

These are not blocking for the initial schema, but they need an owner:

1. **Offline attribution display.** Sources and attributions are stored in Supabase, but
   the specified local schema does not cache them. If licences require attribution to be
   shown next to content, and they often do, add `local_content_sources` and
   `local_shloka_source_attributions` to the local schema. See `SYNC_STRATEGY.md`.
2. **Journal.** The project brief lists "journal entries" as local data, but no separate
   table was specified. Today `reflections` (dated, many per verse) serves this need. A
   free-form journal that is not tied to a verse would need its own local table.
3. **Personal-data backup.** There is no cloud backup, by design. An on-device
   export/import (for example an encrypted file) would protect users against device loss
   without breaking the "never on our server" rule.
4. **Content audit trail.** Every editor can change or soft-delete any verse. Rely on
   Supabase backups / PITR, or add a server-side history table in a later migration.
5. **Edition differences.** Some editions number verses differently (for example
   chapter 13 has 34 or 35 verses). The schema only requires positive verse numbers, so
   whichever edition is chosen fits. Pick one canonical edition before seeding.
