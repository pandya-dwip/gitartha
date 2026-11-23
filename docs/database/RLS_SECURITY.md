# Gitartha — Row Level Security and Permissions

This document explains how the database decides who may read and write what, and how
the project owner grants and revokes editing permission.

## The rule in one sentence

**Members can read everything shared, members whose `app_members.is_accessible = true`
can edit shared content, and nobody except the project owner (or a trusted server-side
process using the service role) can change who is a member or who can edit.**

There are no roles such as Admin, Editor or Reader. The only distinction is that one
boolean per user.

## Three layers of enforcement

PostgreSQL rejects unauthorized writes even when someone calls the Supabase REST API
directly with the app's publishable key and a valid user session. Three layers do this:

| Layer | What it does |
|---|---|
| **1. Table privileges (GRANT/REVOKE)** | Removes Supabase's default "ALL to anon/authenticated", then grants only the verbs that are needed. `anon` gets **nothing**. `authenticated` never gets DELETE on scripture tables, never gets INSERT/UPDATE/DELETE on `app_members`, and never gets TRUNCATE (TRUNCATE bypasses RLS). |
| **2. RLS policies** | Filter each permitted verb by membership or editor status, which is checked using `auth.uid()` from the verified JWT. |
| **3. Triggers** | Force server-side timestamps and forbid id changes, whatever the client sends. |

A request has to pass all three layers.

## Identity

- The user is identified **only** by `auth.uid()`, which Supabase derives from the signed
  JWT. No policy or function takes a user id from the client.
- **Anonymous sign-ins** (a Supabase feature that should stay disabled) also use the
  `authenticated` role. They are blocked twice: the provisioning trigger never creates a
  membership row for them, and both helper functions return `false` when the JWT
  contains `is_anonymous = true`.

## Helper functions

| Function | Returns `true` when |
|---|---|
| `public.is_app_member()` | the caller is not anonymous **and** has a row in `app_members` |
| `public.can_edit_shared_content()` | the caller is not anonymous **and** their own row has `is_accessible = true` |

Both are **`SECURITY INVOKER`**. The brief allowed `SECURITY DEFINER` if it was needed;
it is not needed here, so they don't use it:

- They read `app_members` as the calling user, so RLS restricts them to the caller's
  own row. Even a bug in the function could not reveal other users' rows.
- There is no recursion: `app_members`' own policy is `user_id = auth.uid()` and never
  calls these functions.
- They take **no arguments**, so they cannot be used to probe another user.
- They only read. **No function anywhere modifies permissions.** There is no RPC
  endpoint a client could use to grant itself access.
- They use a fixed empty `search_path` and schema-qualified names, so they cannot be
  hijacked by objects in other schemas.
- `EXECUTE` is revoked from `public` and `anon`, and granted to `authenticated`, which
  needs it because RLS runs policies as the caller, and to `service_role`.

Policies call them as `(select public.fn())`, so PostgreSQL evaluates the check once per
statement rather than once per row.

### The one SECURITY DEFINER function

`public.handle_new_auth_user()` is the trigger on `auth.users` that creates membership
rows. It must be `SECURITY DEFINER` because Supabase Auth inserts users as
`supabase_auth_admin`, which has no privileges on `public.app_members`. It is safe
because:

- it returns `trigger`, so it cannot be called as an RPC or as a plain function;
- `EXECUTE` is revoked from `public`, `anon` and `authenticated`;
- it uses `search_path = ''` and only schema-qualified names;
- it can only insert `(new.id, false)` for the user who was just created, and
  `ON CONFLICT DO NOTHING` means it never changes an existing row;
- it skips anonymous users.

## Policy reference

`✓` means allowed (subject to the condition), and `—` means there is no policy and no
grant, so the action is always denied.

### `app_members`

| Verb | Policy | Condition |
|---|---|---|
| SELECT | `app_members_select_own` | `user_id = auth.uid()`: own row only |
| INSERT | — | Only the provisioning trigger, the owner or the service role |
| UPDATE | — | **Nobody can change `is_accessible` from a client**, including their own and including editors |
| DELETE | — | Owner / service role only |

### `chapters`, `shlokas`, `content_sources`

| Verb | Policy | Condition |
|---|---|---|
| SELECT | `<table>_select_members` | `is_app_member()`. Returns tombstones too, which sync needs |
| INSERT | `<table>_insert_editors` | `can_edit_shared_content()` |
| UPDATE | `<table>_update_editors` | `can_edit_shared_content()` in both USING and WITH CHECK. This covers edits, **soft delete** (`deleted_at = now()`) and **restore** (`deleted_at = null`) |
| DELETE | — | No physical deletes from clients. See "Soft deletion" below |

### `shloka_source_attributions`

| Verb | Policy | Condition |
|---|---|---|
| SELECT | `shloka_source_attributions_select_members` | `is_app_member()` |
| INSERT | `shloka_source_attributions_insert_editors` | `can_edit_shared_content()` |
| UPDATE | — | Rows are immutable. Delete and re-insert instead |
| DELETE | `shloka_source_attributions_delete_editors` | `can_edit_shared_content()` |

### What a denied request looks like

- **INSERT** by a non-editor fails with `new row violates row-level security policy`.
- **UPDATE / DELETE** by a non-editor raises no error but **affects 0 rows**, because RLS
  hides the rows from the write. The Flutter client should treat "0 rows updated" as
  "not permitted".
- **DELETE on scripture tables**, any write to `app_members`, and any access by `anon`
  fail with `permission denied for table …`.

## Permission matrix (as enforced)

| Operation | Not signed in | Signed in, not a member | Member (`false`) | Member (`true`) |
|---|---|---|---|---|
| Read chapters / shlokas / sources / attributions | ✗ | ✗ (0 rows) | ✓ | ✓ |
| Add / update / soft-delete chapter | ✗ | ✗ | ✗ | ✓ |
| Add / update / soft-delete shloka | ✗ | ✗ | ✗ | ✓ |
| Manage content sources | ✗ | ✗ | ✗ | ✓ |
| Add / remove source attributions | ✗ | ✗ | ✗ | ✓ |
| Physically delete chapter / shloka / source | ✗ | ✗ | ✗ | ✗ |
| Read own membership | ✗ | ✗ (no row) | ✓ | ✓ |
| Change own permission | ✗ | ✗ | ✗ | ✗ |
| Change another user's permission | ✗ | ✗ | ✗ | ✗ |

The migration was checked against this matrix by an automated test (see "Verification"
below).

## Soft deletion

Clients have no `DELETE` privilege on `chapters`, `shlokas` or `content_sources`. To
remove content, an editor runs:

```sql
update public.shlokas set deleted_at = now() where id = '…';   -- remove
update public.shlokas set deleted_at = null  where id = '…';   -- restore
```

This bumps `updated_at`, so every device picks up the tombstone on its next sync. A
physical delete would leave no trace for offline devices to discover.

## Granting and revoking editing permission

Permissions are changed by the project owner in **Supabase Dashboard → SQL Editor**. The
SQL Editor connects as the `postgres` role, which owns the tables. RLS is *enabled* but
not *forced*, so the owner is not subject to the application's RLS policies. That
privileged access is completely separate from what the app's users can do.

### 1. Find the user's id

```sql
select id, email, created_at, last_sign_in_at
from auth.users
order by created_at desc;
```

### 2. Grant editing permission

```sql
update public.app_members
set is_accessible = true
where user_id = 'USER_UUID_HERE';
```

The same change by email:

```sql
update public.app_members m
set is_accessible = true
from auth.users u
where u.id = m.user_id
  and u.email = 'person@example.com';
```

### 3. Revoke editing permission

```sql
update public.app_members
set is_accessible = false
where user_id = 'USER_UUID_HERE';
```

### 4. Review who can edit

```sql
select u.email, m.is_accessible, m.created_at, m.updated_at
from public.app_members m
join auth.users u on u.id = m.user_id
order by m.is_accessible desc, u.email;
```

### 5. Remove a user's access entirely (they can no longer read either)

```sql
delete from public.app_members where user_id = 'USER_UUID_HERE';
-- To restore later (read-only):
insert into public.app_members (user_id) values ('USER_UUID_HERE');
```

Deleting the user in **Authentication → Users** also removes their membership
(`ON DELETE CASCADE`).

**Changes take effect immediately.** Permission is checked against the table on every
request, not stored in the JWT, so the user does not need to sign out and back in.

### Server-side automation (optional, later)

A trusted backend process may use the **service role key**, which bypasses RLS, to run
the same `UPDATE`s. That key must exist **only** on the server. Never put it in the
Flutter app, `.env` files that are bundled into the app, or source control.

## Keys: what is safe where

| Key | Where it may live | Why |
|---|---|---|
| Project URL + publishable (anon) key | Flutter app (`.env`, bundled) | Public by design. Gives only the `anon` role, which has no privileges, plus the ability to sign in |
| Service role / secret key | Never in the app. Trusted servers only | Bypasses RLS entirely |
| Database password | Owner only | Full database access |

None of these are required by, or present in, the migration SQL.

## Known limitations and risks

- **Editors are trusted with all content.** Any editor can change or soft-delete any
  verse. This is the intended single-flag model. Mitigate with Supabase backups (or
  PITR) and by granting the permission sparingly. A history/audit table could be added
  later.
- **The owner's SQL Editor session is unrestricted.** Review statements before running
  them, especially `UPDATE` and `DELETE` without a `WHERE` clause.
- **Sign-up must be disabled in the Dashboard.** RLS already denies content to
  non-members. Disabling sign-ups (see `supabase/config/DATABASE_SETUP.md`) keeps
  strangers from creating accounts in the first place, which also stops them from being
  provisioned as read-only members.

## Verification

Before handover, the migration was executed in PGlite (PostgreSQL compiled to WASM),
with a mock of Supabase's `auth` schema, roles (`anon`, `authenticated`,
`service_role`, `supabase_auth_admin`) and default privileges. 79 checks passed,
covering every row of the matrix above, the provisioning trigger, timestamp triggers,
constraints, tombstone visibility and idempotent re-runs. It has **not** been run
against the live Supabase project. Use the checks in `DATABASE_SETUP.md` after applying
it there.
