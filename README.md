# Gitartha (गीतार्थ)

A modern Bhagavad Gita reading and personal reflection app for Android and iOS.

> **Status: Milestone 0, project foundation.** The project structure, dependencies,
> environment configuration, theme and routing are in place. No screens, scripture
> content or backend features have been built yet. The app launches to a temporary
> bootstrap screen.

## Technology stack

| Area | Technology |
|---|---|
| Framework / language | Flutter (stable), Dart |
| UI system | Material 3 |
| State management | Riverpod 3 (`flutter_riverpod`) |
| Navigation | GoRouter |
| Local database | SQLite via Drift (`drift`, `drift_flutter`), see `docs/database/LOCAL_DATABASE_IMPLEMENTATION.md` |
| Local search *(future)* | SQLite FTS5 |
| Backend *(future)* | Supabase (`supabase_flutter`) |
| Environment config | `flutter_dotenv` |
| Code generation | `build_runner`, `drift_dev`, `json_serializable` |
| Lightweight preferences | `shared_preferences` |
| Linting | `flutter_lints` + project rules in `analysis_options.yaml` |

## Prerequisites

- Flutter SDK, stable channel (developed against Flutter 3.41 / Dart 3.11)
- Android Studio with the Android SDK, plus an emulator or a physical device
- Xcode and CocoaPods for iOS builds (macOS only)
- Accepted Android SDK licenses: `flutter doctor --android-licenses`

Check your setup with `flutter doctor`.

**Minimum platform versions:** Android uses Flutter's default `minSdk`, and iOS requires 13.0.

## Installation

```bash
git clone <repository-url> gitartha
cd gitartha
cp .env.example .env      # required: .env is bundled as an asset
flutter pub get
```

## Environment variables

Configuration is read from `.env` by one class,
[`lib/core/config/app_config.dart`](lib/core/config/app_config.dart). Nothing else in
the app reads environment variables directly.

| Variable | Required | Description |
|---|---|---|
| `APP_NAME` | no | Display name. Defaults to `Gitartha`. |
| `APP_ENV` | no | `development` (default), `staging` or `production`. |
| `SUPABASE_URL` | production only | Supabase project URL, e.g. `https://<ref>.supabase.co`. |
| `SUPABASE_PUBLISHABLE_KEY` | production only | Supabase **publishable** key (`sb_publishable_…`). |
| `SUPABASE_ANON_KEY` | legacy | Same key under its old name; used only if `SUPABASE_PUBLISHABLE_KEY` is empty. |

Sign-in, sessions and membership: see [docs/authentication/](docs/authentication/AUTHENTICATION_ARCHITECTURE.md).

Rules:

- `.env` is git-ignored. `.env.example` is the committed template.
- The app runs without Supabase values in `development` and `staging`.
- Configuration is validated at startup. These all fail with a clear message:
  an unknown `APP_ENV`, setting only one of the two Supabase values, a URL that
  isn't https, or a missing backend in `production`.
- **Never use a secret or service-role key.** Everything in `.env` ships inside the app
  bundle, so the config class rejects `sb_secret_…` keys and `service_role` JWTs.

## Running the app

```bash
flutter devices           # list available devices/emulators
flutter run               # run on the selected device
flutter run -d <device-id>
```

## Development commands

```bash
dart format .                                   # format
flutter analyze                                 # static analysis
flutter test                                    # unit + widget tests
flutter test integration_test                   # on-device tests (needs a device)
dart run build_runner build                     # code generation (Drift, json_serializable)

# Bhagavad Gita content (read-only checks; see docs/content/)
dart run tool/validate_gita_content.dart                 # draft mode, all 18 chapters
dart run tool/validate_gita_content.dart --mode=strict   # publishing rules
flutter test test/unit/data/content                      # validation + import pipeline tests
flutter test test/drift                                  # local schema migration tests

# Publish approved content to Supabase (you sign in; start with docs/content/HOW_PUBLISHING_WORKS.md)
dart run tool/publish_gita_content.dart --all --validate-only
dart run tool/publish_gita_content.dart --chapter=1 --dry-run
dart run tool/publish_gita_content.dart --chapter=1 --confirm
flutter test test/tool test/unit/data/content/publishing   # publisher tests
```

Generated files (`*.g.dart`, `app_database.steps.dart`, `drift_schemas/`,
`test/drift/**/generated/`) are committed alongside their sources.

## Folder structure

```text
assets/            fonts (devanagari, english), images, bundled data
docs/              architecture, database, design and project notes
lib/
  app/             root widget, router, theme, temporary bootstrap screen
  core/            config, constants, errors, extensions, helpers, services, utils
  data/            local (Drift), remote (Supabase), models, repositories
  features/        home, chapters, shlokas, journal, bookmarks, notes, search, settings
  main.dart        entry point
supabase/          migrations, seed data and config for the backend
test/              unit, widget and integration tests
integration_test/  on-device tests
```

Each feature folder follows this layout once its implementation starts:

```text
feature_name/
├── data/
├── domain/
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/
```

## Future architecture

- Shared scripture content will live in **Supabase**.
- A local **SQLite (Drift)** database (in place since Milestone 2) caches that content, so
  reading works offline, and holds all personal data.
- Personal data (reflections, journal entries, notes, bookmarks, reading progress)
  will **stay on the device**.
- Sync will initially be **pull-based**, from Supabase to the local cache.
- The Supabase schema, Row Level Security and the local SQLite design are documented in
  [docs/database/](docs/database/DATABASE_ARCHITECTURE.md). The migration is
  `supabase/migrations/0001_initial_schema.sql`, and the steps to apply it are in
  [supabase/config/DATABASE_SETUP.md](supabase/config/DATABASE_SETUP.md).

See [docs/architecture/PROJECT_ARCHITECTURE.md](docs/architecture/PROJECT_ARCHITECTURE.md).
