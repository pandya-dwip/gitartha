# Gitartha — Sessions, Logout and Password Recovery

## Configuration

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_<placeholder>
```

- The variables are read by `AppConfig` (`lib/core/config/app_config.dart`).
  `SUPABASE_ANON_KEY` is still accepted as a legacy name, used only when
  `SUPABASE_PUBLISHABLE_KEY` is empty. The publishing CLI reads the same variables.
- Validation happens at startup. The app fails clearly on a half-filled pair, a
  non-https URL (except localhost), a missing backend in `production`, or a
  secret / service-role key.
- `.env` is git-ignored and bundled into the app. It must never hold a secret key or a
  database password.

## Session storage and restoration

- Supabase Auth issues a short-lived access token and a refresh token.
  `supabase_flutter` refreshes the access token automatically while the app runs.
- The session is persisted by `SecureSessionStorage` (`flutter_secure_storage`): the
  iOS Keychain, or Android Keystore-encrypted storage. It isn't kept in plain
  SharedPreferences.
- On launch, `Supabase.initialize` restores the stored session before the first frame.
  If a session exists, the user goes straight to the membership check and into the app,
  without logging in again.
- Expired access token at launch: Supabase refreshes it. If the refresh token is
  invalid or revoked, Supabase signs out locally, and the app shows the login screen.
- Offline at launch with a stored session: the user stays signed in. The membership
  check fails with a network error, and the app shows **Could not check access** with
  **Try again** and **Sign out**. It does not treat the user as a non-member and does
  not grant editing.
- Passwords and tokens are never logged. Error messages shown to users are fixed texts
  (`AuthFailureKind`), never raw server responses.

## Auth events

`AuthController` holds the app's only subscription to `onAuthStateChange`. It is
created once and cancelled when the provider container is disposed.

| Supabase event | App reaction |
|---|---|
| `initialSession` / `signedIn` | user set, then membership fetched |
| `tokenRefreshed` / `userUpdated` | user kept; membership **not** re-fetched |
| `passwordRecovery` | user set, and recovery mode is turned on, so the app routes to `/reset-password` |
| `signedOut` (logout, revoked or expired refresh) | user cleared, and the app routes to `/login` |
| stream error | session re-read; signed out if it is gone |

## Logout

`AuthController.signOut()` → `supabase.auth.signOut()`:

- The local session is removed, and `signedOut` is emitted, **before** the server is
  contacted. Logout therefore works offline. If the server-side revoke fails, the
  failure is logged and ignored.
- The in-memory user and membership are cleared, and the router leaves every
  authenticated route at once.
- **No local data is deleted.** Logout never touches the SQLite database: not the
  cached chapters or shlokas, sources, reflections, notes, bookmarks, reading progress,
  reading history, settings or sync metadata. Personal data belongs to the device, not
  to the session. `logout_preserves_local_data_test.dart` checks every table.

## Password recovery

1. On the login screen: **Forgot password?** → email → **Send reset link**. This calls
   `resetPasswordForEmail(email, redirectTo: 'com.gitartha.gitartha://auth-callback')`.
   The app always shows the same "If an account exists…" message, so it never reveals
   whether an address has an account.
2. The email link goes to Supabase, which redirects to the app's deep link with a
   one-time code (PKCE). **It must be opened on the same device** that requested it,
   because the code verifier lives there.
3. `supabase_flutter` exchanges the code and emits `passwordRecovery`. The app routes to
   **Choose a new password**.
4. **Save password** calls `updateUser(password: …)`. The success message appears only
   after Supabase confirms the change. If the password is weak, or the same as the old
   one, the error is shown and the user stays on the screen. **Cancel and sign out** is
   always available.

### Deep link configuration

| Place | Value |
|---|---|
| `SupabaseAuthRepository.authRedirectUrl` | `com.gitartha.gitartha://auth-callback` |
| Android `AndroidManifest.xml` | `VIEW` intent filter, scheme `com.gitartha.gitartha`, host `auth-callback` |
| iOS `Info.plist` | `CFBundleURLSchemes` = `com.gitartha.gitartha` |
| Both platforms | Flutter's own deep linking is disabled (`flutter_deeplinking_enabled` / `FlutterDeepLinkingEnabled` = false), so auth links go only to `supabase_flutter` (app_links), not to GoRouter |
| Supabase Dashboard | Authentication → URL Configuration → Redirect URLs: add the URL above |

## Offline reading

Authentication and offline reading are separate. Cached scripture and personal data
stay on the device whatever the session state. Pull/push sync, and whether reading
cached content needs a signed-in member, are decided in the sync milestone.
