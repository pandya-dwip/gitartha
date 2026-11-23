# Bhagavad Gita Content Repository

This folder is the **authoring source** for Gitartha's scripture content: all 18
chapters and, eventually, all 700 verses with their translations and explanations. It is
kept as reviewable JSON in git, validated automatically, and later imported into
Supabase. The app reads it from there through its local cache.

> **Current state:** 18 chapter files exist. Every chapter has empty metadata and no
> verses, except **Chapter 1, Verse 41**, a draft sample entry. Nothing else has been
> written yet, and the repository does **not** contain the 700 verses.

The folder is not listed in `pubspec.yaml`, so it is **not** bundled into the app. It
is source data for the Supabase import.

## 1. Folder structure

```text
assets/data/bhagavad_gita/
├── README.md                     this file
├── schema/
│   ├── chapter.schema.json       JSON Schema (Draft 2020-12) for chapter files
│   ├── sources.schema.json       JSON Schema for sources.json
│   └── content-guidelines.md     editorial and accuracy rules — read before writing
├── chapters/
│   ├── chapter_01.json           one file per chapter: metadata + all its verses
│   └── … chapter_18.json
└── sources/
    └── sources.json              verified sources (translations, editions, commentaries)

tool/validate_gita_content.dart   validator (project root, Dart SDK only)
```

There is **one file per chapter**. Verses live inside their chapter file, never in
separate files, and chapter information is never duplicated elsewhere.

## 2. Chapter file structure

```json
{
  "schema_version": "1.0.0",
  "chapter": {
    "id": 1,
    "sanskrit_name": "",
    "hindi_name": "",
    "english_name": "",
    "introduction": "",
    "overview": "",
    "central_theme": "",
    "key_topics": [],
    "summary": "",
    "conclusion": "",
    "review_status": "draft"
  },
  "verses": []
}
```

| Field | Rules |
|---|---|
| `schema_version` | Always `"1.0.0"` for this format |
| `chapter.id` | Chapter number 1–18. Must match the file name |
| `sanskrit_name`, `hindi_name`, `english_name` | Chapter names. `""` until verified |
| `introduction`, `overview`, `central_theme`, `summary`, `conclusion` | Text. `""` until written |
| `key_topics` | Array of non-empty, unique strings, in display order. `[]` until written |
| `review_status` | `draft`, `in_review` or `approved` (see guidelines §12) |
| `verses` | Verse objects in ascending `verse_number` order. `[]` is fine |

## 3. Verse (shloka) structure

Fields appear in the app's reading order:

```json
{
  "id": "chapter_01_verse_041",
  "verse_number": 41,
  "reference": "1.41",
  "index_title": "",
  "index_summary": "",
  "sanskrit_text": "",
  "transliteration": "",
  "hindi_meaning": "",
  "hindi_meaning_note": "",
  "english_meaning": "",
  "context": "",
  "life_lesson": "",
  "spiritual_meaning": "",
  "reflection_question": "",
  "source_attributions": [],
  "review_status": "draft"
}
```

| Field | Rules |
|---|---|
| `id` | `chapter_NN_verse_NNN`, zero-padded, derived from the chapter and verse number. Permanent |
| `verse_number` | Positive integer, unique within the chapter |
| `reference` | `"<chapter>.<verse>"` without padding, e.g. `1.41` |
| `index_title`, `index_summary` | Shown in the chapter's verse list |
| `sanskrit_text` … `reflection_question` | See the guidelines. `""` = not written yet |
| `hindi_meaning_note` | Optional wording note, shown after the Hindi meaning under "A note on the wording". Never part of the translation |
| `source_attributions` | See §6 |
| `review_status` | `draft`, `in_review` or `approved` |

All keys are required in every verse, even when empty, and no other keys are allowed.
That keeps every file the same shape.

Text conventions: `\n` separates lines of Sanskrit and transliteration, `\n\n`
separates paragraphs in prose, and `*term*` marks emphasis for Sanskrit terms in prose.
Nothing else (guidelines §10).

**One addition to the requested format:** `review_status`, on both chapters and
verses. It records the human review decision, which can't be derived from the content.
It lets the validator tell draft, ready-for-review and approved content apart. It is
**not** imported as a database column (see §9).

## 4. How to add or complete a verse

1. Open `chapters/chapter_NN.json` for the chapter.
2. Add the verse object to `verses` at the position that keeps `verse_number` in
   ascending order. Copy the template from §3 so that every key is present.
3. Set `id` (`chapter_02_verse_047`), `verse_number` (`47`) and `reference` (`2.47`).
4. Fill in only content you have from a verified source, or that you have written
   following `schema/content-guidelines.md`. Leave the rest as `""`.
5. Add the sources you used to `sources/sources.json` (if they are new), and add
   `source_attributions` for the sections they cover.
6. Leave `review_status` as `draft`. Change it to `in_review` when all fields are
   filled. A reviewer changes it to `approved`.
7. Run the validator (§7) and fix any errors before committing.

Files must be saved as UTF-8 without a BOM, with Devanagari typed or pasted as real
characters, not `\u` escapes. Any editor with UTF-8 support works. A JSON formatter
with 2-space indentation keeps diffs clean.

## 5. How to add a chapter

All 18 chapter files already exist, and the Gita has exactly 18 chapters, so you never
create a new chapter file. Adding a chapter means filling in the metadata of its
existing file, sourcing the names, and setting `review_status` as in §4. Do not rename,
split or duplicate chapter files. The validator rejects any other file in `chapters/`.

## 6. Source attributions

`sources/sources.json` lists every source used:

```json
{
  "sources": [
    {
      "id": "stable_snake_case_id",
      "name": "Title of the work or edition",
      "author": "Translator / editor / commentator",
      "source_url": "https://…",
      "license": "Licence or permission terms",
      "attribution": "Exact credit text to display"
    }
  ]
}
```

A verse then records which of its sections came from which source:

```json
"source_attributions": [
  { "source_id": "stable_snake_case_id", "content_section": "sanskrit_text" },
  { "source_id": "stable_snake_case_id", "content_section": "english_meaning" }
]
```

- The allowed `content_section` values are `sanskrit_text`, `transliteration`,
  `hindi_meaning`, `hindi_meaning_note`, `english_meaning`, `context`, `life_lesson`,
  `spiritual_meaning` and `reflection_question`. They match the Supabase table's check
  constraint.
- `source_id` must exist in `sources.json`. Duplicate entries are rejected.
- Only attribute real, verified sources, and only for sections that have content.
- An approved verse needs attributions for `sanskrit_text`, `hindi_meaning` and
  `english_meaning`, from sources with a recorded licence.

The sources list is **empty** at the moment. The sample verse has no attributions
because no source was supplied with it.

## 7. Validation

From the project root:

```sh
dart run tool/validate_gita_content.dart            # summary per chapter
dart run tool/validate_gita_content.dart --verbose  # also lists each verse's missing fields
```

It needs only the Dart SDK (no packages) and exits `1` if there are errors. It checks:

- **Structure:** each file against its JSON Schema (parsed and interpreted directly).
- **Consistency:**
  - file name matches `chapter.id`;
  - `id` and `reference` agree with `verse_number`;
  - verse ids and numbers are unique and in ascending order;
  - source ids are unique and exist;
  - attributions only point at sections that have content;
  - no stray files.
- **Readiness:** each verse is reported as *incomplete*, *ready for review* or
  *approved*, and each chapter as *publication-ready* or not. Approval rules are
  enforced (guidelines §12).

JSON Schema cannot express "unique by property" or relations between files, which is
why the script exists. Incomplete drafts never fail validation. Structural mistakes
always do.

The expected verse count per chapter (700 in total; Chapter 13 counted as 34 verses)
is set in the script. **Confirm the edition Gitartha follows** and record it here
before seeding; some editions count 35 verses in Chapter 13.

**Editor support (optional):** to get live validation in VS Code, map the schemas in
`.vscode/settings.json`:

```json
"json.schemas": [
  { "fileMatch": ["assets/data/bhagavad_gita/chapters/*.json"],
    "url": "./assets/data/bhagavad_gita/schema/chapter.schema.json" },
  { "fileMatch": ["assets/data/bhagavad_gita/sources/sources.json"],
    "url": "./assets/data/bhagavad_gita/schema/sources.schema.json" }
]
```

Any Draft 2020-12 validator (for example Ajv) can also check the structure. Only the
script performs the consistency and readiness checks.

## 8. Content accuracy rules (summary)

The full rules are in [`schema/content-guidelines.md`](schema/content-guidelines.md). In
short:

- keep scripture, translation, context, lesson, interpretation and question separate;
- never present interpretation as literal meaning;
- never invent text, sources, history or licences;
- copy Sanskrit exactly and use IAST consistently;
- check copyright before using any translation;
- anything machine-generated stays `draft` until a person verifies it.

## 9. Importing into Supabase (future — not implemented)

No import tool exists yet. When one is written, it must follow these rules.

### Field mapping

| JSON | Supabase | Import rule |
|---|---|---|
| `schema_version` | — | Checked, not stored |
| `chapter.id` | `chapters.id` | As is |
| `chapter.sanskrit_name` / `hindi_name` / `english_name` | `chapters.sanskrit_name` / `hindi_name` / `english_name` | Required (NOT NULL in the database) |
| `chapter.introduction` | `chapters.introduction` | `""` → NULL |
| `chapter.overview` | `chapters.overview` | `""` → NULL |
| `chapter.central_theme` | `chapters.central_theme` | `""` → NULL |
| `chapter.key_topics` | `chapters.key_topics` (`text[]`) | `[]` → NULL |
| `chapter.summary` | `chapters.summary` | `""` → NULL |
| `chapter.conclusion` | `chapters.conclusion` | `""` → NULL |
| `chapter.review_status` | — | Import gate (see below), not stored |
| *(file's `chapter.id`)* | `shlokas.chapter_id` | Verses have no `chapter_id` key; it comes from the file they are in |
| `verse.id` | — (`shlokas.id` is a UUID) | Mapped to the UUID through the natural key, see below |
| `verse.verse_number` | `shlokas.verse_number` | As is |
| `verse.reference` | `shlokas.reference` | **Not written.** It is a generated column. The import checks it matches |
| `verse.index_title` | `shlokas.index_title` | `""` → NULL |
| `verse.index_summary` | `shlokas.index_summary` | `""` → NULL |
| `verse.sanskrit_text` | `shlokas.sanskrit_text` | `""` → NULL |
| `verse.transliteration` | `shlokas.transliteration` | `""` → NULL |
| `verse.hindi_meaning` | `shlokas.hindi_meaning` | `""` → NULL |
| `verse.hindi_meaning_note` | `shlokas.hindi_meaning_note` | `""` → NULL |
| `verse.english_meaning` | `shlokas.english_meaning` | `""` → NULL |
| `verse.context` | `shlokas.context` | `""` → NULL |
| `verse.life_lesson` | `shlokas.life_lesson` | `""` → NULL |
| `verse.spiritual_meaning` | `shlokas.spiritual_meaning` | `""` → NULL |
| `verse.reflection_question` | `shlokas.reflection_question` | `""` → NULL |
| `verse.source_attributions[]` | `shloka_source_attributions` (one row each) | `shloka_id` = the verse's UUID, `source_id` = the source's UUID, `content_section` as is |
| `verse.review_status` | — | Import gate, not stored |
| `sources[].id` | — (`content_sources.id` is a UUID) | Needs a key column, see "Schema changes" |
| `sources[].name` / `author` / `source_url` / `license` / `attribution` | `content_sources.*` (same names) | `""` → NULL |

Empty strings must become NULL, because the database rejects blank text.

### Verse ids and UUIDs

A text id such as `chapter_01_verse_041` is never written into the UUID column.
Instead:

1. `verse.id` is fully determined by `(chapter_id, verse_number)`, and the validator
   enforces this. `(chapter_id, verse_number)` is also unique in Supabase
   (`shlokas_chapter_verse_key`). The import therefore **upserts on that natural key**:
   `INSERT … ON CONFLICT (chapter_id, verse_number) DO UPDATE …`. Supabase generates
   the UUID on first insert and keeps it permanently. Later imports update the same
   row.
2. The import reads back `id, chapter_id, verse_number` to build the
   `verse.id → UUID` map. It uses the map to write attributions, and can save it as a
   generated report (for example `supabase/seed/generated/shloka_ids.json`, not
   hand-edited) for traceability.
3. Verses are **never deleted and re-inserted**. That would change their UUIDs and
   orphan users' local reflections. Removing a verse means setting `deleted_at` in the
   database.
4. If a verse ever has to be renumbered, that is a deliberate one-off update of
   `verse_number` on the existing row (keeping its UUID), together with renaming its
   JSON `id`.

### What gets imported

The recommended gate keeps unreviewed text out of the app:

- A chapter row is imported once its three names are filled (the database requires
  them, and verses need the row to exist). Its descriptive fields are imported only
  when the chapter is `approved`. Until then they are NULL.
- A verse is imported only when its `review_status` is `approved`.
- Attributions are imported with their verse. On re-import, missing rows are inserted
  and removed rows are deleted, because attribution rows are immutable.

### Schema changes needed in Supabase before import

| Change | Status |
|---|---|
| `shlokas.hindi_meaning_note text NULL`, plus `hindi_meaning_note` in the attribution section check | **Done** in `supabase/migrations/0001_initial_schema.sql` (not yet run on the project) |
| **A stable key for sources:** `content_sources` has only a UUID, and `name` is not unique, so `sources[].id` has nowhere to go. Recommended: add `content_sources.source_key text NOT NULL UNIQUE` (snake_case check), and upsert sources on it. The alternative is a committed `source_id → UUID` mapping file | **Needed before importing attributions.** Not done; requires a new migration |
| `review_status` | No change needed if the gate above is used. A column would only be needed to store unapproved content in Supabase |
| `verse.id` | No change needed (natural-key mapping). An optional `shlokas.content_key text UNIQUE` would make the link explicit |
