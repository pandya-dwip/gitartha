# Gitartha — Shared-Content Synchronization (Supabase → SQLite)

Implemented in Milestone 5, in `lib/features/synchronization/`. This is pull only:
the device downloads shared scripture and never uploads anything. Personal data is
not part of sync in any form.

## Principles

- **SQLite is the reading source.** Screens read cached content through Drift watch
  queries (`localChaptersProvider`, `localShlokasForChapterProvider`,
  `chapterProgressSummariesProvider` in `lib/data/local/local_database_providers.dart`).
  Startup renders from the cache immediately. Sync runs in the background and the
  providers re-emit when it commits, so no invalidation is needed.
- **Incremental, with overlap.** Each table is read from
  `checkpoint − overlap` (10 min by default). The checkpoint is the **server's**
  newest timestamp seen, never the device clock.
- **Staged, then one transaction.** All pages of all four tables are downloaded first,
  with no transaction open during network calls. Then the rows and the new checkpoint
  are written in **one** Drift transaction. Any failure (network, auth, pagination,
  bad data, SQLite) leaves the previous content **and** the previous checkpoint.
- **Idempotent.** Upserts keep server ids and never go backwards (`updated_at`), so
  re-downloads and retries are harmless.
- **Tombstones are updates.** `deleted_at` is copied and rows are never physically
  deleted, because personal tables reference shlokas (`ON DELETE RESTRICT`).

## Components

| Piece | File | Role |
|---|---|---|
| `SupabaseContentDataSource` | `data/content_remote_datasource.dart` | One ordered page per call, read-only, as the signed-in member (RLS applies). It maps errors to `SyncException` |
| `RemoteRowMapper` | `data/remote_row_mapper.dart` | Strict row → Drift row mapping. A missing field or wrong type aborts the run. Nulls are kept |
| `ContentSyncService` | `data/content_sync_service.dart` | Pagination, staging, transaction, checkpoints, counts. Concurrent callers share one run |
| `ContentSyncController` (`contentSyncProvider`) | `presentation/providers/content_sync_provider.dart` | Auth gating, automatic triggers, `syncContentManually()`, state for the UI |
| `SyncResult`, `SyncStatus`, `SyncFailureKind` | `domain/sync_result.dart` | Structured outcome and safe user messages |

Column lists are shared with the publisher's mappers
(`lib/data/content/publishing/mappers/`), so both sides read the same schema,
`hindi_meaning_note` included.

## Procedure

1. Write `content_sync_state = syncing` and the attempt time.
2. Read the checkpoint. If there is no successful sync yet, or the stored
   `content_sync_protocol` differs from `ContentSyncService.protocolVersion`, run a
   **full sync**: no lower bound, so every row including tombstones is fetched.
3. For **chapters → content_sources → shlokas → shloka_source_attributions**
   (dependency order), fetch pages with keyset pagination:

   ```text
   first page:  WHERE ts >= :checkpoint − overlap            (none on a full sync)
   next pages:  WHERE ts > :last_ts OR (ts = :last_ts AND id > :last_id)
   ORDER BY ts ASC, id ASC   LIMIT :pageSize (500)
   ```

   `ts` is `updated_at`, except for attributions, which have only `created_at`.
   Fetching stops at an **empty** page, so a server "max rows" setting below the page
   size can't truncate a table. Each run costs one extra small request per table.
4. Parse every row strictly. Nothing has been written yet.
5. In one transaction:
   - upsert chapters, sources, shlokas (existing DAO upserts with the "not older"
     guard);
   - if a verse slot `(chapter, verse)` is held by a *different* cached row, park that
     row on a unique out-of-range slot and hide it, so the server row can land. The
     parked row keeps its id, and personal records stay attached;
   - insert new attributions (`INSERT OR IGNORE`);
   - on a full sync only, remove cached attributions of server shlokas that the
     server no longer has (see Limitations);
   - write the per-table cursors (`content_cursor.<table>`),
     `last_successful_content_sync_at`, `content_sync_protocol`,
     `content_sync_state = success`, and clear `last_content_sync_error`.
6. On failure, write `content_sync_state = failed` and `last_content_sync_error = <kind>`.
   Nothing else changes.

Why the cursor comes from the data rather than a "sync start" clock time: the device
clock can be wrong, and there is no server-time endpoint. A row updated during a run
has a newer `updated_at` than anything already read, so the next run sees it. The
overlap covers transactions that committed late with an older `updated_at`.

## Who syncs, and when

| Auth status (Milestone 4) | Sync |
|---|---|
| `readOnly`, `editor` | yes: downloading needs membership, not editing permission |
| `signedOut` | no; result `unauthenticated` |
| `membershipMissing`, `membershipError`, `loadingMembership`, `passwordRecovery` | no; result `membershipUnavailable` |
| `backendUnavailable` | no; result `offline` |

Triggers:

- **Automatic:** the moment the user becomes an active member (a restored session at
  startup, or sign-in), and on app resume (`AppLifecycleListener` in `main.dart`).
  Skipped if a sync is running, or if the last success is newer than
  `SyncConfig.autoSyncMinInterval` (30 min).
- **Manual:** `ref.read(contentSyncProvider.notifier).syncContentManually()`. This
  ignores the interval and joins a running sync.
- No realtime, no polling, no background jobs.

Sign-out, loss of membership, or a different user during a run cancels it before
anything is applied. The cache is never cleared by auth changes: shared scripture is
the same for every member.

## `sync_metadata` keys

| Key | Value |
|---|---|
| `content_cursor.chapters` / `.content_sources` / `.shlokas` / `.shloka_source_attributions` | newest server timestamp applied, fixed-width UTC |
| `content_sync_protocol` | protocol version that wrote the cursors |
| `last_successful_content_sync_at` | device time of the last success (display, and the auto-sync interval) |
| `last_content_sync_attempt_at` | device time of the last attempt |
| `content_sync_state` | `syncing` / `success` / `failed` (`syncing` with nothing running = interrupted; simply retried) |
| `last_content_sync_error` | `SyncFailureKind` name |

No credentials or tokens are ever stored here. No migration was needed: the table and
the four cache tables already existed (schema v2).

## Limitations

- **Attribution deletions.** Attributions have no `updated_at` and no `deleted_at`,
  and are physically deleted, so an incremental sync cannot see a removal. A full sync
  reconciles them. To force one, bump `protocolVersion`, or delete the
  `content_sync_protocol` key. The publisher never deletes attributions; only manual
  SQL does. If deletions become routine, the smallest fix is a server migration that
  adds `deleted_at` to attributions, used as a soft delete.
- **Rows the server never had** (from a local JSON import, for development) are left
  alone. Sync only applies server rows.
- **Memory.** A run stages its changes in memory. A first sync of the whole Gita
  (about 3,000 rows including attributions) is small. A much larger catalogue would
  want per-table transactions.
- **First launch offline.** The cache is empty and the providers emit empty lists.
  The future UI should show an "offline, nothing downloaded yet" state.
