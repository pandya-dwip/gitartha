# Gitartha — Accounts: Registration and Invitations

People can get an account in two ways:

1. **Self-registration in the app** (added after Milestone 6). The *Create an account*
   screen calls Supabase Auth `signUp` with the publishable key. Supabase creates the
   `auth.users` record. The database trigger `on_auth_user_created_provision_membership`
   then gives the new account a **read-only** membership (`app_members.is_accessible =
   false`). The app never writes to `app_members`, and nothing a registrant enters can
   grant editing permission: their name is stored as Auth metadata, which the trigger
   ignores.
2. **Invitation by the owner**, from the Supabase Dashboard, as before.

Editing permission is still granted only by the project owner
([MEMBERSHIP_ACCESS_CONTROL.md](MEMBERSHIP_ACCESS_CONTROL.md)).

> **Consequence:** anyone who has the app can register and then **read** the shared
> scripture. They cannot change it. To return to invite-only, turn sign-ups off in the
> Dashboard. The app then shows "New registrations are not open right now" on the
> registration screen.

## One-time Supabase configuration

Dashboard labels change from time to time; use the closest equivalent. These settings
can't be changed from this repository, so check each one yourself.

| Where | Setting | Value | Why |
|---|---|---|---|
| Authentication → Sign In / Providers → User Signups | Allow new users to sign up | **On** for in-app registration (**Off** = invite-only) | Off blocks the app's *Create an account* (it shows "registrations are not open"). Invitations work either way. |
| same | Allow anonymous sign-ins | **Off** | The schema already denies anonymous users |
| Authentication → Sign In / Providers → Email | Email provider | **On** | Email + password sign-in |
| same | Confirm email | **On** (recommended) | New accounts must open the confirmation link (on the same phone; it returns to the app). With it off, registration signs the user in immediately |
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
