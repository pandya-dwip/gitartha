# Gitartha — UI Implementation (Milestone 6)

Design authority: `DESIGN.md` (rules and tokens) and `code.html` (layouts), both in the
repository root.

## Screen inventory

| # | Screen / overlay | code.html | Route | Data (SQLite unless noted) |
|---|---|---|---|---|
| 1 | Welcome (splash) | `screen-splash` | `/welcome` (signed-out entry) | — |
| 2 | Home | `screen-home` | `/` (tab Home) | last opened progress, daily verse, chapter summaries |
| 3 | Chapter Library (+ search) | `screen-library` | `/chapters` (tab Read) | `local_chapters`, live verse counts, `searchShlokas` |
| 4 | Chapter Overview | `screen-chapter-overview` | `/chapters/:id` | chapter fields, verse count |
| 5 | Verse Index (range chips) | `screen-verse-index` | `/chapters/:id/verses` | live `local_shlokas` of the chapter |
| 6 | Shloka Reader | `screen-reader` | `/chapters/:id/verses/:verse` | verse, bookmark, progress, reflections, notes, attributions + sources |
| 7 | Bookmarks | `screen-coming-soon` (Bookmarks) | `/bookmarks` (tab) | `bookmarks` |
| 8 | My Journal (Reflections / Notes) | `screen-coming-soon` (Journal) | `/journal` (tab) | `reflections`, `personal_notes` |
| 9 | Settings & About | `settings-modal` | bottom sheet | `local_settings`, sync state, current user, membership |
| — | Toast | `toast-notification` | SnackBar | — |
| — | Bottom navigation (4 tabs) | `bottom-navbar` | `StatefulShellRoute` | — |
| — | Note editor, reflection edit, delete confirmation | (journal states) | bottom sheet / dialogs | — |
| — | Sign-in, forgot / reset password, account access, loading | (Milestone 4) | `/login` … | Supabase Auth |

## Components (`lib/app/widgets/`)

`SacredCard` (vellum/parchment card, 1px linen border, 8px radius, optional gold border),
`SectionLabel`, `SacredDivider` (— ✦ —), `NumberBadge`, `HeaderIconButton`,
`ThemeToggleButton`, `PillChip`, `InnerTopBar`, `TabHeader`, `ReadingWidth` (680px max),
`EmptyState` / `LoadingState` / `ErrorState`. Feature widgets: `ChapterCard`,
`ChapterPreviewTile`, `VerseTile`.

## Design tokens (`lib/app/theme/`)

- **Colours:** `GitarthaColors` (ThemeExtension) holds DESIGN.md's light roles: canvas
  `#F7F3EA`, well `#EFE8DA`, card `#FFFDF8`, accent `#B99A60`, text `#493A2E`, secondary
  `#796B5D`, border `#E2D8C7`. It also holds the Night Contemplation values. The values
  are mapped onto the Material 3 `ColorScheme`.
- **Type:** `GitarthaText`, the DESIGN.md scale (mobile variants): display, sanskrit,
  headline, translation, commentary, transliteration (italic), meta, ui.
- **Fonts:** Noto Serif, Noto Serif Devanagari and Plus Jakarta Sans are bundled
  (SIL OFL; licences in `assets/fonts/**/OFL-*.txt`, shown under Settings → About &
  licences).
- **Spacing:** `AppSpacing` (4 / 8 / 16 / 24 / 36, page margin 20, gutter 12).
- **Radii:** `AppRadii` (4 / 6 / 8 / 12).

## Conflicts between the references, and decisions

| Topic | DESIGN.md | code.html | Followed |
|---|---|---|---|
| Fonts | Noto Serif + Plus Jakarta Sans | Noto Serif Devanagari, Cinzel, Lora | DESIGN.md (Noto Serif, with Noto Serif Devanagari for Devanagari as its "Devanagari" fidelity requires) |
| Card / button radius | 4–8px | `rounded-2xl` (16px), `rounded-3xl` | DESIGN.md (8px cards, 4px buttons) |
| Dark border | `#36312B` | `#3A332C` | DESIGN.md |
| Dark card, dark secondary text | not given | `#211F1C`, `#B9AA97` | code.html |
| YAML Material palette (`primary #745a27` …) | generated M3 scheme | not used for components | The prose colour roles (explicit per component) |
| Primary button uppercase | "uppercase tracking" | sentence case | Letter-spacing applied, sentence case kept (readable labels) |
| Bookmarks / Journal | — | "coming soon" panels | Implemented as functional tabs using the panel's empty-state style |
| Reader "My Journal" slot | — | "coming soon" | Implemented: dated reflections, notes, progress |
| Settings "Milestone 1" box | — | static text | Replaced by scripture-update status, account / access and sign-out |
| Splash every launch | — | always shown | Shown to signed-out visitors only (members open straight into Home) |

The following are **not implemented**, because the database has no data for them: the
DESIGN.md audio chant bar, anvaya (word-by-word) chips, and the audio autoplay toggle.
Nothing is shown in their place.

Copy on the design screens ("Peace to the mind…", "One step at a time…") is
interface text. No scripture is hard-coded: every verse, meaning and chapter text comes
from SQLite. When it is missing, the screen shows an empty state.

## Behaviour notes

- **Opening a verse.** This records `opened` once per verse shown (post-frame, de-duplicated
  by the repository), never `read` or `studied`. "Read" and "Studied" are explicit buttons.
  Saving a reflection marks the verse `reflected`.
- **Reflections.** Each save creates a new, dated record. Edit changes that record in
  place.
- **Bookmarks.** One per verse (unique). The bookmark icon state updates live everywhere.
- **Read-only members and editors** see the same UI. The app has no in-app editing
  (publishing stays in the CLI), so there is nothing to hide for read-only users. Settings
  shows the access level.
- **Theme and font size** are saved in `local_settings` (`theme_mode`,
  `body_font_scale`).
- **Search** is debounced (300 ms) and runs only against local SQLite.
- **Layout.** All screens are tested at 320 dp width with 1.3× text, in both themes.
