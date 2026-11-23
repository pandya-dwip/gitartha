# Gitartha — Content Validation

Validation is read-only and independent of the database. The same code
(`lib/data/content/`) runs in the CLI, in tests, and in the app (over the bundled
assets).

## Pipeline

```text
ContentSource (assets | files | test fixtures)
  → ContentAssetLoader           18 chapter files + sources.json + schemas; missing/unexpected files
  → JSON decode                  INVALID_ENCODING (BOM), INVALID_JSON
  → Level 1: JSON Schema         chapter.schema.json / sources.schema.json (Draft 2020-12)
  → typed models                 json_serializable (PARSE_FAILED if schema and model disagree)
  → Level 2: semantic checks     ChapterValidator, ShlokaValidator, SourceValidator, cross-file checks
  → completeness & review        per mode
  → ValidationResult             counts + issues (+ per-record verdicts for the importer)
```

### Level 1: JSON Schema

The schemas declare Draft 2020-12 and are used **unchanged**. Validation uses the
[`json_schema`](https://pub.dev/packages/json_schema) package (5.2.2), which implements
Draft 2020-12. Before it was adopted, it was checked against the repository's schemas
and against fixtures previously judged by Ajv. It agreed on every file, including
`$defs`/`$ref`, `const`, `uniqueItems`, `additionalProperties: false` and Unicode
patterns.

Each schema error becomes an issue with the file name, a JSONPath-style location
(`$.verses[0].hindi_meaning`) and a readable message. The schema enforces required
properties, types, allowed values, nested object shapes, array item shapes, no
unexpected properties, and the id/reference/URL formats.

### Level 2: semantic checks

These are the checks that JSON Schema cannot express:

| Check | Code |
|---|---|
| File name ↔ `chapter.id` | `CHAPTER_ID_FILENAME_MISMATCH` |
| Chapter id unique across files | `DUPLICATE_CHAPTER_ID` |
| Verse number unique in chapter | `DUPLICATE_VERSE_NUMBER` |
| Verses in ascending order | `VERSES_OUT_OF_ORDER` |
| `reference` = `<chapter>.<verse>` | `INVALID_REFERENCE` |
| `id` = `chapter_NN_verse_NNN` for this chapter/verse | `INVALID_SHLOKA_ID` |
| Verse id unique across the repository | `DUPLICATE_SHLOKA_ID` |
| Attribution `source_id` exists in sources.json | `UNKNOWN_SOURCE_ID` |
| Attribution points at a non-empty section | `ATTRIBUTION_FOR_EMPTY_SECTION` |
| Source ids unique | `DUPLICATE_SOURCE_ID` |
| `approved` content is really complete and sourced | `INCOMPLETE_CONTENT`, `MISSING_ATTRIBUTION`, `UNVERIFIED_SOURCE_LICENSE` |

## Validation modes

The rules come from `content-guidelines.md` §12 (required fields, approval
requirements) and the schema. They were not invented for the tool.

| | `structural` | `draft` (default) | `strict` |
|---|---|---|---|
| Purpose | Shape and identity only | Day-to-day authoring | Publishing / approved import |
| Schema + semantic errors | error | error | error |
| Incomplete verse or chapter metadata | counted only | **warning** | **error** |
| `approved` but incomplete or unsourced | not checked | error | error |
| Not `approved` | — | — | **error** (`NOT_APPROVED`) |
| Chapter missing verses | info | info | **error** (`MISSING_VERSES`) |
| Source without licence | — | warning | warning (error if an approved verse uses it) |

**Required for completeness:**

- a verse needs every text field except the optional `hindi_meaning_note`;
- chapter metadata needs all names, the descriptions and at least one key topic;
- an approved verse also needs attributions for `sanskrit_text`, `hindi_meaning` and
  `english_meaning`, from sources with a recorded licence.

An empty `verses` array is **incomplete content, not malformed JSON**: it is valid in
`structural` and `draft` mode.

### Content states

| State | Meaning |
|---|---|
| Structurally invalid | Fails the schema or semantic checks. An error in every mode |
| Incomplete draft | Valid, but required fields are empty |
| Awaiting verification | Complete, `draft` or `in_review`. Reported as complete but not approved |
| Approved | Complete, `approved`, sourced with verified licences. The only state approved import accepts |

## Issue format and codes

Every issue has `fileName`, `jsonPath`, `severity` (`error` / `warning` / `info`),
`code` and `message`, plus a `scope` (repository / file / chapterMetadata / verse /
source) that decides what an error blocks at import.

| Code | Severity | Meaning |
|---|---|---|
| `MISSING_FILE` | error | An expected `chapter_NN.json` is missing |
| `UNEXPECTED_FILE` | error | An extra file is in `chapters/` |
| `ASSET_LOAD_FAILED` | error | A file or schema could not be read |
| `INVALID_ENCODING` | error | The file starts with a UTF-8 BOM |
| `INVALID_JSON` | error | The file is not valid JSON |
| `SCHEMA_VALIDATION_FAILED` | error | A generic schema violation |
| `INVALID_CHAPTER_ID` | error | `chapter.id` is not 1–18 (schema) |
| `INVALID_VERSE_NUMBER` | error | `verse_number` is not a positive integer (schema) |
| `INVALID_REFERENCE` | error | A malformed reference, or one that disagrees with chapter/verse |
| `INVALID_SHLOKA_ID` | error | A malformed id, or one that disagrees with chapter/verse |
| `INVALID_CONTENT_SECTION` | error | An attribution section outside the nine allowed values |
| `MISSING_SOURCE_NAME` | error | A source without a name (schema) |
| `PARSE_FAILED` | error | A schema-valid document could not be mapped to a model |
| `CHAPTER_ID_FILENAME_MISMATCH`, `DUPLICATE_CHAPTER_ID`, `DUPLICATE_VERSE_NUMBER`, `VERSES_OUT_OF_ORDER`, `DUPLICATE_SHLOKA_ID`, `DUPLICATE_SOURCE_ID`, `UNKNOWN_SOURCE_ID`, `ATTRIBUTION_FOR_EMPTY_SECTION`, `MISSING_ATTRIBUTION` | error | See the Level 2 table above |
| `UNVERIFIED_SOURCE_LICENSE` | warning or error | A source has no licence (error when an approved verse uses it) |
| `INCOMPLETE_CONTENT` | warning (draft) or error (strict) | Required fields are empty |
| `NOT_APPROVED` | error (strict) | `review_status` is not `approved` |
| `MISSING_VERSES` | info or error (strict) | The chapter lacks some of its expected verses |
| `VERSE_NUMBER_EXCEEDS_EXPECTED` | warning | The verse number is beyond the 700-verse count (check the edition) |
| `SOURCES_UNAVAILABLE` | warning | sources.json is unusable, so references were not checked |
| `PLACEHOLDER_TEXT`, `CARRIAGE_RETURN` | warning | TODO/TBD text, or `\r` line endings |

Codes are stable. Tools and documentation may rely on them.

## Running validation

```sh
dart run tool/validate_gita_content.dart                       # draft, all chapters
dart run tool/validate_gita_content.dart --mode=structural
dart run tool/validate_gita_content.dart --mode=strict
dart run tool/validate_gita_content.dart --chapter=1 --verbose # one chapter, with info messages
dart run tool/validate_gita_content.dart --json                # JSON on stdout
dart run tool/validate_gita_content.dart --output=report.json  # JSON report file
```

| Exit code | Meaning |
|---|---|
| `0` | Valid in the chosen mode |
| `1` | Validation errors |
| `2` | Bad arguments, or the schemas could not be loaded |

The tool never modifies JSON files, never writes to any database and never contacts
Supabase. `--output` refuses paths inside the content repository. `dart run` itself
may print `Running build hooks...` to stdout, so use `--output` when another program
consumes the JSON.

In code:
`ContentRepository.validate(mode: ValidationMode.strict)`, or
`ContentValidationService(source).validate(...)`.

### Current results (all 18 files)

| Mode | Result |
|---|---|
| `structural` | Valid. 19 files (18 chapters + sources), 18 chapters, 1 verse |
| `draft` | Valid, with warnings: every chapter's metadata is incomplete, and 1.41 lacks `index_summary` |
| `strict` | Invalid (exit 1). No chapter metadata is complete or approved, 699 verses are missing, and 1.41 is a `draft` |

Verse 1.41 has no structural errors. It is incomplete only for `index_summary`, and
not approved.
