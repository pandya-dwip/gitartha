# Gitartha — Publishing Content to Supabase

`tool/publish_gita_content.dart` publishes **approved** content from the JSON repository
(`assets/data/bhagavad_gita/`) to the Supabase tables `chapters`, `content_sources`,
`shlokas` and `shloka_source_attributions`. It runs as **you**: an existing member
whose `app_members.is_accessible = true`, signed in with your password, using the
publishable key, under RLS.

It is a developer tool. It isn't part of the app, isn't triggered by file changes, and
never runs at startup.

## Workflow

```text
1. Edit chapters/chapter_NN.json (content guidelines; reviewer sets "approved")
2. dart run tool/publish_gita_content.dart --chapter=N --validate-only   # no login
3. dart run tool/publish_gita_content.dart --chapter=N --dry-run         # login, preview
4. dart run tool/publish_gita_content.dart --chapter=N --confirm         # login, preview, type "publish"
5. Read the report (optionally --save-report)
```

## Commands

```bash
# Validate (strict publishing rules); no Supabase, no credentials
dart run tool/publish_gita_content.dart --all --validate-only

# Preview everything (reads Supabase, writes nothing)
dart run tool/publish_gita_content.dart --all --dry-run

# Publish everything
dart run tool/publish_gita_content.dart --all --confirm

# One chapter
dart run tool/publish_gita_content.dart --chapter=1 --dry-run
dart run tool/publish_gita_content.dart --chapter=1 --confirm

# One verse (chapter row only inserted if it does not exist yet)
dart run tool/publish_gita_content.dart --chapter=1 --verse=41 --dry-run
dart run tool/publish_gita_content.dart --chapter=1 --verse=41 --confirm

# Keep a JSON report in reports/content-publishing/
dart run tool/publish_gita_content.dart --chapter=1 --confirm --save-report

dart run tool/publish_gita_content.dart --help
```

| Rule | |
|---|---|
| Scope | `--all` **or** `--chapter=N` (1–18). `--verse=N` requires `--chapter` and must be within that chapter's verse count |
| Mode | `--validate-only` (the **default**), `--dry-run` or `--confirm`. Only one |
| Writes | Only with `--confirm`, after the preview **and** after you type `publish` |
| Credentials | Asked for interactively. Arguments such as `--password` or `--email` are rejected |
| Config | `--env-file=PATH` (default `.env`). See [`PUBLISHER_AUTHENTICATION.md`](PUBLISHER_AUTHENTICATION.md) |

**Exit codes:**

| Code | Meaning |
|---|---|
| `0` | OK. The validation passed, the dry run completed, or the publish succeeded (possibly with warnings) |
| `1` | Blocking validation errors, plan errors, or the publish was cancelled |
| `2` | Bad arguments or configuration (including a refused secret key) |
| `3` | Sign-in failed or publishing permission was denied |
| `4` | A remote problem: schema mismatch, a failed or partial publish |

## Architecture

```text
JSON files ─▶ ContentValidationService (strict) ─▶ blocking errors? ── yes ─▶ stop
                                                    │ no
                ContentSelector (approved only) ◀───┘     (same selector as the local import)
                         │
   validate-only stops ──┤
                         ▼
   PublishingConfig (.env: URL + publishable key; secret keys refused)
                         ▼
   PublisherAccessService: sign in ─▶ own app_members row ─▶ is_accessible? ── no ─▶ stop
                         ▼
   verifySchema (columns exist, incl. hindi_meaning_note)
                         ▼
   PublishingPlanner: map rows ─▶ read remote ─▶ insert/update/unchanged/skip/error
                         ▼
   Preview ─── dry run stops ─── errors? stop ─── type "publish"
                         ▼
   PublishingExecutor: chapters → sources → shlokas → attributions (RLS enforces each write)
                         ▼
   PublishingResult (terminal, optional JSON report)
```

| Code | Location |
|---|---|
| Entry point | `tool/publish_gita_content.dart` |
| Command flow, options | `tool/publishing/publish_command.dart` |
| Configuration | `tool/publishing/publishing_config.dart` |
| Supabase adapter (REST/Auth) | `tool/publishing/supabase_remote_content_store.dart` |
| Hidden password input | `tool/publishing/terminal.dart` |
| Store interface, errors | `lib/data/content/publishing/remote_content_store.dart` |
| Membership check | `lib/data/content/publishing/publisher_access.dart` |
| Row mappers | `lib/data/content/publishing/mappers/` |
| Change detection | `lib/data/content/publishing/publishing_planner.dart` |
| Ordered writes | `lib/data/content/publishing/publishing_executor.dart` |
| Plan, result and report | `publishing_models.dart`, `publishing_result.dart`, `publishing_report_formatter.dart` |
| Eligibility (shared with the local import) | `lib/data/content/selection/content_selection.dart` |

The validation, models, ids and eligibility rules are the Milestone 3 components,
reused. Nothing is parsed or validated twice.

## What gets published

The rules are exactly those of the local *approved import*:

- A **chapter** is published once its three names exist. Its descriptive fields are
  published only when the chapter metadata is `approved` and complete. Otherwise they
  are `NULL`.
- A **verse** is published only when it is complete, `approved`, attributed to sources
  for Sanskrit, Hindi and English, and those sources have a verified licence.
- A **source** is published only with a verified licence. For a chapter or verse scope,
  only the sources those verses cite are published.
- **Attributions** of published verses are inserted when missing.

**Blocking vs. not ready:** structural errors (invalid JSON, schema violations,
duplicate ids or verse numbers, id/reference mismatches, unknown sources, attributions
on empty sections) in the files in scope **block** publishing. "Not ready" findings
(`INCOMPLETE_CONTENT`, `NOT_APPROVED`, `MISSING_VERSES`, `MISSING_ATTRIBUTION`,
`UNVERIFIED_SOURCE_LICENSE`) only leave those records out. This lets content be
published verse by verse as it is approved.

## Table mapping

| Supabase column | From | Notes |
|---|---|---|
| `chapters.id` | `chapter.id` | 1–18 |
| `chapters.sanskrit_name`, `hindi_name`, `english_name` | `chapter.*_name` | required |
| `chapters.introduction`, `overview`, `central_theme`, `summary`, `conclusion` | same | `""` → NULL. NULL unless the metadata is approved |
| `chapters.key_topics` (`text[]`) | `chapter.key_topics` | `[]` → NULL |
| `shlokas.id` | `ContentIds.shloka(verse.id)` | deterministic UUID v5 ([`CONTENT_ID_MAPPING.md`](CONTENT_ID_MAPPING.md)) |
| `shlokas.chapter_id`, `verse_number` | file's chapter, `verse_number` | unique `(chapter_id, verse_number)` |
| `shlokas.reference` | — | **not sent**: a generated column |
| `shlokas.index_title` … `reflection_question`, **`hindi_meaning_note`** | same names | `""` → NULL. The note stays separate from `hindi_meaning` |
| `content_sources.id` | `ContentIds.source(source.id)` | |
| `content_sources.name`, `author`, `source_url`, `license`, `attribution` | same | `""` → NULL, nothing invented |
| `shloka_source_attributions.id` | `ContentIds.attribution(verse, source, section)` | |
| `…shloka_id`, `source_id`, `content_section` | mapped UUIDs, section value | all 9 sections, incl. `hindi_meaning_note` |
| `created_at`, `updated_at` (all tables) | — | **not sent**: the `set_row_timestamps` trigger owns them |
| `deleted_at` | — | **never sent** |
| `app_members` | — | read-only (own row), never written |

## Change detection and idempotency

Before any write, the planner reads the current remote rows and compares the
**publishable columns** (normalized JSON). Timestamps are never compared.

| Remote state | Plan | Written? |
|---|---|---|
| no row | `insert` | yes (upsert) |
| row with different content | `update`, listing the changed fields | yes (upsert) |
| row with identical content | `unchanged` | **no**, so `updated_at` is not bumped |
| row soft-deleted (`deleted_at` set) | `skip` `REMOTE_SOFT_DELETED` | no. Never restored |
| (chapter, verse) slot owned by another id | `error` `VERSE_SLOT_CONFLICT` | the whole publish is refused |
| chapter differs, but `--verse` scope | `skip` `OUTSIDE_VERSE_SCOPE` | no |
| attribution in Supabase but not in the files | `skip` `REMOTE_ONLY_ATTRIBUTION` | no. Never deleted |

Writes are `INSERT … ON CONFLICT (id) DO UPDATE` (chapters, sources, shlokas), and
`INSERT … ON CONFLICT (shloka_id, source_id, content_section) DO NOTHING` (attributions).
Attribution rows are immutable in the schema, and editors have no UPDATE privilege on
them. Ids are deterministic, so running the same command twice produces no
duplicates. The second run reports everything as unchanged and sends nothing.

**Nothing is ever deleted or soft-deleted.** A verse removed from a JSON file stays in
Supabase. Absence is never treated as an instruction. Deletion and restoration need a
separate, explicit operation, which is not implemented.

## Order, partial failures and retries

Writes go in dependency order: **chapters → sources → shlokas → attributions**. There
is one request per chapter, per source, per chapter's shlokas, and per chapter's
attributions. Each request is a single SQL statement, so it is atomic. **The run as a
whole is not atomic:** several HTTP requests never are.

- Before the first write, everything is validated, the plan is complete, and any plan
  error refuses the run.
- If an **insert** of a chapter, source or verse batch fails, its dependents are not
  attempted (`PREREQUISITE_FAILED`).
- **Permission, session, network, rate-limit and schema errors stop the run**
  (`RUN_STOPPED`). Foreign-key, unique and check errors fail only that request.
- The result is `partially_completed`, listing exactly what was written, what failed
  and what was not attempted.
- **Retrying is safe:** run the same command again. Finished records show as
  unchanged and only the rest are sent.

An atomic multi-table RPC was considered and **not** added. It would need a new
migration and a function that re-implements the RLS check. The ordered, idempotent
REST approach with exact reporting meets the requirements without new database code.

## Reports

Each run ends with a status:

| Status | Meaning |
|---|---|
| `dry_run` | `--validate-only` or `--dry-run`. Nothing was written |
| `success` | Every planned write succeeded, and nothing was left out |
| `success_with_warnings` | Every planned write succeeded, but some records were skipped (not approved, soft-deleted, out of scope…) |
| `partially_completed` | Some writes succeeded and some failed or were not attempted |
| `failed` | Stopped before writing (configuration, validation, sign-in, permission, schema, plan errors, cancellation), or every write failed |

`--save-report` writes `reports/content-publishing/publishing_YYYYMMDD_HHMMSS.json`
(UTC). `/reports/` is git-ignored. It contains:

- the operation id, target host, scope, timestamps and your user id;
- per-table inserted / updated / unchanged / skipped / errors / failed counts;
- every skipped, failed and written record with its reason;
- validation errors and warnings.

It **never** contains your email, password, tokens or keys.

## Current state of the repository

`--all --validate-only` reports 0 blocking errors and **0 publishable verses**: no
chapter has names yet, and Verse 1.41 is a `draft` without sources. A `--confirm` run
today would therefore write nothing. That is expected.
