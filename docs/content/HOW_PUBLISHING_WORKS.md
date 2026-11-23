# How Content Publishing Works in Gitartha

This guide explains, in plain language, how Bhagavad Gita content gets from the JSON
files in this repository into the Supabase database, and why the process is designed
the way it is. No earlier knowledge of the project is needed.

Once you know the basics, the reference documents give the detail:

| If you want… | Read |
|---|---|
| Every command, option and rule | [`CONTENT_PUBLISHING.md`](CONTENT_PUBLISHING.md) |
| How sign-in and permissions work | [`PUBLISHER_AUTHENTICATION.md`](PUBLISHER_AUTHENTICATION.md) |
| How readable ids become database ids | [`CONTENT_ID_MAPPING.md`](CONTENT_ID_MAPPING.md) |
| Help with an error message | [`PUBLISHING_TROUBLESHOOTING.md`](PUBLISHING_TROUBLESHOOTING.md) |
| How content is written and reviewed | [`CONTENT_QUALITY_GUIDELINES.md`](CONTENT_QUALITY_GUIDELINES.md) |

---

## 1. The big picture

Gitartha keeps scripture in three places. Each has its own job:

```text
 ┌────────────────────────────┐   publish (this tool)   ┌──────────────────────┐   sync (future)   ┌──────────────────┐
 │  JSON files in this repo   │ ──────────────────────▶ │  Supabase database   │ ────────────────▶ │  Each phone's    │
 │  assets/data/bhagavad_gita │                         │  (shared, online)    │                   │  local database  │
 │  where content is WRITTEN  │                         │  where it is SERVED  │                   │  where it is READ│
 └────────────────────────────┘                         └──────────────────────┘                   └──────────────────┘
```

- **The JSON files** are the source of truth. People write and review verses here,
  and git keeps the history.
- **Supabase** is the shared online database the app downloads content from.
- **Each phone** keeps its own copy so the app works offline, together with the
  user's private reflections. Private data never goes to Supabase.

**The publisher** is a command-line program run by a developer. It copies **approved**
content from the JSON files into Supabase, safely and repeatably. It is not part of the
app, and it never runs by itself.

---

## 2. The workflow in five steps

```text
  ① Edit JSON  ──▶  ② Validate  ──▶  ③ Preview (dry run)  ──▶  ④ Publish (confirm)  ──▶  ⑤ Read the report
```

### ① Edit a chapter file

Open, for example, `assets/data/bhagavad_gita/chapters/chapter_01.json` and add or
improve a verse. Follow the content guidelines. When a reviewer has checked the verse,
they set its `"review_status"` to `"approved"`.

### ② Validate (no login needed)

```bash
dart run tool/publish_gita_content.dart --chapter=1 --validate-only
```

This checks the files with the publishing rules and tells you how many verses are
ready to publish. It doesn't contact Supabase.

### ③ Preview what would change

```bash
dart run tool/publish_gita_content.dart --chapter=1 --dry-run
```

You sign in. The tool then compares your files with what is already in Supabase and
shows exactly what it would insert or update. **Nothing is written.**

### ④ Publish

```bash
dart run tool/publish_gita_content.dart --chapter=1 --confirm
```

The tool shows the same preview, then asks you to type `publish`. Only after that does
it write to Supabase.

### ⑤ Read the report

The terminal shows the outcome (`success`, `partially_completed`, …). Add
`--save-report` to keep a JSON copy in `reports/content-publishing/`.

> Use `--all` instead of `--chapter=1` to work on every chapter, and add `--verse=41`
> to work on a single verse: `--chapter=1 --verse=41 --dry-run`.

---

## 3. What a run looks like

```text
========================================
       GITARTHA CONTENT PUBLISHER
========================================

Target: Supabase (<project-ref>.supabase.co) using SUPABASE_PUBLISHABLE_KEY
Scope:  Chapter 1
Mode:   DRY RUN

CONTENT VALIDATION (strict publishing rules)
----------------------------------------
Files discovered:              19
Approved verses:                3
Publishable in scope:           3
Blocking errors:                0

Sign in as an existing Gitartha member.
Email: you@example.com
Password:                          ← what you type is not shown
Authenticating...
Authentication successful. Publishing permission confirmed.

PUBLISHING PREVIEW
----------------------------------------
Chapters to insert:             0
Chapters to update:             1
Shlokas to insert:              1
Shlokas to update:              1
Shlokas unchanged:              1
...
Changes:
  UPDATE    chapters  chapter 1 (overview)
  INSERT    shlokas   chapter_01_verse_003
  UPDATE    shlokas   chapter_01_verse_002 (hindi_meaning_note)

========================================
Status: dry_run
No database changes were made.
========================================
```

The numbers above are only an example. A real run calculates them from your files and
from Supabase.

---

## 4. What happens inside, step by step

```text
JSON files
   │
   ▼
1. Validate ─────────── broken files?  ─────────▶ STOP (fix the errors first)
   │
   ▼
2. Select approved content only
   │
   ▼
3. Load settings (.env) ─── secret key? ────────▶ STOP (refused)
   │
   ▼
4. Sign in (email + hidden password)
   │
   ▼
5. Check permission ─── not an editor? ─────────▶ STOP ("Publishing permission denied")
   │
   ▼
6. Check the database has the expected columns
   │
   ▼
7. Compare files with Supabase → plan of changes
   │
   ▼
8. Show the preview ─── dry run? ───────────────▶ END (nothing written)
   │
   ▼
9. Ask you to type "publish"
   │
   ▼
10. Write, in order: chapters → sources → verses → attributions
   │
   ▼
11. Report (and sign out)
```

**1. Validate.** Every chapter file is checked against the JSON Schema and the
consistency rules: unique verse numbers, ids that match their verse, sources that
exist, and so on. Real mistakes, like broken JSON or a duplicate verse, stop
everything.

**2. Select approved content.** Only content that is ready is published:

- a **verse** must be complete, marked `approved`, and cite verified sources for its
  Sanskrit, Hindi and English text;
- a **chapter** is published once it has its three names. Its description is
  published only when the chapter itself is approved;
- a **source** is published only if its licence is recorded.

Content that isn't ready yet, such as a draft verse, is simply **left out**, not
treated as an error. That allows publishing verse by verse as reviews finish.

**3–5. Who you are, and whether you may publish.** See §5 below.

**6. Database check.** The tool checks that Supabase has every column it needs, for
example `hindi_meaning_note`, before it plans anything.

**7. Plan.** The tool reads the matching rows from Supabase and decides, for each
record:

| Decision | Meaning |
|---|---|
| **insert** | It doesn't exist in Supabase yet |
| **update** | It exists, but the text differs (the preview names the fields) |
| **unchanged** | It is already identical, so nothing is sent |
| **skip** | It is deliberately not touched (for example, it was retired in Supabase) |
| **error** | It can't be published safely. The whole publish is refused until this is resolved |

Automatic timestamps are ignored when comparing, so a second run of the same command
finds everything **unchanged** and sends nothing.

**10. Write in order.** Chapters go before the verses that belong to them, and sources
before the attributions that point to them. If something fails, anything that depends
on it isn't attempted.

---

## 5. Security: who can publish

The publisher has no master key. It works only as **you**, with the same permissions
you would have anywhere else.

```text
  Your email + password ──▶ Supabase Auth ──▶ "you are user X"
                                                    │
  app_members table: user X → is_accessible = true? │── no ──▶ "Publishing permission denied."
                                                    │
                                                    yes
                                                    ▼
  Every write is checked AGAIN by the database (Row Level Security)
```

- **Membership.** Every user has a row in `app_members`. Only users with
  `is_accessible = true` may change shared scripture. New users start at `false`.
- **Only the project owner grants permission,** in the Supabase SQL Editor. Nobody can
  grant permission to themselves, and this tool cannot change permissions at all.
- **The database has the final word.** Even after the tool's own check, Supabase checks
  every single write (Row Level Security). If someone's permission is removed during a
  run, the next write is refused.
- **Keys.** The tool uses only the public *publishable* key, which identifies the
  project but grants nothing on its own. It **refuses** secret and service-role keys.
- **Password.** It is typed without being shown. It is never accepted on the command
  line, never stored in a file, and never written to reports. The login lasts only
  while the command runs.

### Setting up

Add the project details to `.env` in the project root (see `.env.example`):

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_<your-publishable-key>
```

You also need a Supabase account that the project owner has invited and marked
`is_accessible = true`.

---

## 6. Safety rules the publisher always follows

| Rule | Why |
|---|---|
| **Writes only with `--confirm`, after you type `publish`** | Nothing changes by accident |
| **Publishes only approved content** | Unreviewed text never reaches users |
| **Never deletes anything** | A verse missing from a file may be a mistake. Deleting is a separate, deliberate job |
| **Never restores retired (soft-deleted) records** | Restoring needs a conscious decision |
| **Never sends unchanged records** | Re-running is harmless, and timestamps stay meaningful |
| **Always uses the same id for the same verse** | No duplicates, and users' reflections stay linked (see §7) |
| **Never touches memberships or personal data** | It has no way to reach them |

---

## 7. Why ids matter

People refer to verses with readable ids like `chapter_01_verse_041`. The database needs
UUIDs. The tool converts one into the other with a fixed formula (a "version 5 UUID"):

```text
chapter_01_verse_041  ──(fixed formula)──▶  8c555087-1c57-50db-9632-7bbd1e10a472
```

The same input always produces the same output, on every computer and every run.
Because of that:

- publishing twice never creates a second copy of a verse;
- the local database on phones uses exactly the same id, so a reflection a user wrote
  about verse 1.41 stays attached to verse 1.41 forever.

Details: [`CONTENT_ID_MAPPING.md`](CONTENT_ID_MAPPING.md).

---

## 8. When something goes wrong

Publishing sends several requests to Supabase. Each request either fully succeeds or
fully fails, but the run as a whole could stop halfway, for example if the network
drops. The tool handles this as follows:

1. It stops anything that depends on the failed part (no verse without its chapter, no
   attribution without its verse).
2. It reports exactly what was written, what failed, and what wasn't attempted (status
   `partially_completed`).
3. **You fix the cause and run the same command again.** Finished records show as
   *unchanged*, and only the rest are sent. Nothing is duplicated.

Common messages:

| Message | What to do |
|---|---|
| `Validation found N blocking error(s)` | Fix the listed file/field. `dart run tool/validate_gita_content.dart --chapter=N --verbose` gives detail |
| `Nothing is publishable in this scope yet` | No verse there is complete and approved yet |
| `Invalid email or password.` | Check your login |
| `Publishing permission denied.` | Ask the project owner to set your `is_accessible` |
| `An interactive terminal is required…` | Run from PowerShell / Windows Terminal, or `winpty dart run …` in Git Bash |
| `…refuses privileged keys` | You configured a secret key. Use the publishable key instead |

More: [`PUBLISHING_TROUBLESHOOTING.md`](PUBLISHING_TROUBLESHOOTING.md).

---

## 9. Quick reference

```bash
# Check content (no login)
dart run tool/publish_gita_content.dart --all --validate-only

# Preview (login, no writes)
dart run tool/publish_gita_content.dart --all --dry-run
dart run tool/publish_gita_content.dart --chapter=1 --dry-run
dart run tool/publish_gita_content.dart --chapter=1 --verse=41 --dry-run

# Publish (login, preview, type "publish")
dart run tool/publish_gita_content.dart --all --confirm
dart run tool/publish_gita_content.dart --chapter=1 --confirm

# Keep a report / show help
dart run tool/publish_gita_content.dart --chapter=1 --confirm --save-report
dart run tool/publish_gita_content.dart --help
```

| Exit code | Meaning |
|---|---|
| 0 | OK |
| 1 | Content problem, or cancelled |
| 2 | Wrong options or settings |
| 3 | Login failed or no permission |
| 4 | Supabase problem, or only partly published |

---

## 10. Where the code lives

| Part | Location |
|---|---|
| The command you run | `tool/publish_gita_content.dart` |
| Command steps and options | `tool/publishing/publish_command.dart` |
| Reading `.env`, refusing secret keys | `tool/publishing/publishing_config.dart` |
| Talking to Supabase | `tool/publishing/supabase_remote_content_store.dart` |
| Hidden password prompt | `tool/publishing/terminal.dart` |
| Permission check | `lib/data/content/publishing/publisher_access.dart` |
| Comparing files with Supabase | `lib/data/content/publishing/publishing_planner.dart` |
| Writing in the right order | `lib/data/content/publishing/publishing_executor.dart` |
| Which content is "approved" | `lib/data/content/selection/content_selection.dart` |
| Validation (shared with the app) | `lib/data/content/validators/` and `services/` |
| Tests (no real Supabase needed) | `test/tool/` and `test/unit/data/content/publishing/` |

Run the publisher's tests with:

```bash
flutter test test/tool test/unit/data/content/publishing
```
