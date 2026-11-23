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
  - `local/`: the Drift database and its DAOs *(planned)*.
  - `remote/`: Supabase data sources *(planned)*.
  - `models/`: serializable models (`json_serializable`) for Supabase payloads and
    their mapping to entities *(planned)*.
  - `repositories/`: repositories that span more than one feature *(planned)*.

## Local database (planned)

- SQLite through **Drift**, opened with `drift_flutter`, which bundles native SQLite.
- It will hold:
  - a **scripture cache**, a read-only copy of content pulled from Supabase;
  - **personal data** (journal, notes, bookmarks, reading progress), which exists only
    locally;
  - **FTS5** full-text indexes for offline search.
- Schemas and migrations will be designed in their own milestone and documented in
  `docs/database/`. No schema exists yet.

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
  → runApp(ProviderScope(overrides: [appConfigProvider], child: GitarthaApp()))
        → MaterialApp.router(theme: AppTheme.light, darkTheme: AppTheme.dark,
                             routerConfig: appRouterProvider)
```

The app has one temporary route, `/`, which shows a bootstrap screen. Feature
milestones will replace it.
