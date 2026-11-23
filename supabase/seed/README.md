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

## Where the content comes from

There is **one** content repository:
[`assets/data/bhagavad_gita/`](../../assets/data/bhagavad_gita/README.md) (18 chapter
JSON files and `sources/sources.json`). Do not keep a second copy of the scripture
here. Any Supabase seed is generated from that repository:

```text
supabase/seed/
├── README.md        this file
└── sql/             (future) generated from assets/data/bhagavad_gita, reviewed, then run
    ├── 01_sources.sql
    ├── 02_chapters.sql
    ├── 03_shlokas_chapter_01.sql
    └── …
```

- Validate first in strict mode:
  `dart run tool/validate_gita_content.dart --mode=strict`. Seed only `approved`
  content, using the same gate as the local approved import
  (`docs/content/CONTENT_IMPORT_PIPELINE.md`).
- Map fields exactly as the local import does (`""` → NULL, no `reference`, which is
  generated, and deterministic ids). See the field mapping in the content README, §9.
- The generator is a future tool. It is not implemented yet.

## Rules for the SQL

**Use the deterministic content UUIDs. Never delete and re-insert verses.** Every
verse UUID is permanent, because users' local reflections and bookmarks reference it.
Verse, source and attribution ids are the name-based UUIDs from
`lib/data/content/content_ids.dart` (for example `chapter_01_verse_041` →
`8c555087-1c57-50db-9632-7bbd1e10a472`). These are the same ids the app's local import
already uses. Generate the SQL from the JSON with those functions, and re-seed by
updating rows in place:

```sql
insert into public.chapters (id, sanskrit_name, hindi_name, english_name)
values (1, '…', '…', '…')
on conflict (id) do update set
  sanskrit_name = excluded.sanskrit_name,
  hindi_name    = excluded.hindi_name,
  english_name  = excluded.english_name;

insert into public.shlokas (id, chapter_id, verse_number, sanskrit_text, transliteration)
values ('<ContentIds.shloka(chapter_01_verse_001)>', 1, 1, '…', '…')
on conflict (id) do update set
  sanskrit_text   = excluded.sanskrit_text,
  transliteration = excluded.transliteration;
  -- only list the columns this seed file owns, so later edits to other
  -- columns are not overwritten

insert into public.shloka_source_attributions (id, shloka_id, source_id, content_section)
values ('<ContentIds.attribution(...)>', '<verse uuid>', '<ContentIds.source(key)>',
        'sanskrit_text')
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
