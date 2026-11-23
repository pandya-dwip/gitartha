# Gitartha — Pull-Based Synchronization Strategy

This is the design only. No sync code, Edge Functions or realtime subscriptions exist,
and none are planned for this stage.

## Principles

- **Pull only.** The device downloads shared content. It never uploads anything.
  Personal data is not part of sync in any form.
- **The cache is the reading source.** Screens read from SQLite. Sync only refreshes the
  cache, so the app works fully offline after the first sync.
- **Incremental.** Each run fetches only rows changed since the last run, using the
  server's `updated_at`.
- **Tombstones, not gaps.** Deletions arrive as rows with `deleted_at` set. A row that
  simply stops appearing means nothing.
- **Idempotent.** Applying the same rows twice gives the same result, so overlapping
  windows and retries are safe.

## What the server guarantees

These guarantees come from [`0001_initial_schema.sql`](../../supabase/migrations/0001_initial_schema.sql):

| Guarantee | Enforced by |
|---|---|
| Every insert and update (including soft delete and restore) sets `updated_at = now()` on the server | `set_row_timestamps()` trigger. Client-supplied values are ignored |
| Chapter ids and verse UUIDs never change | `reject_id_change()` trigger |
| `(chapter_id, verse_number)` is unique | `shlokas_chapter_verse_key` |
| Chapters, verses and sources are never physically deleted by clients | No DELETE grant. Soft delete only |
| Members can read tombstones | SELECT policies do not filter `deleted_at` |
| Changed rows can be listed cheaply in a stable order | `(updated_at, id)` indexes |

## The sync procedure

### 1. Read cached scripture from SQLite

On launch, render from `local_chapters` / `local_shlokas` (`WHERE deleted_at IS NULL`)
straight away. Never block reading on the network. If the cache is empty (first launch),
show a "downloading scripture" state and continue.

### 2. Check network availability

Use a connectivity check as a hint only. A "connected" result does not guarantee that
Supabase is reachable. If offline, stop and keep the cache. Any request failure later in
the procedure is treated the same way: abort without moving the cursor.

### 3. Retrieve the authenticated user's membership permission

Sync requires a signed-in session. Without one, skip sync and keep reading the cache.

```dart
// RLS returns only the caller's own row.
final rows = await supabase.from('app_members').select('is_accessible');
```

| Result | Meaning | App behaviour |
|---|---|---|
| 1 row, `is_accessible: false` | Read-only member | Sync. Hide edit tools |
| 1 row, `is_accessible: true` | Editor | Sync. Show edit tools |
| 0 rows | Not a member, or access removed | Skip sync. Content queries would return nothing anyway. Show "no access". **Do not wipe the cache or personal data** |

Hold the flag in memory and refetch it at each sync. Edit tools in the UI are a
convenience only. The server enforces the real permission on every write.

### 4. Fetch updated chapters and verses

Process **chapters first, then shlokas**, so that foreign keys resolve locally. Use
keyset pagination on `(updated_at, id)`:

```text
WHERE updated_at > :cursor_ts
   OR (updated_at = :cursor_ts AND id > :cursor_id)
ORDER BY updated_at, id
LIMIT 500
```

```dart
// Sketch only, not final code.
// First page of a run: everything from (stored cursor − overlap), see below.
// Later pages: strictly after the last row of the previous page.
var q = supabase.from('shlokas').select();
if (pageTs != null) {
  q = q.or('updated_at.gt."$pageTs",and(updated_at.eq."$pageTs",id.gt.$pageId)');
} else if (fromTs != null) {
  q = q.gte('updated_at', fromTs);
}
final page = await q.order('updated_at').order('id').limit(500);
```

Repeat until a page comes back with fewer than 500 rows. The first sync has no cursor
and downloads everything: about 718 rows, a handful of pages.

**Safety overlap.** `updated_at` is the time the writing transaction *started*. A
transaction that started earlier but committed after the last sync can therefore become
visible with an `updated_at` older than the cursor. To never miss such rows, start each
run from `cursor_ts − 10 minutes` (with no `id` tie-break for that first page) rather
than exactly at the cursor. The overlap re-downloads a few rows, and step 6 makes that
harmless.

### 5. Detect soft-deleted records

A downloaded row whose `deleted_at` is not null is a tombstone:

- a verse removed by an editor (`deleted_at` set),
- or a verse **restored** (`deleted_at` back to null, with a new `updated_at`), which is
  simply a normal update.

There is no separate "deletions" endpoint, because tombstones arrive through the same
query as every other change.

### 6. Apply updates to SQLite

Inside **one SQLite transaction per page**:

```sql
INSERT INTO local_shlokas (id, chapter_id, verse_number, reference, …, updated_at, deleted_at)
VALUES (…)
ON CONFLICT (id) DO UPDATE SET
  chapter_id = excluded.chapter_id,
  verse_number = excluded.verse_number,
  reference = excluded.reference,
  -- … every content column …
  updated_at = excluded.updated_at,
  deleted_at = excluded.deleted_at
WHERE excluded.updated_at >= local_shlokas.updated_at;   -- never go backwards
```

- **Tombstones are applied as updates.** Set `deleted_at` and keep the row. Never
  `DELETE` from the cache, because personal reflections, notes and bookmarks reference
  these rows.
- The `WHERE excluded.updated_at >= …` guard keeps replayed or overlapping rows
  harmless.
- Personal tables are not touched.

### 7. Store the last successful sync timestamp

In the **same transaction** as each applied page, update the cursor in the local
`sync_metadata` table (`SyncMetadataDao`, keys in `SyncMetadataKeys`):

| Key | Value |
|---|---|
| `content_cursor.chapters`, `content_cursor.shlokas` | JSON `{"updated_at": "<server updated_at of the last applied row>", "id": "<its id>"}` |
| `last_successful_content_sync_at` | Device time when a full run finished (display only) |
| `content_sync_state` | e.g. `idle` / `failed`, for diagnostics |

- The cursor is **the server's `updated_at` from the data**, never the device clock.
  Device clocks drift or can be wrong.
- `last_successful_sync_at` uses the device clock and is for display only.
- Advance the cursor after each committed page (it can be updated per page), so an
  interrupted sync resumes rather than restarting.
- If any step fails, roll back that page and leave the cursor where it was. The next run
  retries from there.

## When to sync

- On app start (after rendering from the cache), and when the app returns to the
  foreground if the last sync was more than a few hours ago.
- On a manual pull-to-refresh.
- **After an editor saves a change**, so their own device reflects it.
- Not continuously, and not through realtime subscriptions.

## Full resync (escape hatch)

Allow a "Re-download scripture" action in settings, and run it automatically if the
local schema version changes in a way that affects the cache. It clears the `content_cursor.*` keys
and repeats steps 4–6 from the beginning. Because the upsert keeps existing ids, this
never orphans personal data. **Do not** implement it by dropping `local_shlokas`.

## Sources and attributions (not yet synced)

`content_sources` behaves exactly like `chapters` and `shlokas` (`updated_at`,
`deleted_at`, and a `(updated_at, id)` index), so it can join the same procedure as a
third entity whenever it is cached locally.

`shloka_source_attributions` is different. Rows are immutable and editors delete them
physically, so incremental sync cannot detect removals. Options, if attributions must be
available offline:

1. **Full refresh** of the attribution table on each sync. It is small (at most a few
   thousand rows) and simple. This is the recommended option.
2. **Fetch per verse** when online and cache opportunistically.
3. A later migration adds `deleted_at` to attributions and replaces physical delete with
   soft delete.

This is listed as an open decision in `DATABASE_ARCHITECTURE.md`.

## Edge cases

| Case | Handling |
|---|---|
| Verse renumbered (A 1.5 → 1.6, B 1.6 → 1.5 in one edit session) | Both arrive as updates of their own UUIDs. `local_shlokas` has a UNIQUE `(chapter_id, verse_number)` (Milestone 2 spec), which SQLite checks per statement, so a swap can't be applied row by row. Within the page's transaction, first move any row whose slot is claimed by a different UUID to a temporary slot (`verse_number + 1000000` with a matching `reference`), then apply the page. This is rare, because the canonical numbering is fixed before seeding |
| Chapter soft-deleted while its verses are live | Readers hide the chapter, so its verses are unreachable from navigation. Editors should soft-delete the verses too |
| User loses membership | Step 3 returns 0 rows. Sync stops, and the cache and personal data stay readable on the device |
| Clock skew on the device | Irrelevant to correctness. Cursors use server timestamps |
| Very large edit batch | Pagination plus per-page commits keep memory and transaction size bounded |
| Seed import in one transaction | Every row shares one `updated_at`. The `id` tie-break in the keyset pagination handles that |
