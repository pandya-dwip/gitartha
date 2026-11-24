# Gitartha — Invitation-Only Accounts

Gitartha is private. Nobody can create their own account: the project owner invites
people from the Supabase Dashboard. The app has no sign-up screen, and it never uses
administrative credentials.

## One-time Supabase configuration

Dashboard labels change from time to time; use the closest equivalent. These settings
can't be changed from this repository, so check each one yourself.

| Where | Setting | Value | Why |
|---|---|---|---|
| Authentication → Sign In / Providers → User Signups | Allow new users to sign up | **Off** | Blocks public `signUp`. Invitations and dashboard-created users still work: disabling sign-ups does **not** disable invites. |
| same | Allow anonymous sign-ins | **Off** | The schema already denies anonymous users |
| Authentication → Sign In / Providers → Email | Email provider | **On** | Email + password sign-in |
| same | Confirm email | **On** | Accounts must prove the address |
| Authentication → Sign In / Providers | Social / OAuth providers | **Off** | Some providers create accounts on first login |
| Authentication → URL Configuration → Redirect URLs | add | `com.gitartha.gitartha://auth-callback` | Password-reset links return to the app. If the URL isn't listed, Supabase falls back to the Site URL. |
| Authentication → URL Configuration → Site URL | | `com.gitartha.gitartha://auth-callback` (or your own web page) | Where invitation links land after confirmation |
| Authentication → Emails → SMTP | custom SMTP | recommended | The built-in sender is heavily rate-limited |

The scheme `com.gitartha.gitartha` is registered in
`android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`. The full URL is
`SupabaseAuthRepository.authRedirectUrl`. If you change one, change all three, and the
Dashboard.

## Inviting a person

1. Dashboard → **Authentication → Users → Invite user** → enter their email.
2. The moment the user record is created, the database trigger
   `on_auth_user_created_provision_membership` gives them a **read-only** membership
   (`is_accessible = false`). There is nothing else to do for reading access.
3. They receive the invitation email and open the link. This confirms their address.
   If the Site URL is the app's deep link and they open the email on their phone, the
   app opens already signed in.
4. **Setting a password:** in the app, on the sign-in screen, they tap
   **Forgot password?**, enter their email, open the reset link **on the same device**,
   and choose a password. From then on they sign in with email and password.
5. To let them edit shared scripture as well, see
   [MEMBERSHIP_ACCESS_CONTROL.md](MEMBERSHIP_ACCESS_CONTROL.md).

Alternative: Dashboard → **Add user → Create new user**, with "Auto confirm" ticked, and
a temporary password that you share privately. Ask them to change it straight away with
**Forgot password?**. The trigger still creates a read-only membership.

## Verifying the configuration

- With sign-ups off, a direct `signUp` call made with the publishable key must fail
  with "Signups not allowed for this instance". The app never makes that call.
- Invite a test address you control and confirm three things: it receives the email,
  `select * from public.app_members where user_id = '<id>'` shows
  `is_accessible = false`, and the account can sign in after setting a password.

## Removing a person

Dashboard → Authentication → Users → the user → **Delete user**. The `app_members` row is
removed with them (`on delete cascade`). To keep the account but stop all access,
delete only the membership:

```sql
delete from public.app_members where user_id = 'USER_UUID_HERE';
```

The app then shows "Access unavailable" at the next membership check (the next sign-in,
app start or **Try again**). RLS stops their reads immediately.
