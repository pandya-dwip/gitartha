# Gitartha — Project Architecture

This document describes the *intended* architecture. As of Milestone 0, only
environment configuration, theming, routing and the app bootstrap exist. Every
section marks what is in place now and what is planned.

## Guiding principles

1. **Offline-first reading.** Scripture must be readable with no network connection.
2. **Personal data stays on the device.** Reflections, journal entries, notes,
   bookmarks and reading progress are never uploaded.
3. **Feature-first modules.** Code is grouped by feature, and each feature is split
   into layers.
4. **One-way dependencies.** Presentation depends on domain. Data implements the
   contracts domain defines. Domain depends on neither.

## Layers

```text
┌──────────────────────────────────────────────┐
│ Presentation  screens · widgets · providers  │  Flutter, Riverpod, GoRouter
└──────────────────────┬───────────────────────┘
                       │ uses
┌──────────────────────▼───────────────────────┐
│ Domain        entities · repository contracts│  pure Dart
└──────────────────────▲───────────────────────┘
                       │ implements
┌──────────────────────┴───────────────────────┐
│ Data          repositories · models          │
│   local  (Drift / SQLite)                    │
│   remote (Supabase)                          │
└──────────────────────────────────────────────┘
```

### Presentation layer — `features/<feature>/presentation/`

- `screens/`: route-level widgets, registered in `lib/app/router/app_router.dart`.
- `widgets/`: reusable UI pieces for that feature.
- `providers/`: Riverpod providers that expose state to the UI and call domain contracts.
- Widgets take colours and type styles from `Theme.of(context)`, never hard-coded
  values. The palette is defined only in `lib/app/theme/`.

### Domain layer — `features/<feature>/domain/`

- Plain Dart entities and abstract repository interfaces.
- No Flutter, Drift or Supabase imports, so it can be unit-tested in isolation.

### Data layer — `features/<feature>/data/` and `lib/data/`

- Repository implementations that fulfil the domain contracts.
- Code shared across features goes in `lib/data/`:
  - `local/`: the Drift database, its DAOs and `LocalDatabaseRepository` *(in place, Milestone 2)*.
  - `remote/`: Supabase data sources *(planned)*.
  - `models/`: serializable models (`json_serializable`) for Supabase payloads and
    their mapping to entities *(planned)*.
  - `repositories/`: repositories that span more than one feature *(planned)*.

## Local database (in place)

- SQLite through **Drift**, opened with `drift_flutter`, which bundles native SQLite.
  The file is `gitartha.sqlite` in the app's documents directory.
- It holds:
  - a **scripture cache** (`local_chapters`, `local_shlokas`), a copy of content that
    will be pulled from Supabase;
  - **personal data** (reflections, notes, bookmarks, reading progress and history,
    settings), which exists only locally;
  - `sync_metadata` for the future sync.
- Opened in `main()` before the first frame and provided through
  `appDatabaseProvider` / `localDatabaseRepositoryProvider`
  (`lib/data/local/local_database_providers.dart`).
- Full-text (FTS5) search is planned for the search milestone. Search uses `LIKE` for
  now.
- Documented in `docs/database/LOCAL_SQLITE_SCHEMA.md`,
  `LOCAL_DATABASE_IMPLEMENTATION.md` and `LOCAL_DATABASE_TESTING.md`.

## Content pipeline (in place, Milestone 3)

- Scripture is authored as JSON in `assets/data/bhagavad_gita/` (the single source),
  which is bundled as Flutter assets.
- `lib/data/content/` validates it (JSON Schema Draft 2020-12 plus semantic checks, in
  `structural` / `draft` / `strict` modes), parses it into typed `json_serializable`
  models, and imports it into the local Drift cache on explicit request
  (`contentRepositoryProvider`). It never runs at startup, and never touches personal
  data.
- Content ids map to deterministic UUID v5 (`content_ids.dart`), shared with the
  Supabase publisher.
- Publishing approved content to Supabase: `tool/publish_gita_content.dart`
  (Milestone 3.1). It runs as an `is_accessible` member under RLS, with no
  privileged keys. See `docs/content/CONTENT_PUBLISHING.md`.
- The CLI `tool/validate_gita_content.dart` runs the same validation from the command
  line.
- Documented in `docs/content/`.

## Supabase backend

- The source of truth for **shared scripture content** only. Schema and RLS:
  `supabase/migrations/0001_initial_schema.sql` (see `docs/database/`).
- The client uses only the project URL and the **publishable key**. Secret or
  service-role keys must never reach the app.
- **Authentication (in place, Milestone 4):** invitation-only email/password sign-in,
  a session kept in secure storage, individual membership (`app_members.is_accessible`)
  and GoRouter guards, in `lib/features/authentication/`. See
  `docs/authentication/AUTHENTICATION_ARCHITECTURE.md`.
- **Content sync (in place, Milestone 5):** pull-only, incremental, transactional
  download of chapters, sources, shlokas and attributions into the Drift cache, in
  `lib/features/synchronization/`. Screens read only SQLite. See
  `docs/database/SYNC_STRATEGY.md`.

## Environment configuration (in place)

- `.env` (git-ignored) is bundled as a Flutter asset and loaded at startup by
  `AppConfig.load()` in `lib/core/config/app_config.dart`.
- `AppConfig` is immutable and validated once. The root `ProviderScope` exposes it
  through `appConfigProvider` (`lib/core/config/app_config_provider.dart`).
- Validation failures throw `ConfigurationException` (`lib/core/errors/`), with a
  message that says how to fix the problem.
- Supabase settings are optional outside `production`.
  `AppConfig.isSupabaseConfigured` tells features whether a backend exists.
  `AppConfig.requireSupabase` gets the settings or throws a clear error.
- The Supabase client is initialized in `main()` only when it is configured
  (Milestone 4).

## App bootstrap (in place)

```text
Native launch screen        canvas colour only (Android ≤11, Android 12+ system
                            splash with its icon hidden, iOS LaunchScreen)
main() → runApp(GitarthaStartup)            first Flutter frame = GitarthaSplash
  GitarthaSplash            logo + "गीतार्थ" below it; entrance plays once the logo
                            image is decoded (logo and name never appear apart)
  behind the splash:
  → AppConfig.load()                         reads and validates .env
  → Supabase.initialize(...)                 if configured (12 s limit)
  → container.read(appDatabaseProvider).ensureInitialized()   opens gitartha.sqlite
  → wait for the first membership check      (6 s limit) and for the entrance
  → cross-fade into UncontrolledProviderScope(GitarthaApp)
        → MaterialApp.router(builder: NetworkGate(...), routerConfig: appRouterProvider)
```

There is exactly **one** splash. The router's `/loading` route (membership still being
checked) renders the same `GitarthaSplash` without replaying its entrance, so app start
→ checking access → app shows no second screen. If startup takes over 4 s, a quiet
"Preparing your library…" appears under the name. Errors appear there too, with "Try
again".

**Network prompt.** `NetworkGate` (`lib/features/connectivity/`) sits above every
screen. On launch and on every resume it checks that the Supabase host is reachable (a
TCP connection, not just "Wi-Fi is on"). Offline, it shows a modal ("No internet
connection") with *Open network settings* (Android, via the `gitartha/network` method
channel in `MainActivity.kt`) and *Try again*. It re-checks every 3 s and closes by
itself when the connection is back, then re-runs a membership check that failed offline
and the content sync. It is off when no backend is configured.

**Motion** (`lib/app/motion/motion.dart`):

- one-shot entrances (`FadeSlideIn`, staggered per list, only during a screen's first
  700 ms via `EntranceScope`);
- a press effect on tappable cards (`PressScale`);
- animated icon swaps (`PopSwitcher`);
- a fade between tabs (`FadingBranchContainer`);
- zoom page transitions on Android and the native slide on iOS.

Everything animates opacity or transform only, nothing loops, and everything is off
when the system's "reduce motion" setting is on.

Routes are guarded by `authRedirect` (`lib/app/router/app_router.dart`). Signed-out
visitors see `/welcome`, then `/login`. Only confirmed members (read-only or editor)
reach the app: a `StatefulShellRoute` with four tabs (Home `/`, Read `/chapters`,
Bookmarks `/bookmarks`, My Journal `/journal`). Reading routes nest as
`/chapters/:id/verses/:verse`, so back navigation walks up the hierarchy. The screens
and the design system are documented in `docs/design/UI_IMPLEMENTATION.md` (Milestone 6).
The data flow is UI → Riverpod (Drift watch streams) → `LocalDatabaseRepository` →
SQLite. Screens never call Supabase.
