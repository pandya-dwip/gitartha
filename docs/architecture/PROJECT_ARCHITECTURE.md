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

## Supabase backend (planned)

- The source of truth for **shared scripture content** only.
- Migrations, seed data and CLI config will go in `supabase/`.
- The client uses only the project URL and the **publishable (anon) key**. Secret or
  service-role keys must never reach the app.
- Authentication and Row Level Security will be configured in a later milestone.
- **Sync is pull-based:** the app fetches content into the local Drift cache and reads
  from that cache. The details of the sync strategy are not designed yet.

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
- No Supabase client is initialized in this milestone.

## App bootstrap (in place)

```text
main()
  → WidgetsFlutterBinding.ensureInitialized()
  → AppConfig.load()                 // reads and validates .env
  → container = ProviderContainer(overrides: [appConfigProvider])
  → container.read(appDatabaseProvider).ensureInitialized()   // opens gitartha.sqlite
  → runApp(UncontrolledProviderScope(container: container, child: GitarthaApp()))
        → MaterialApp.router(theme: AppTheme.light, darkTheme: AppTheme.dark,
                             routerConfig: appRouterProvider)
```

The app has one temporary route, `/`, which shows a bootstrap screen. Feature
milestones will replace it.
