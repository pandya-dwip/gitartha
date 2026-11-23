# Gitartha — Bhagavad Gita Content Repository

The scripture lives in source-controlled JSON files under `assets/data/bhagavad_gita/`.
They are the **only** copy: the local database and (later) Supabase are filled from
them by the import pipeline ([`CONTENT_IMPORT_PIPELINE.md`](CONTENT_IMPORT_PIPELINE.md)).

> **Current content:** 18 chapter files, all with empty metadata. The only verse is
> **Chapter 1, Verse 41**, a `draft` supplied by the project owner. There are no
> sources yet. Nothing else has been written, and nothing has been invented.

## Structure

```text
assets/data/bhagavad_gita/
├── README.md                     detailed format reference (fields, import mapping)
├── schema/
│   ├── chapter.schema.json       JSON Schema (Draft 2020-12) for chapter files  [bundled]
│   ├── sources.schema.json       JSON Schema for sources.json                   [bundled]
│   └── content-guidelines.md     editorial rules (canonical)
├── chapters/chapter_01.json … chapter_18.json                                    [bundled]
└── sources/sources.json                                                          [bundled]
```

`pubspec.yaml` bundles the chapters, the sources and the two schemas as Flutter
assets, so the app can validate and import offline. The Markdown files are not bundled.

## JSON format

The authoritative reference is
[`assets/data/bhagavad_gita/README.md`](../../assets/data/bhagavad_gita/README.md)
(§2–§6). In short, each chapter file looks like this:

```json
{
  "schema_version": "1.0.0",
  "chapter": {
    "id": 1, "sanskrit_name": "", "hindi_name": "", "english_name": "",
    "introduction": "", "overview": "", "central_theme": "", "key_topics": [],
    "summary": "", "conclusion": "", "review_status": "draft"
  },
  "verses": [ { "id": "chapter_01_verse_041", "verse_number": 41, "reference": "1.41", "…": "…" } ]
}
```

- Every key is always present. `""` (or `[]`) means "not written yet".
- `review_status` (`draft` / `in_review` / `approved`) records the human review
  decision. Only people set it.
- `hindi_meaning` is the translation. `hindi_meaning_note` is an optional, separate
  note on the wording.

### Typed models

`lib/data/content/models/` mirrors the format with `json_serializable` classes:

| JSON | Dart |
|---|---|
| chapter file | `ChapterContentModel` (`schemaVersion`, `chapter`, `verses`) |
| `chapter` object | `ChapterMetadataModel` |
| verse | `ShlokaContentModel` |
| `source_attributions[]` entry | `SourceAttributionModel` (`sourceId`, `contentSection`) |
| `sources.json` / a source | `SourcesFileModel` / `SourceContentModel` |
| `review_status`, `content_section` | `ReviewStatus`, `ContentSection` enums |

Empty strings are read as `null` and written back as `""`, so a parsed file serializes
to exactly its original JSON (this is tested on Verse 1.41).

## Stable identifiers

| Content key | Database id |
|---|---|
| chapter `1` | `chapters.id = 1` (the chapter number) |
| verse `chapter_01_verse_041` | `ContentIds.shloka('chapter_01_verse_041')` = `8c555087-1c57-50db-9632-7bbd1e10a472` |
| source `some_source` | `ContentIds.source('some_source')` |
| attribution | `ContentIds.attribution(verseKey, sourceKey, section)` |

These are RFC 4122 version 5 UUIDs under a fixed Gitartha namespace
(`lib/data/content/content_ids.dart`). They are cross-checked against Python's
`uuid.uuid5`. Every device and every import produce the same ids, and the future
Supabase import must use them too. **Never change the namespace.**

## Adding a verse

Example: the existing sample, Chapter 1, Verse 41.

1. Open `chapters/chapter_01.json`, and insert the verse at the position that keeps
   `verse_number` ascending.
2. Set `"id": "chapter_01_verse_041"`, `"verse_number": 41` and `"reference": "1.41"`.
3. Fill only verified or properly written fields (content guidelines). Leave the rest
   `""`. Keep wording notes in `hindi_meaning_note`, never inside `hindi_meaning`.
4. Add any new sources to `sources/sources.json` (real, verified, with licence), and
   record per-section `source_attributions`.
5. Keep `review_status: "draft"`. Set `in_review` when complete. A reviewer sets
   `approved`.
6. Validate: `dart run tool/validate_gita_content.dart --chapter=1 --verbose`.

For 1.41 today, that reports one warning: `INCOMPLETE_CONTENT … empty: index_summary`.
The sample was supplied without an index summary, and none has been invented.

## Adding a chapter

All 18 files exist. "Adding" a chapter means filling its metadata: three names from a
verified source, introduction, overview, central theme, key topics, summary and
conclusion. Never create, rename or split chapter files. The validator rejects anything
other than `chapter_01.json` … `chapter_18.json`.
