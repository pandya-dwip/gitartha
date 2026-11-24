# Gitartha — Membership and Access Control

There are no roles. Each user has at most one row in `public.app_members`:

| Column | Meaning |
|---|---|
| `user_id` | `auth.users.id` |
| `is_accessible` | individual permission to modify shared scripture. `false` = read-only (default) |
| `created_at` / `updated_at` | maintained by trigger (`set_row_timestamps`) |

| Situation | Reading shared scripture | Editing shared scripture | App |
|---|---|---|---|
| no session | ✗ | ✗ | login |
| signed in, **no row** | ✗ (RLS) | ✗ | "Access unavailable" |
| row, `is_accessible = false` | ✓ | ✗ (RLS) | full reading app |
| row, `is_accessible = true` | ✓ | ✓ | same app, editing offered |

A read-only member is a normal, valid user. Nothing treats them as an authentication
failure.

## How the app reads it

After sign-in, or when a stored session is restored, the app runs:

```sql
-- what PostgREST executes for the app (RLS adds: user_id = auth.uid())
select user_id, is_accessible, created_at, updated_at
from public.app_members
where user_id = '<id from the session>';
```

- The id comes from the authenticated session, never from user input.
- The result is held in memory for that signed-in user only, never written to disk.
- It is fetched again on every sign-in, every app start with a restored session, and
  every **Try again**. A token refresh does not re-fetch it.
- "No row" and "could not check" are different states. A network failure never looks
  like a missing membership, and it never grants editing.

## Provisioning (verified in `0001_initial_schema.sql`, section 7)

`public.handle_new_auth_user()` runs `after insert on auth.users`:

- It inserts `(new.id, false)`: the id of the user just created, and always
  `is_accessible = false`.
- It never reads `raw_user_meta_data` / `raw_app_meta_data`, so crafted metadata can't
  grant editing.
- `on conflict (user_id) do nothing`: it never changes an existing row.
- It skips anonymous users.
- `SECURITY DEFINER` is required, because the trigger runs as `supabase_auth_admin`,
  which has no rights on `public.app_members`. It is hardened with
  `set search_path = ''`, fully qualified names, a `trigger` return type (so it can't be
  called as an RPC), and `EXECUTE` revoked from `public`, `anon` and `authenticated`.

No new migration was needed for Milestone 4.

## RLS (verified in `0001_initial_schema.sql`, sections 6, 8 and 9)

- `app_members`: `authenticated` has **SELECT only**, with policy
  `user_id = auth.uid()`. There is no INSERT, UPDATE or DELETE grant or policy, so no
  client can change any permission: not their own, not anyone else's, and not even an
  editor's.
- `chapters`, `shlokas`, `content_sources`, `shloka_source_attributions`: SELECT
  requires `is_app_member()`. INSERT, UPDATE (including soft delete) and, for
  attributions, DELETE require `can_edit_shared_content()`. There is no physical
  DELETE on scripture tables.
- Helper functions take **no arguments** and use `auth.uid()`. They are
  `SECURITY INVOKER`, so they only see the caller's own row, and there is no recursion,
  because the `app_members` policy doesn't call them. `search_path = ''` is fixed, and
  `EXECUTE` is limited to `authenticated` and `service_role`.
- `anon` has no table privileges at all.
- Sources and attributions require the same editor check as shlokas.

To prove this on a real database, run
`supabase/tests/rls_auth_membership_verification.sql` on an **isolated** project (local
`supabase start` or a throwaway project). It creates test users inside a transaction,
impersonates a reader, an editor, a non-member and anon, asserts every allowed and
denied operation, and then rolls everything back.

## Granting and revoking editing (project owner only)

1. Find the user's UUID: Dashboard → **Authentication → Users** → click the user → copy
   **User UID**. Or, in the SQL Editor:

   ```sql
   select id, email, created_at from auth.users order by created_at desc;
   ```

2. Run, in the **SQL Editor** (as the project owner, which is outside RLS):

   ```sql
   -- Grant
   update public.app_members set is_accessible = true  where user_id = 'USER_UUID_HERE';

   -- Revoke
   update public.app_members set is_accessible = false where user_id = 'USER_UUID_HERE';

   -- Check (updated_at is set by the trigger)
   select user_id, is_accessible, updated_at from public.app_members where user_id = 'USER_UUID_HERE';
   ```

   Check that the statement reports `UPDATE 1`. `UPDATE 0` means the UUID is wrong, or
   the user has no membership row. If so, insert one:
   `insert into public.app_members (user_id) values ('USER_UUID_HERE');`

3. Effects:
   - **RLS** applies the change to the user's very next request.
   - **The app** shows it at the next membership check: the next sign-in, the next app
     start or **Try again**. Until then, a revoked editor may still *see* editing
     controls, but every write is rejected by RLS.

Neither the app nor the publishing CLI can change permissions. Both only read the
caller's own row.
