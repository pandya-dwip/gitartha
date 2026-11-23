# Gitartha — Seed Data

This folder will hold the scripture content: 18 chapters and 700 verses, with sources.
**It intentionally contains no content yet.** Nothing here is invented. All text must
come from a verified source whose licence permits its use.

## Before adding any content

1. **Choose one canonical edition** for verse numbering. Editions differ (for example,
   chapter 13 has 34 or 35 verses). Record the choice in this README.
2. **Clear the licence of every source.** Sanskrit text is in the public domain, but
   translations, transliterations and commentaries usually are not. For each source,
   record its licence, or the written permission obtained, in `content_sources.license`,
   and the required credit text in `content_sources.attribution`.
3. **Do not commit copyrighted text to a public repository** unless its licence allows
   redistribution.

## Recommended layout

```text
supabase/seed/
├── README.md                     this file
├── data/
│   ├── sources.json              content_sources rows
│   ├── chapters.json             18 chapter rows
│   └── shlokas/
│       ├── chapter_01.json       verses of chapter 1
│       ├── chapter_02.json
│       └── … chapter_18.json
└── sql/                          generated from data/, reviewed, then run
    ├── 01_sources.sql
    ├── 02_chapters.sql
    ├── 03_shlokas_chapter_01.sql
    ├── …
    └── 20_attributions.sql
```

Files are UTF-8 (without a BOM), and Devanagari is stored as-is, not as escape
sequences. Field names match the database columns exactly.

### `chapters.json`

```json
[
  {
    "id": 1,
    "sanskrit_name": "<from source>",
    "hindi_name": "<from source>",
    "english_name": "<from source>",
    "introduction": null,
    "overview": null,
    "central_theme": null,
    "key_topics": null,
    "summary": null,
    "conclusion": null
  }
]
```

### `shlokas/chapter_NN.json`

```json
[
  {
    "chapter_id": 1,
    "verse_number": 1,
    "index_title": null,
    "index_summary": null,
    "sanskrit_text": "<from source>",
    "transliteration": "<from source>",
    "hindi_meaning": null,
    "hindi_meaning_note": null,
    "english_meaning": null,
    "context": null,
    "life_lesson": null,
    "spiritual_meaning": null,
    "reflection_question": null,
    "sources": { "sanskrit_text": "<source key>", "transliteration": "<source key>" }
  }
]
```

- Leave out `id`, `reference`, `created_at` and `updated_at`. The database generates
  them.
- Use `null` for content that is not written yet, never `""`. Empty strings are
  rejected.
- `sources` maps each filled section to a source key from `sources.json`, and becomes
  `shloka_source_attributions` rows.

## Rules for the SQL

**Upsert by natural key. Never delete and re-insert verses.** Every verse UUID is
permanent, because users' local reflections and bookmarks reference it. Re-seeding must
update rows in place:

```sql
insert into public.chapters (id, sanskrit_name, hindi_name, english_name)
values (1, '…', '…', '…')
on conflict (id) do update set
  sanskrit_name = excluded.sanskrit_name,
  hindi_name    = excluded.hindi_name,
  english_name  = excluded.english_name;

insert into public.shlokas (chapter_id, verse_number, sanskrit_text, transliteration)
values (1, 1, '…', '…')
on conflict (chapter_id, verse_number) do update set
  sanskrit_text   = excluded.sanskrit_text,
  transliteration = excluded.transliteration;
  -- only list the columns this seed file owns, so later edits to other
  -- columns are not overwritten

insert into public.shloka_source_attributions (shloka_id, source_id, content_section)
select s.id, src.id, 'sanskrit_text'
from public.shlokas s, public.content_sources src
where s.chapter_id = 1 and s.verse_number = 1 and src.name = '…'
on conflict (shloka_id, source_id, content_section) do nothing;
```

- Wrap each file in `begin; … commit;`.
- Load in dependency order: sources, then chapters, then shlokas, then attributions.
- Run the files as the project owner in the **SQL Editor**. That bypasses RLS, which is
  correct for a reviewed import. An editor account can also insert through the API.
- Timestamps are set by triggers. Every changed row receives a new `updated_at`, so
  devices pick up the changes on their next sync.
- To retire a verse, set `deleted_at = now()`. Never `DELETE` it.

## Checks after loading

```sql
-- Verses per chapter (compare with the chosen edition; total should reach 700)
select chapter_id, count(*) as verses
from public.shlokas where deleted_at is null
group by chapter_id order by chapter_id;

select count(*) as total_verses from public.shlokas where deleted_at is null;

-- Gaps in verse numbering
select chapter_id, verse_number + 1 as missing_after
from public.shlokas s
where deleted_at is null
  and not exists (select 1 from public.shlokas n
                  where n.chapter_id = s.chapter_id and n.verse_number = s.verse_number + 1)
  and verse_number < (select max(verse_number) from public.shlokas m where m.chapter_id = s.chapter_id);

-- Filled sections without an attribution
select s.reference
from public.shlokas s
where s.sanskrit_text is not null
  and not exists (select 1 from public.shloka_source_attributions a
                  where a.shloka_id = s.id and a.content_section = 'sanskrit_text');

-- Sources whose licence is still unverified
select name from public.content_sources where license is null and deleted_at is null;
```
