# Gitartha — Publisher Authentication and Permission

The publisher acts as a normal Gitartha member. There are no special keys and no
bypass of Row Level Security.

## Configuration

These are read from the environment, or from `.env` in the project root (the
environment wins). `--env-file=PATH` selects another file.

| Variable | Required | Value |
|---|---|---|
| `SUPABASE_URL` | yes | `https://<project-ref>.supabase.co` (https, or http only for localhost) |
| `SUPABASE_PUBLISHABLE_KEY` | yes* | the project's **publishable** key (`sb_publishable_…`) |
| `SUPABASE_ANON_KEY` | *fallback | the app's existing legacy anon key, used only if the variable above is empty |

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_<placeholder>
```

**Refused:** `sb_secret_…` keys and legacy JWTs with `role: service_role`. The tool
exits with code 2 and never prints the key. The tool never reads a database password,
a connection string or a service-role variable, and a test asserts that the
publishing code doesn't reference them.

The publishable key only identifies the project. It grants nothing by itself: anon has
no privileges in the schema.

`.env` is git-ignored (`.gitignore`: `.env`, `.env.*`, `!.env.example`).
`.env.example` has placeholders only. The app also bundles `.env`, which is one more
reason it may only ever hold publishable values.

## Sign-in

```text
Sign in as an existing Gitartha member.
Email: you@example.com
Password:                ← typed without echo
Authenticating...
Authentication successful. Publishing permission confirmed.
```

- Password sign-in through Supabase Auth, with the pure-Dart `supabase` client.
- The password is read with terminal echo turned off. It is never an argument, never
  read from `.env`, never printed or logged, and never stored in reports. The tool
  drops its reference immediately after sign-in.
- If input is not an interactive terminal (a pipe, CI, some Git Bash setups), the
  tool refuses to ask for a password (exit 3). Use PowerShell, Windows Terminal or
  cmd, or `winpty dart run …` in Git Bash.
- The session lives **in memory for this process only**: the Dart client persists
  nothing, and token auto-refresh is off. At the end of every run, including
  failures, the tool signs out and disposes of the client.
- No users are created, and no other authentication system exists.

| Failure | Message |
|---|---|
| Wrong email or password | `Invalid email or password.` |
| Unconfirmed invitation | `This account has not confirmed its email address yet…` |
| No network | `Could not reach Supabase Auth. Check your connection.` |
| Auth unavailable / rate-limited | `Supabase Auth is unavailable right now…` / `Too many sign-in attempts…` |
| Session expired mid-run | `Your session expired or is invalid. Run the command again.` |

Server responses are never echoed raw.

## Permission check

After sign-in, the tool reads **only your own** `app_members` row (RLS policy
`app_members_select_own`):

```text
own row exists? ── no ──▶ denied
is_accessible?  ── no ──▶ denied
                   yes ─▶ continue (dry run or publish)
```

Denial looks like this (the same for both cases):

```text
Publishing permission denied.

Your account does not have permission to modify shared scripture content.

Contact the project owner if you require publishing access.
```

- Signing in successfully is **not** permission.
- The tool cannot change `is_accessible`, for you or anyone else. It has no write path
  to `app_members` at all. The project owner grants the permission in the SQL Editor
  (`docs/database/RLS_SECURITY.md`).
- **RLS stays the final authority.** Every write carries your session, and Supabase
  checks `can_edit_shared_content()` on each one. If your permission is revoked
  mid-run, the next write is rejected (`42501`), and the run stops and reports what
  happened.
- No policy changes were needed. The existing `app_members_select_own` policy already
  lets you read your own row.
