# Gitartha — Supabase Tables Reference

Source of truth: [`supabase/migrations/0001_initial_schema.sql`](../../supabase/migrations/0001_initial_schema.sql).
If this document and the SQL ever disagree, the SQL wins. Update this file whenever you
add a migration.

All tables live in the `public` schema. The database encoding is UTF-8, so every `text`
column stores Devanagari (Sanskrit and Hindi) and IAST transliteration as-is.

Conventions used everywhere:

- **Timestamps** are `timestamptz` and are stored in UTC. `created_at` and `updated_at`
  are written by a trigger and never by the client (see [Triggers](#triggers)).
- **"Not written yet" is `NULL`, never `''`.** Optional text columns have a CHECK
  constraint that rejects empty or whitespace-only strings, so there is one way to say
  "missing". Clients should send `null` for blank form fields.
- **Soft delete:** `deleted_at IS NULL` means the row is live. A non-null value is a
  tombstone. Tombstones remain readable so sync can propagate them.

---

## 1. `app_members`

Authorized members and their individual edit permission. Authentication itself (email,
password, sessions) lives in Supabase's `auth.users`. This table stores no credentials.

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `user_id` | `uuid` | NOT NULL | — | PK. FK → `auth.users(id)` **ON DELETE CASCADE** |
| `is_accessible` | `boolean` | NOT NULL | `false` | Edit permission for shared content |
| `created_at` | `timestamptz` | NOT NULL | `now()` | Trigger-managed |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | Trigger-managed |

- **Constraints:** `app_members_pkey (user_id)` and `app_members_user_id_fkey`.
- **Population:** rows are created by the `on_auth_user_created_provision_membership`
  trigger, which always sets `is_accessible = false`. The migration also backfills users
  who already existed. Anonymous users are skipped.
- **Why CASCADE is safe:** nothing references `app_members`, so removing an auth user
  can only remove their membership row and never any content.
- **Client access:** `SELECT` on their own row only. No insert, update or delete for
  anyone except the owner and the service role.

## 2. `chapters`

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `bigint` | NOT NULL | — | PK. **The chapter number.** CHECK 1–18. Immutable |
| `sanskrit_name` | `text` | NOT NULL | — | Not blank |
| `hindi_name` | `text` | NOT NULL | — | Not blank |
| `english_name` | `text` | NOT NULL | — | Not blank |
| `introduction` | `text` | null | — | Not blank if present |
| `overview` | `text` | null | — | Not blank if present |
| `central_theme` | `text` | null | — | Not blank if present |
| `key_topics` | `text[]` | null | — | Ordered. Array elements may not be NULL |
| `summary` | `text` | null | — | Not blank if present |
| `conclusion` | `text` | null | — | Not blank if present |
| `created_at` | `timestamptz` | NOT NULL | `now()` | Trigger-managed |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | Trigger-managed |
| `deleted_at` | `timestamptz` | null | — | Soft-delete tombstone |

- **Constraints:** `chapters_pkey`, `chapters_id_range_check (id BETWEEN 1 AND 18)`,
  `chapters_*_not_blank`, `chapters_key_topics_no_nulls`.
- **Indexes:** `chapters_pkey (id)` and `chapters_updated_at_id_idx (updated_at, id)`
  for sync.
- **No `verse_count`.** It is derived:
  `SELECT chapter_id, count(*) FROM shlokas WHERE deleted_at IS NULL GROUP BY chapter_id`
  (or the same query on the local cache).
- **Exactly 18.** The id range check together with the primary key means there can
  never be more than 18 chapters. Fewer is allowed, so the table can start empty.

## 3. `shlokas`

Columns are listed in the app's reading order.

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK. **Immutable** stable sync key |
| `chapter_id` | `bigint` | NOT NULL | — | FK → `chapters(id)` ON UPDATE/DELETE **RESTRICT** |
| `verse_number` | `integer` | NOT NULL | — | CHECK `> 0` |
| `reference` | `text` | (generated) | — | `GENERATED ALWAYS AS (chapter_id || '.' || verse_number) STORED`, e.g. `2.47`. Read-only |
| `index_title` | `text` | null | — | Title shown in the chapter's verse index |
| `index_summary` | `text` | null | — | Summary shown in the verse index |
| `sanskrit_text` | `text` | null | — | 1. Sanskrit |
| `transliteration` | `text` | null | — | 2. Pronunciation |
| `hindi_meaning` | `text` | null | — | 3. Hindi meaning |
| `hindi_meaning_note` | `text` | null | — | Optional historical, linguistic or interpretive clarification shown with the Hindi meaning |
| `english_meaning` | `text` | null | — | 4. English meaning |
| `context` | `text` | null | — | 5. Context: what is happening here? |
| `life_lesson` | `text` | null | — | 6. Life lesson |
| `spiritual_meaning` | `text` | null | — | 7. Spiritual meaning |
| `reflection_question` | `text` | null | — | 8. Shared reflection prompt |
| `created_at` | `timestamptz` | NOT NULL | `now()` | Trigger-managed |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | Trigger-managed |
| `deleted_at` | `timestamptz` | null | — | Soft-delete tombstone |

- **Constraints:**
  - `shlokas_pkey (id)`
  - `shlokas_chapter_id_fkey` (RESTRICT: deleting a chapter never cascades to its verses)
  - `shlokas_verse_number_positive`
  - `shlokas_chapter_verse_key UNIQUE (chapter_id, verse_number)`
  - `shlokas_*_not_blank` on every text field
- **Indexes:**
  - `shlokas_pkey (id)`: verse lookup by UUID.
  - `shlokas_chapter_verse_key (chapter_id, verse_number)`: chapter navigation
    (`WHERE chapter_id = ? ORDER BY verse_number`) and lookup by reference. It also
    covers the `chapter_id` foreign key.
  - `shlokas_updated_at_id_idx (updated_at, id)`: incremental sync.
- **No personal columns.** There is no `answer`, `user_answer` or `reflection_response`
  column. Answers are local-only (`reflections` in SQLite).
- **Nullable content fields.** Verses can be inserted first and filled in later. A
  complete verse has all eight reading-order fields set (`hindi_meaning_note` is optional and
  not required for completeness). Check for gaps with:
  `SELECT reference FROM shlokas WHERE deleted_at IS NULL AND (sanskrit_text IS NULL OR english_meaning IS NULL …)`.
- **700 verses.** This is a content target, not a constraint. The table can start empty.
  There is no upper bound on `verse_number`, because editions differ (see "Open
  decisions" in the architecture doc).
- **Moving a verse.** Editors may correct `chapter_id` or `verse_number`. The UUID and
  `reference` stay consistent automatically.

## 4. `content_sources`

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK. Immutable |
| `name` | `text` | NOT NULL | — | Not blank. Example: the title of a translation |
| `author` | `text` | null | — | Translator, commentator or editor |
| `source_url` | `text` | null | — | Must start with `http://` or `https://` |
| `license` | `text` | null | — | Licence or permission terms. **NULL = not yet verified** |
| `attribution` | `text` | null | — | Exact credit text to display |
| `created_at` | `timestamptz` | NOT NULL | `now()` | Trigger-managed |
| `updated_at` | `timestamptz` | NOT NULL | `now()` | Trigger-managed |
| `deleted_at` | `timestamptz` | null | — | Soft-delete tombstone |

- **Constraints:** `content_sources_pkey`, `content_sources_name_not_blank`,
  `content_sources_*_not_blank`, `content_sources_source_url_http`.
- **Indexes:** `content_sources_pkey (id)` and
  `content_sources_updated_at_id_idx (updated_at, id)`.
- **Licensing.** Do not assume any source is reusable. Record the licence or written
  permission before importing content from a source. Names are deliberately not unique,
  because two editions of the same work can have the same title.

## 5. `shloka_source_attributions`

Maps one section of one verse to one source. Rows are **immutable**: to change a mapping,
delete it and insert a new one.

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | NOT NULL | `gen_random_uuid()` | PK |
| `shloka_id` | `uuid` | NOT NULL | — | FK → `shlokas(id)` ON UPDATE/DELETE **RESTRICT** |
| `source_id` | `uuid` | NOT NULL | — | FK → `content_sources(id)` ON UPDATE/DELETE **RESTRICT** |
| `content_section` | `text` | NOT NULL | — | One of the nine values below |
| `created_at` | `timestamptz` | NOT NULL | `now()` | |

`content_section` CHECK values, which match the `shlokas` column names: `sanskrit_text`,
`transliteration`, `hindi_meaning`, `hindi_meaning_note`, `english_meaning`, `context`, `life_lesson`,
`spiritual_meaning`, `reflection_question`.

- **Constraints:**
  - `shloka_source_attributions_pkey`
  - both foreign keys
  - `shloka_source_attributions_content_section_check`
  - `shloka_source_attributions_mapping_key UNIQUE (shloka_id, source_id, content_section)`:
    no duplicate mappings
- **Indexes:**
  - `shloka_source_attributions_mapping_key`: its leading column covers the `shloka_id`
    foreign key and "all attributions for this verse".
  - `shloka_source_attributions_source_id_idx (source_id)`: covers the `source_id`
    foreign key.
  - `shloka_source_attributions_created_at_id_idx (created_at, id)`: time-ordered pulls.
- **Why no `updated_at` / `deleted_at`:** the specification defines only `created_at`.
  Because the rows are immutable, an `updated_at` would add nothing. Physical deletes
  are allowed for editors. See `SYNC_STRATEGY.md` for how devices handle that.
- **Why RESTRICT:** an attribution can never silently disappear because a verse or source
  was purged. An administrator purging content must remove the attributions first, and
  that has to be a deliberate act.

---

## Relationships

```text
auth.users 1 ──── 0..1 app_members          (CASCADE)
chapters   1 ──── 0..N shlokas              (RESTRICT)
shlokas    1 ──── 0..N shloka_source_attributions (RESTRICT)
content_sources 1 ── 0..N shloka_source_attributions (RESTRICT)
```

No foreign key can delete scripture content through a cascade.

## Triggers

| Trigger | Table | When | Function | Effect |
|---|---|---|---|---|
| `*_set_timestamps` | `app_members`, `chapters`, `shlokas`, `content_sources` | BEFORE INSERT OR UPDATE | `set_row_timestamps()` | INSERT: `created_at = updated_at = now()`. UPDATE: keep `created_at`, set `updated_at = now()` |
| `*_reject_id_change` | `chapters`, `shlokas`, `content_sources` | BEFORE UPDATE WHEN `old.id IS DISTINCT FROM new.id` | `reject_id_change()` | Raises an error. Ids are permanent sync keys |
| `on_auth_user_created_provision_membership` | `auth.users` | AFTER INSERT | `handle_new_auth_user()` | Inserts `app_members (user_id, false)` for non-anonymous users |

`now()` is the transaction start time, so every row written in one transaction (for
example a seed import) gets the same `updated_at`. `SYNC_STRATEGY.md` explains why that
is fine for sync.

## Functions

| Function | Security | Callable by | Purpose |
|---|---|---|---|
| `is_app_member()` | INVOKER | `authenticated`, `service_role` | Caller has a membership row (and is not anonymous) |
| `can_edit_shared_content()` | INVOKER | `authenticated`, `service_role` | Caller's own `is_accessible` is true (and not anonymous) |
| `set_row_timestamps()` | INVOKER | triggers only | Timestamp maintenance |
| `reject_id_change()` | INVOKER | triggers only | Id immutability |
| `handle_new_auth_user()` | **DEFINER** | triggers only | Membership provisioning |

Security rationale for each function: [`RLS_SECURITY.md`](RLS_SECURITY.md).
