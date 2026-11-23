# Gitartha — Content Accuracy and Editorial Guidelines

These rules apply to every chapter and verse in this repository, whoever writes it,
whether a person or a tool. The goal is content that is **accurate, sourced and clearly
labelled** for what it is. Volume and uniformity come second.

## 1. Keep each kind of content separate

Every verse has separate fields for each kind of content. Never mix one kind into
another.

| Field | Contains | Does **not** contain |
|---|---|---|
| `sanskrit_text` | The original verse, exactly as in the verified source | Corrections, commentary, translation |
| `transliteration` | IAST romanisation of that exact Sanskrit | Translation, simplified spellings |
| `hindi_meaning` | A Hindi translation | Commentary, modern reinterpretation, notes |
| `hindi_meaning_note` | *Optional.* A note on historical, linguistic or interpretive points in the wording | The translation itself |
| `english_meaning` | An English translation | Commentary, modern reinterpretation |
| `context` | Who is speaking, to whom, what led up to the verse, and why it matters in the chapter | Life lessons, invented history |
| `life_lesson` | A practical lesson for everyday life, connected to this verse | Claims that the lesson *is* the literal meaning |
| `spiritual_meaning` | The philosophical and spiritual interpretation | Presentation of one school's view as the only one |
| `reflection_question` | One open question for the reader | Answers, leading questions |

**Never present a modern interpretation as if it were the literal meaning of the
Sanskrit.** Interpretation belongs in `context`, `life_lesson` and `spiritual_meaning`,
and should read as interpretation ("This verse invites us to…", "Many commentators read
this as…").

## 2. Sanskrit accuracy

- Copy the verse from a reliable, recorded source (`sources/sources.json`) and attribute
  it (`content_section: "sanskrit_text"`).
- Preserve the Devanagari exactly: conjuncts, avagraha (ऽ), punctuation (।, ॥) and the
  verse ending with its number (for example `॥ १.४१॥`).
- **Do not silently correct the Sanskrit.** If you think the source has an error, leave
  the text unchanged and raise it with a reviewer. If a reading is changed after
  checking a second source, attribute that source too.
- Separate the two half-verses (*pāda* pairs) with a single line break (`\n`), as in the
  source layout.
- Use Unicode Devanagari only, normalised to NFC. Never use legacy font encodings,
  images or transliteration in this field.
- **Do not use machine-generated Sanskrit** (OCR, AI or transliteration converters)
  unless a person has checked every character against the source.

## 3. Transliteration

- Use **IAST** consistently: ā ī ū ṛ ṝ ḷ ṃ ḥ ṅ ñ ṭ ḍ ṇ ś ṣ. Do not mix in Harvard-Kyoto,
  ITRANS or ad-hoc spellings ("sh", "aa").
- It must correspond to the Sanskrit in `sanskrit_text`, line for line.
- Choose one convention for hyphenating compounds (for example `kula-striyaḥ`) and for
  capitalising names and verse beginnings, and keep to it across all verses.
- Do not include asterisks or other formatting marks. The app styles this field itself.

## 4. Hindi and English translations

- A translation translates. It does not explain, soften or modernise. Explanations go in
  the wording note or in `context`.
- Attribute every translation to its real source. If the Gitartha team writes its own
  translation, record it as a source too, for example a source named after the
  Gitartha editorial translation, with its author and licence.
- **Check usage rights before copying any published translation.** Most modern
  translations are under copyright. The source must have a verified `license` before
  any verse using it can be approved.
- Paraphrasing a copyrighted translation closely is still copying it.

### The Hindi wording note (`hindi_meaning_note`)

Use it when the reader needs help with the wording itself:

- historically significant terms (for example *varṇa-saṅkara*, *kula-striyaḥ*);
- words whose meaning has changed, or that carry social assumptions of their time;
- notable differences between translations or commentators.

Keep it factual and brief, and never put translation text in it. Leave it `""` when
nothing needs explaining. Most verses will not need one.

## 5. Context: what is happening here?

Explain:

- **who is speaking** and **to whom**;
- **what happened just before** this verse;
- **what is happening** in the dialogue at this point;
- **why the verse matters** within the chapter's argument.

Do not invent historical details, dates, emotions or events that the text or a cited
commentary does not support. When the text shows a character's view (for example
Arjuna's fears in Chapter 1), say clearly that it is *that character's* view, not the
Gita's final teaching.

## 6. Life lessons

- Make the lesson understandable in modern everyday life.
- **Tie it to this verse.** A reader should be able to see how the lesson follows from
  the verse.
- Avoid generic motivational lines ("Believe in yourself", "Stay positive") that could
  be attached to any verse.
- Make clear that it is a practical application, not the literal scripture.

## 7. Spiritual meaning

- Explain the philosophical meaning in accessible language.
- Keep key Sanskrit concepts and explain them where they first matter: *Dharma*,
  *Karma*, *Yoga*, *Ātman*, *Brahman*, *Mokṣa*, *Bhakti*, *Jñāna* and others.
- **Acknowledge differences in interpretation** where they exist (for example Advaita,
  Viśiṣṭādvaita and Dvaita readings, or the readings of different commentators), and
  don't present one school as the only view.
- If the explanation follows a particular commentator, attribute that source.

## 8. Reflection questions

Each question should:

- be **relevant to this verse** and its lesson;
- be **open-ended**, with no right answer and no yes/no question;
- encourage **independent thinking**, without steering the reader towards an expected
  answer;
- connect the verse's idea to a **real situation** in the reader's life;
- be **specific**: avoid stock questions repeated across verses ("What did you learn
  from this verse?").

One question per verse.

## 9. Length and depth

**Verses do not all need the same amount of text.** Some need long historical context
or a wording note, and others need only a few sentences. Accuracy and clarity matter
more than uniform word counts. Do not pad text to look complete.

## 10. Text formatting conventions

All fields are plain UTF-8 text with a very small formatting vocabulary:

| Need | Write |
|---|---|
| Line break (Sanskrit / transliteration lines) | `\n` |
| New paragraph (prose fields) | `\n\n` (one blank line) |
| Emphasis for a Sanskrit or technical term in prose | `*term*` |

Do not use other Markdown, HTML, emoji or leading/trailing spaces. Empty fields are `""`
(the database stores them as NULL). Use straight quotes or typographic quotes, but use
the same style throughout the repository.

## 11. Sources and attribution

- Add a source to `sources/sources.json` only when it is **real and verified**: you have
  seen it, and the name, author and URL are correct. Never invent books, authors,
  publishers, URLs or licences.
- Source `id`s are permanent snake_case keys (for example `gita_press_<edition>`).
  Never rename one once it is used.
- Add a verse attribution **only** for sections that actually came from that source.
  An attribution on an empty section is an error.
- The scripture and its translations (`sanskrit_text`, `hindi_meaning`,
  `english_meaning`) must each have at least one attribution before a verse can be
  approved.
- Original Gitartha writing (context, life lessons, reflection questions) does not need
  an external source. Attribute it if it draws on a commentary.

## 12. Review workflow

Every chapter and verse has a `review_status`, which **people** set:

| `review_status` | Meaning | Who sets it |
|---|---|---|
| `draft` | Being written. Anything may be missing | Author |
| `in_review` | Author believes it is complete and has asked for review | Author |
| `approved` | A reviewer has checked it against the sources and these guidelines | Reviewer (ideally not the author) |

The validator (`tool/validate_gita_content.dart`) combines this status with what is
actually filled in, which gives four levels:

| Level | Meaning | Determined by |
|---|---|---|
| 1. **Valid structure** | The file parses and matches the schema. Required for every commit | Schema + validator (errors otherwise) |
| 2. **Incomplete** | Structurally valid, but some required field is empty | Validator (fine for drafts) |
| 3. **Ready for review** | All required fields are filled. Not yet approved | Validator |
| 4. **Approved** | Status `approved`, all required fields filled, required sections attributed to sources with verified licences | Reviewer's status, which the validator enforces |

The required fields for a verse are all text fields except the optional
`hindi_meaning_note`. For chapter metadata they are all fields, including at least one
key topic.

A **chapter is publication-ready** only when its metadata is approved and every verse
from 1 to the chapter's expected count is present and approved. An empty chapter is
never publication-ready.

Reviewers check, at minimum: the Sanskrit against the source, character by character;
that the transliteration matches; that the translations are faithful and properly
licensed; that no interpretation is presented as literal meaning; and that no invented
historical claims are made.

Any **machine-assisted draft** (AI, OCR, converters) stays `draft` until a person has
verified every field. Being machine-generated is never grounds for approval.
