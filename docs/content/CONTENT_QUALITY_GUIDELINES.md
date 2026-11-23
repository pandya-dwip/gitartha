# Gitartha — Content Quality Guidelines

The **canonical editorial rules** are in
[`assets/data/bhagavad_gita/schema/content-guidelines.md`](../../assets/data/bhagavad_gita/schema/content-guidelines.md),
which sits next to the content its authors edit. This page doesn't repeat them. It shows
**which rules the pipeline enforces automatically, and which need a human reviewer**,
so nobody mistakes a passing validator for a reviewed verse.

## Enforced automatically

| Rule (guidelines §) | Enforced by | Code |
|---|---|---|
| Fixed structure: every key present, no extra keys (§3 of README) | JSON Schema | `SCHEMA_VALIDATION_FAILED` |
| No leading or trailing whitespace, empty means `""` (§10) | JSON Schema | `SCHEMA_VALIDATION_FAILED` |
| Ids, references, chapter and verse numbers consistent | Semantic checks | see `CONTENT_VALIDATION.md` |
| Wording notes kept out of the translation (§4) | Separate field `hindi_meaning_note`, separate column | — |
| Attributions only for sections that have text (§11) | Semantic checks | `ATTRIBUTION_FOR_EMPTY_SECTION` |
| Sources must exist (§11) | Semantic checks | `UNKNOWN_SOURCE_ID` |
| An approved verse has every required field (§12) | Semantic checks | `INCOMPLETE_CONTENT` |
| An approved verse cites sources for Sanskrit, Hindi and English (§11) | Semantic checks | `MISSING_ATTRIBUTION` |
| An approved verse uses only licensed sources (§4, §11) | Semantic checks | `UNVERIFIED_SOURCE_LICENSE` |
| Only approved content is imported as verified (§12) | Approved import (strict) | `NOT_APPROVED` |
| UTF-8 without BOM, `\n` line endings, no placeholders (§2, §10) | Parser and hygiene checks | `INVALID_ENCODING`, `CARRIAGE_RETURN`, `PLACEHOLDER_TEXT` |

## Not checkable by software: the reviewer's job

A clean validation report means the content is **well-formed and complete**. It never
means the content is **correct**. Before setting `review_status: "approved"`, a person
must verify:

- the Sanskrit, character by character, against the cited source (§2);
- that the transliteration is consistent IAST and matches the Sanskrit line by line
  (§3);
- that the translations are faithful and their licence really permits use (§4);
- that the context invents no history and attributes views to the right speaker (§5);
- that life lessons and spiritual meaning read as interpretation, not as literal
  scripture, and acknowledge other readings where appropriate (§6–§7);
- that the reflection question is open, specific and relevant (§8).

Machine-generated drafts (AI, OCR or converters) stay `draft` until a person has
verified every field (§12).

## Worked example: Verse 1.41

| Aspect | Status |
|---|---|
| Structure | Valid |
| Wording note | Present, in `hindi_meaning_note`, separate from the Hindi translation |
| Completeness | Missing `index_summary` (the supplied sample has none, and none was invented) |
| Sources | None recorded, so it cannot be approved yet |
| Review | `draft` |
| Draft import | Imported locally for development |
| Approved import | Rejected (not approved, incomplete, unsourced) |

To publish it: add a verified `index_summary`, record its real sources with licences
and the `source_attributions` for `sanskrit_text`, `hindi_meaning` and
`english_meaning`, have it reviewed, and then set `approved`.
