# Gitartha — Content Identifier Mapping

The content repository uses readable keys. The database uses UUIDs. One function maps
the first to the second, everywhere:

**`lib/data/content/content_ids.dart` (`ContentIds`)**

It is used by the local import (Milestone 3), by the Supabase publisher (Milestone
3.1), and therefore by every device's cache and by future sync. That is how a
reflection written offline against a verse keeps pointing at the same verse after
the verse arrives from Supabase.

## Rules

| Record | Readable key | Database id |
|---|---|---|
| Chapter | `chapter.id` = `1` … `18` | `chapters.id` = the same integer |
| Verse | `chapter_01_verse_041` | `ContentIds.shloka(key)` |
| Source | snake_case key, e.g. `some_source` | `ContentIds.source(key)` |
| Attribution | (verse key, source key, section) | `ContentIds.attribution(verseKey, sourceKey, section)` |

- A key that is **already a canonical UUID** (lower-case, 36 characters) is kept as it
  is (verses and sources). The repository schemas don't currently allow UUID keys, so
  in practice every key is mapped.
- Otherwise: an **RFC 4122 version 5** (SHA-1, name-based) UUID.
- **Namespace:** `3b798233-c921-47f3-b5eb-a1bdb069565b` (`ContentIds.namespace`).
- **Names:** `shloka/<verse key>`, `source/<source key>`,
  `attribution/<verse key>/<source key>/<section>`.
- The mapping is deterministic: the same key always gives the same UUID, on every run
  and every machine. Ids are never random during import or publishing.
- The readable keys in the JSON are never changed to suit the database.

## Examples

| Key | UUID |
|---|---|
| `chapter_01_verse_041` | `8c555087-1c57-50db-9632-7bbd1e10a472` |
| source `test_source` (a test fixture) | `5c132c83-a915-50de-b00f-029b7728df60` |

The values are cross-checked against Python's standard library:

```python
import uuid
ns = uuid.UUID('3b798233-c921-47f3-b5eb-a1bdb069565b')
uuid.uuid5(ns, 'shloka/chapter_01_verse_041')   # 8c555087-1c57-50db-9632-7bbd1e10a472
```

## Guarantees and tests

- All 700 possible verse keys map to 700 distinct UUIDs. They don't collide with
  source ids, and the algorithm matches the RFC test vector
  (`uuid5(DNS, "www.example.com")`).
- The publisher's `shlokas.id` equals the local importer's `local_shlokas.id` for the
  same verse.
- Re-publishing never creates duplicates, because the upsert conflict target is this
  id.

## Never change

- the namespace UUID;
- the name prefixes and their format;
- a verse's key once it has been published. The key encodes the chapter and verse
  number, so a renumbering would be a deliberate migration that moves personal data
  to the new id.

Changing any of these would give every record a new id: duplicates in Supabase, and
personal reflections orphaned on devices.
