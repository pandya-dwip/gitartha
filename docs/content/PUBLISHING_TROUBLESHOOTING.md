# Gitartha — Publishing Troubleshooting

| Symptom (exit code) | Cause and fix |
|---|---|
| `Choose a scope: --all or --chapter=N.` (2) | Add `--all` or `--chapter=N` |
| `--all and --chapter are mutually exclusive.` (2) | Use one of them |
| `--verse requires --chapter.` / `--verse=… is beyond the … verses` (2) | Give the chapter, and a verse number within it |
| `Credentials are never accepted as arguments.` (2) | Remove `--password`/`--email`. You will be asked for them |
| `SUPABASE_URL is not set` / `SUPABASE_PUBLISHABLE_KEY is not set` (2) | Add them to `.env` (see `.env.example`), or pass `--env-file=PATH` |
| `SUPABASE_URL must use https` (2) | Use the `https://<ref>.supabase.co` URL |
| `… contains a secret / service-role key … refuses privileged keys` (2) | You configured a secret key. Replace it with the **publishable** key, and rotate the secret key if it may have leaked |
| `Validation found N blocking error(s)` (1) | Fix the listed `[CODE] file $.path` errors. Run `dart run tool/validate_gita_content.dart --chapter=N --verbose` for detail |
| `Nothing is publishable in this scope yet` (0) | No verse in scope is complete, approved and sourced, or the chapter has no names. See `content-guidelines.md` §12 |
| `An interactive terminal is required…` (3) | Run from PowerShell, Windows Terminal or cmd, or `winpty dart run tool/publish_gita_content.dart …` in Git Bash |
| `Invalid email or password.` (3) | Check the credentials of your Supabase Auth user |
| `…has not confirmed its email address yet…` (3) | Accept the invitation email first |
| `Could not reach Supabase Auth` / `Supabase did not respond` (3/4) | Network problem. Check your connection and the project status |
| `Publishing permission denied.` (3) | Your `app_members` row is missing or `is_accessible = false`. Ask the project owner (`docs/database/RLS_SECURITY.md`) |
| `Supabase table "shlokas" does not have the expected columns…` (4) | The live schema differs from `0001_initial_schema.sql` (for example, `hindi_meaning_note` is missing). Apply the migration, then retry |
| `VERSE_SLOT_CONFLICT … already exists remotely with a different id` (1) | A verse was created in Supabase outside this tool. Check that row in the SQL Editor (soft-delete or correct it), then re-run the dry run |
| `REMOTE_SOFT_DELETED` in the preview (warning) | The record was retired in Supabase. Publishing never restores it. Restore it in the SQL Editor (`update … set deleted_at = null`) if that is intended |
| `REMOTE_ONLY_ATTRIBUTION` (warning) | An attribution exists in Supabase but not in the files. It is left in place. Remove it in the SQL Editor if it is wrong |
| `OUTSIDE_VERSE_SCOPE` (warning) | The chapter metadata differs remotely, but you used `--verse`. Publish the chapter without `--verse` to update it |
| `Row Level Security rejected the request` during publishing (4) | Your permission was revoked, or the policy does not allow the write. The run stops. Check your membership |
| `Your session expired…` (4) | Re-run. The session is not kept between runs |
| `Supabase is rate-limiting requests` (4) | Wait a minute, then re-run. Finished records are skipped automatically |
| `partially_completed` (4) | Some writes failed (listed with reasons). Fix the cause and **re-run the same command**: completed records are unchanged and only the rest are sent |
| The preview shows updates on every run | It shouldn't, because content is compared without timestamps. Check for a trailing-space or normalization difference in the JSON, then compare the record's fields in Supabase |
| `Running build hooks...` appears in output | Printed by `dart run` itself (the `sqlite3` native assets). It is harmless |

## Checking the result in Supabase

In the SQL Editor (owner):

```sql
select id, reference, updated_at from public.shlokas
where chapter_id = 1 order by verse_number;

select a.content_section, s.name
from public.shloka_source_attributions a
join public.content_sources s on s.id = a.source_id
where a.shloka_id = '8c555087-1c57-50db-9632-7bbd1e10a472';   -- verse 1.41
```

The verse UUIDs are listed in `CONTENT_ID_MAPPING.md` (compute others with
`ContentIds.shloka`).
