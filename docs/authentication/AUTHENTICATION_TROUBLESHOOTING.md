# Gitartha — Authentication Troubleshooting

| What the user sees | Likely cause | Fix |
|---|---|---|
| "Sign-in is not available: the app is not connected to its server." | `.env` has no `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY`, or `Supabase.initialize` failed (see the debug log "Supabase failed to initialize") | Fill in `.env` from `.env.example` and rebuild. `.env` is bundled at build time. |
| App fails to start with `ConfigurationException` | Half-filled Supabase values, non-https URL, missing values in `production`, or a secret / service-role key | Follow the message. Use only the **publishable** key. |
| "Invalid email or password." | Wrong credentials, **or no such user**. Supabase deliberately gives the same answer for both. | Check the address. Use **Forgot password?**. The owner can check Authentication → Users. |
| "This account has not confirmed its email address yet…" | The invitation wasn't accepted | Open the invitation email first, or ask the owner to re-send it |
| "This account is disabled…" | The user is banned in Supabase Auth | Owner: Authentication → Users → unban |
| "Too many attempts…" | Auth rate limit (sign-in or email sending) | Wait. For emails, configure custom SMTP. |
| "Could not reach the server…" | No network, DNS, captive portal | Retry when online |
| "The sign-in service is unavailable right now…" | Supabase Auth 5xx | Check the Supabase status page; retry later |
| **Access unavailable** | Signed in, but no `app_members` row | Owner: `insert into public.app_members (user_id) values ('<uuid>');`, then the user taps **Try again** |
| **Could not check access** | Membership lookup failed: network, an expired session that couldn't refresh, or a malformed row | **Try again**. If it persists, sign out and in. Owner: check the row exists and `is_accessible` is not null. |
| Shows "Read-only access" after editing was granted | The app checks membership at sign-in, at app start and on **Try again**, not continuously | Restart the app, or sign out and in |
| Shows "Editor access" after editing was revoked | Same as above. Writes are already rejected by RLS. | Restart the app, or sign out and in |
| Reset link opens a browser page, not the app | Redirect URL not allow-listed (Supabase fell back to the Site URL), or the link was opened on another device | Add `com.gitartha.gitartha://auth-callback` to Redirect URLs. Open the link on the phone that requested it. |
| Reset link opens the app but nothing happens | The link was already used or has expired, or the PKCE verifier is missing (requested on another device, or the app data was cleared) | Request a new link from the same device |
| "That password is too weak…" | The project's password policy | Use a longer password. The policy is set in Authentication → Sign In / Providers → Email. |
| Signed out unexpectedly | The refresh token was revoked or expired (password changed elsewhere, user deleted, or a long time offline) | Sign in again. Local data is untouched. |

## Developer checks

```bash
flutter test test/unit/features/authentication test/unit/app test/widget
flutter analyze
```

- Tests never contact Supabase. They use `FakeAuthRepository`, or a mocked HTTP client
  under the real `SupabaseAuthRepository`.
- Real RLS verification: run `supabase/tests/rls_auth_membership_verification.sql` on
  an **isolated** project. It rolls back. A failure names the check, e.g.
  `FAIL reader: updated a chapter`.
- Manual end-to-end check on a device (test project): invite two addresses, grant one
  editing, then sign in as each. Confirm "Read-only access" and "Editor access". Sign
  out, kill and reopen the app, and confirm it opens on login. Sign in, kill and reopen,
  and confirm it goes straight to the app. Turn on airplane mode, reopen, and confirm
  "Could not check access" and that **Sign out** works.

## Never do this to "fix" access

- Don't put a `service_role` / `sb_secret_` key in `.env`. The app refuses it, and it
  would bypass RLS for anyone who unpacks the app.
- Don't add an INSERT or UPDATE policy on `app_members` for `authenticated`.
- Don't enable public sign-ups to work around invitation problems.
