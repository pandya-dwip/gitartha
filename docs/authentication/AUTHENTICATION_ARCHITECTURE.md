# Gitartha — Authentication Architecture

Milestone 4 connects the app to Supabase Auth and to the individual membership model
(`public.app_members`). It decides **who is signed in** and **what the UI offers them**.
Supabase Row Level Security decides what they can actually read and write.

## Layers

```text
lib/features/authentication/
├── domain/                          pure Dart, no Flutter/Supabase imports
│   ├── entities/app_user.dart         AppUser (id, email), AuthChange (session event)
│   ├── entities/member_access.dart    MemberAccess + canEditSharedContent
│   ├── entities/auth_failure.dart     AuthFailure / MembershipFailure + safe messages
│   ├── repositories/auth_repository.dart   the contract
│   └── auth_validators.dart           email / password input checks
├── data/
│   ├── repositories/auth_repository_impl.dart   SupabaseAuthRepository
│   ├── models/member_access_model.dart          strict app_members row parsing
│   └── secure_session_storage.dart              session in Keychain / Keystore
└── presentation/
    ├── providers/auth_state_provider.dart       client, repository, AuthController
    ├── providers/member_access_provider.dart    membership, AuthStatus, canEdit
    ├── screens/                                 login, forgot/reset password,
    │                                            account access, loading
    └── widgets/auth_widgets.dart                shared minimal layout
```

`SupabaseAuthRepository` talks to Supabase directly; a separate "data source" class
would only forward calls, so there isn't one.

## Startup

```text
main()
  → AppConfig.load()                  .env: SUPABASE_URL + SUPABASE_PUBLISHABLE_KEY
  → Supabase.initialize(...)          restores a stored session from secure storage
      (skipped if not configured; on failure the app still opens, sign-in unavailable)
  → ProviderContainer(overrides: appConfig, supabaseClient)
  → open the local SQLite database
  → runApp → GoRouter → authRedirect(authStatus, location)
```

Session restoration finishes inside `Supabase.initialize`, before the first frame, so
the platform launch screen covers it. The in-app loading screen covers the membership
check that follows.

## Providers

| Provider | Type | Meaning |
|---|---|---|
| `supabaseClientProvider` | `SupabaseClient?` | null = no backend |
| `authRepositoryProvider` | `AuthRepository?` | overridden with a fake in tests |
| `authControllerProvider` | `AuthSession` | user + password-recovery flag; owns the **only** auth-event subscription |
| `currentUserProvider` | `AppUser?` | the signed-in user |
| `memberAccessProvider` | `AsyncValue<MemberAccess?>` | own membership; `null` = confirmed missing; error = unknown |
| `authStatusProvider` | `AuthStatus` | the single combined answer the router and screens read |
| `canEditSharedContentProvider` | `bool` | true only when status is `editor` |

`AuthStatus` values:

| Status | Meaning | Route |
|---|---|---|
| `backendUnavailable` | Supabase not configured / failed to start | `/login` (sign-in disabled, message shown) |
| `signedOut` | no session | `/login`, `/forgot-password` |
| `passwordRecovery` | opened a reset link | `/reset-password` |
| `loadingMembership` | signed in, membership being checked | `/loading` |
| `readOnly` | member, `is_accessible = false` | the app |
| `editor` | member, `is_accessible = true` | the same app; editing offered |
| `membershipMissing` | signed in, no `app_members` row | `/account-access` |
| `membershipError` | could not check (network, malformed row, denied) | `/account-access` with **Try again** |

UI code reads `canEditSharedContentProvider` or `authStatusProvider`. It never reads
`is_accessible` itself and never re-derives the rule.

## Routing

`authRedirect(status, path)` in `lib/app/router/app_router.dart` is a pure function:
every status maps to one fixed destination (or, for members and signed-out users, a set
they can move within). A test checks that one redirect always lands on a route that
does not redirect again, for every status and path, so there are no loops.

The router re-evaluates through `refreshListenable` whenever `authStatusProvider`
changes. Every navigation, including deep links and `router.go(...)`, passes through
the redirect.

Not done yet: a deep link to a specific page made while signed out lands on the home
route after sign-in, not on the requested page. The app has only one protected route
so far; add a `from` query parameter when real routes arrive.

## Security boundaries

- The app only ever uses the **publishable** key and the user's own session.
  `AppConfig` refuses `sb_secret_…` keys and `service_role` JWTs.
- Registration (`/register`) calls only Supabase Auth `signUp`; the read-only
  membership comes from the database trigger. No admin API, no invite API and no write
  to `app_members` exist in app code. A test
  (`test/unit/features/authentication/app_security_scan_test.dart`) fails if any appear,
  or if `signUp` is called anywhere except `SupabaseAuthRepository`.
- The membership query filters by the **session's** user id, and RLS
  (`app_members_select_own`) returns only that row anyway. The parser rejects a row for
  a different user, or a missing or non-boolean `is_accessible`.
- Permission is held **in memory** for the session and never persisted. A re-check that
  is still in flight or has failed never counts as "editor".
- RLS remains the final authority. See [MEMBERSHIP_ACCESS_CONTROL.md](MEMBERSHIP_ACCESS_CONTROL.md).

## Packages

| Package | Why |
|---|---|
| `supabase_flutter` (already present) | Auth, session refresh, deep-link handling, PostgREST |
| `flutter_secure_storage` (added) | Stores the session (refresh token) in the iOS Keychain or Android Keystore-backed storage instead of plain SharedPreferences, which Android auto-backup would copy off the device |

## Tests

| File | Covers |
|---|---|
| `test/unit/features/authentication/auth_state_test.dart` | sign-in, restore, logout, expiry, refresh, recovery, membership states, permission, revocation |
| `test/unit/features/authentication/supabase_auth_repository_test.dart` | the real Supabase repository over mocked HTTP: requests sent, error mapping, membership parsing |
| `test/unit/features/authentication/logout_preserves_local_data_test.dart` | every local SQLite table is unchanged by logout, expiry and user switches |
| `test/unit/features/authentication/app_security_scan_test.dart` | no privileged credentials, sign-up or membership writes in `lib/` |
| `test/unit/app/auth_redirect_test.dart` | route guard table, no redirect loops |
| `test/widget/auth_flow_test.dart` | the real app and screens: login, validation, double submit, logout, missing membership, retry, recovery |
| `supabase/tests/rls_auth_membership_verification.sql` | real RLS behaviour, run on an isolated project |
