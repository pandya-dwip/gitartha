# Gitartha — Applying the Database Schema

How to apply [`../migrations/0001_initial_schema.sql`](../migrations/0001_initial_schema.sql)
to the Supabase project and configure Auth for invitation-only access.

> **The migration has not been run against the live project.** It was validated in
> PGlite (PostgreSQL WASM) with a mocked Supabase `auth` schema and roles (see
> `docs/database/RLS_SECURITY.md` → "Verification"). Review it, then apply it yourself.

## Before you start

- A Supabase project (PostgreSQL 15 or newer, which all current projects run).
- Ideally a **fresh** project, or one without tables named `app_members`, `chapters`,
  `shlokas`, `content_sources` or `shloka_source_attributions`. The script uses
  `CREATE TABLE IF NOT EXISTS`. If a table with one of these names already exists with
  a different structure, it is left as-is and later statements may fail or behave
  unexpectedly.
- You do **not** need any API keys. Everything runs in the Dashboard.

## Step 1: Configure Auth for invitation-only access

Do this **before** sharing the app with anyone. Dashboard labels change from time to
time, so use the closest equivalent if a name differs.

1. **Authentication → Sign In / Providers → User Signups**
   - Turn **off** "Allow new users to sign up". With sign-ups disabled, only the owner
     can create accounts (by invitation or manually). Invited users can still accept
     their invitation and set a password.
   - Turn **off** "Allow anonymous sign-ins". The schema already denies anonymous users,
     but there is no reason to issue them sessions.
   - Turn **off** "Allow manual linking" unless it is needed.
2. **Authentication → Sign In / Providers → Email**: keep Email enabled, and keep
   "Confirm email" on.
3. **Authentication → Sign In / Providers**: leave every social/OAuth provider
   **disabled** unless you add one deliberately. An enabled provider can create accounts
   on first login, depending on its settings.
4. **Authentication → URL Configuration**: set the Site URL and redirect URLs to the
   app's deep link (for example `io.gitartha.app://login-callback`) once the app's auth
   milestone defines it. The invite email links there.
5. **Authentication → Emails → Templates → Invite user**: optionally customise the
   invitation text.

**Inviting someone:** Authentication → Users → **Invite user** → enter their email
address. The moment the invitation is created, the database trigger gives that account
a **read-only** membership (`is_accessible = false`).

## Step 2: Apply the migration

1. Open **SQL Editor** → **New query**.
2. Open `supabase/migrations/0001_initial_schema.sql` from this repository, copy its
   **entire** contents, and paste them into the editor.
3. Read through the script. It contains no `DROP TABLE`, no data deletion and no
   credentials. The only `DROP` statements are `DROP POLICY IF EXISTS`, used just
   before each policy is re-created.
4. Click **Run**. The script is wrapped in `BEGIN … COMMIT`, so it either applies
   completely or not at all.
5. Expect "Success. No rows returned". A notice such as
   `there is already a transaction in progress` is harmless.

The script is idempotent. Running it a second time changes nothing and does not touch
existing permissions or data.

> **If the Dashboard shows a "destructive operation" confirmation**, that is caused by
> the `DROP POLICY IF EXISTS` lines. On a first run there are no policies to drop.

## Step 3: Verify

Run each query in the SQL Editor.

```sql
-- 1. Five tables, all with RLS enabled.
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
where c.relnamespace = 'public'::regnamespace and c.relkind = 'r'
order by 1;
-- expect: app_members, chapters, content_sources, shloka_source_attributions, shlokas — all true

-- 2. Policies.
select tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
order by tablename, cmd;
-- expect 13 policies: 1 on app_members, 3 each on chapters/shlokas/content_sources,
-- 3 on shloka_source_attributions (select/insert/delete)

-- 3. anon has no table privileges.
select table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'public' and grantee = 'anon';
-- expect: 0 rows

-- 4. The provisioning trigger exists on auth.users.
select tgname from pg_trigger
where tgrelid = 'auth.users'::regclass and not tgisinternal;
-- expect: on_auth_user_created_provision_membership (possibly alongside Supabase's own)

-- 5. Every existing user has a read-only membership.
select u.email, m.is_accessible
from auth.users u
left join public.app_members m on m.user_id = u.id;
-- expect: every row has is_accessible = false (no NULLs)

-- 6. No personal-data columns exist.
select table_name, column_name
from information_schema.columns
where table_schema = 'public' and column_name ~ '(answer|response|note|bookmark)';
-- expect: 0 rows
```

### Optional: end-to-end permission check

1. Invite two test addresses that you control. Grant one of them editing permission
   (see the next section).
2. In the app (or with any Supabase client using the **publishable** key), sign in as
   each account and try to insert into `content_sources`:
   - The read-only account gets `new row violates row-level security policy`.
   - The editor account succeeds.
3. As either account, try
   `update app_members set is_accessible = true`. It must fail with
   `permission denied`.
4. Clean up in the SQL Editor:
   `delete from public.content_sources where name = '<your test name>';`
   This runs as the owner, so the physical delete is allowed.

## Granting and revoking editing permission

```sql
-- Find the user
select id, email from auth.users order by created_at desc;

-- Grant
update public.app_members set is_accessible = true  where user_id = 'USER_UUID_HERE';

-- Revoke
update public.app_members set is_accessible = false where user_id = 'USER_UUID_HERE';
```

These work because the SQL Editor runs as the table owner, which is not subject to the
app's RLS policies. App users can never run them. Further examples (by email, listing
editors, removing access entirely) are in `docs/database/RLS_SECURITY.md`.

## Do not

- Enable **Realtime** on these tables. Sync is pull-based.
- Put the **service role / secret key** in the Flutter app or in the bundled `.env`.
  The app needs only the project URL and the publishable (anon) key.
- Run `ALTER TABLE … FORCE ROW LEVEL SECURITY` on these tables. It would subject the
  owner to RLS and lock you out of permission management through the SQL Editor.
- Physically `DELETE` scripture rows to "remove" them. Set `deleted_at = now()` instead,
  or offline devices will never learn about the removal.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Inviting a user fails with "Database error saving new user" | The provisioning trigger failed. Check **Logs → Postgres**. Most likely `public.app_members` is missing because the migration did not complete. Re-run it |
| `relation "auth.users" does not exist` | The script is not running against a Supabase database |
| A signed-in user sees no content | They have no `app_members` row, or they signed in anonymously. Check query 5 above. Insert a row if needed: `insert into public.app_members (user_id) values ('…');` |
| An editor's UPDATE "succeeds" but nothing changes | They are not actually an editor: RLS reports 0 rows updated rather than an error. Check their `is_accessible` |
| `The id of a shlokas row cannot be changed` | Intended. Ids are permanent sync keys |
