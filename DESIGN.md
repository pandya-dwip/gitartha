---
name: Sacred Illuminated Scripture
colors:
  surface: '#fdf9f0'
  surface-dim: '#dddad1'
  surface-bright: '#fdf9f0'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3ea'
  surface-container: '#f1eee5'
  surface-container-high: '#ece8df'
  surface-container-highest: '#e6e2d9'
  on-surface: '#1c1c16'
  on-surface-variant: '#4d463a'
  inverse-surface: '#31302b'
  inverse-on-surface: '#f4f0e7'
  outline: '#7f7668'
  outline-variant: '#d0c5b5'
  surface-tint: '#745a27'
  primary: '#745a27'
  on-primary: '#ffffff'
  primary-container: '#b99a60'
  on-primary-container: '#473201'
  inverse-primary: '#e4c284'
  secondary: '#6c5b4e'
  on-secondary: '#ffffff'
  secondary-container: '#f3dbca'
  on-secondary-container: '#715f52'
  tertiary: '#695c4f'
  on-tertiary: '#ffffff'
  tertiary-container: '#ac9c8c'
  on-tertiary-container: '#3f3428'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdea4'
  primary-fixed-dim: '#e4c284'
  on-primary-fixed: '#261900'
  on-primary-fixed-variant: '#5a4311'
  secondary-fixed: '#f6decd'
  secondary-fixed-dim: '#d9c2b2'
  on-secondary-fixed: '#25190f'
  on-secondary-fixed-variant: '#534437'
  tertiary-fixed: '#f2dfce'
  tertiary-fixed-dim: '#d5c4b3'
  on-tertiary-fixed: '#231a0f'
  on-tertiary-fixed-variant: '#514538'
  background: '#fdf9f0'
  on-background: '#1c1c16'
  surface-variant: '#e6e2d9'
typography:
  display-lg:
    fontFamily: Noto Serif
    fontSize: 34px
    fontWeight: '600'
    lineHeight: 44px
    letterSpacing: -0.01em
  display-lg-mobile:
    fontFamily: Noto Serif
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  shloka-sanskrit:
    fontFamily: Noto Serif
    fontSize: 21px
    fontWeight: '500'
    lineHeight: 36px
    letterSpacing: 0.02em
  shloka-sanskrit-mobile:
    fontFamily: Noto Serif
    fontSize: 19px
    fontWeight: '500'
    lineHeight: 32px
    letterSpacing: 0.015em
  headline-md:
    fontFamily: Noto Serif
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-translation:
    fontFamily: Noto Serif
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 28px
  body-commentary:
    fontFamily: Noto Serif
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 25px
  label-transliteration:
    fontFamily: Noto Serif
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0.02em
  label-meta:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.06em
  label-ui:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.5rem
  margin-mobile: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.25rem
---

## Brand & Style

This design system translates the timeless sanctity of ancient Palm-leaf and Devanagari manuscripts into a refined, contemporary mobile reading experience. Built for sustained contemplation and spiritual study, the UI evokes tranquility, revered authority, and quiet luxury.

The aesthetic philosophy fuses traditional classical book design with modern screen-first clarity:
- **Atmospheric Warmth:** Surfaces reject clinical pure whites and harsh blacks in favor of hand-pressed parchment, warm ivory, and temple stone.
- **Editorial Reverence:** Generous margins, breathing room, and classical proportion ratios create a meditative reading cadence that removes digital friction.
- **Subtle Ornamentation:** Fine ornamental hairline dividers, antique gold brackets, and subtle illuminated drop markers punctuate sacred verses without visual clutter.

## Colors

The palette is derived from aged manuscript folios, hand-ground minerals, and burnished gold leaf.

### Color Tokens & Roles

- **Primary Accent (`#B99A60` antique gold):** Used for key devotional anchors, active chapter tab indicators, subtle filigree dividers, chapter invocations, and interactive sacred actions.
- **Primary Surface / Canvas (`#F7F3EA` warm ivory):** The core reading backdrop, calibrated to minimize eye fatigue during extended study sessions.
- **Secondary Surface (`#EFE8DA` aged parchment):** Used for elevated navigation trays, verse commentary wells, and header bars.
- **Surface Card (`#FFFDF8` milk vellum):** Dedicated for discrete verse cards, reflection modals, and vocabulary glossaries.
- **Primary Text (`#493A2E` deep scorched earth):** Replaces harsh black with a warm, high-contrast mineral brown that renders serifs with organic legibility.
- **Secondary Text (`#796B5D` muted sandalwood):** Used for metrical markings, verse numbering, Sanskrit transliterations, and word-by-word commentary.
- **Borders & Dividers (`#E2D8C7` woven linen):** Subtle hairline borders providing soft structure.

### Dark Mode (Night Contemplation)
- **Primary Surface:** `#191817` (Deep Obsidian Sandalwood)
- **Secondary Surface:** `#24211E` (Darkened Clay)
- **Primary Text:** `#E9E0D1` (Softened Bone)
- **Primary Accent:** `#C3A46A` (Burnished Ochre Gold)
- **Borders:** `#36312B`

## Typography

The typographic hierarchy honors the dual rhythm of sacred classical meter (chandas) and clear modern exegesis.

- **Primary Reading Typeface (`Noto Serif`):** Chosen for its optical fidelity in both Devanagari and Latin scripts. Sanskrit ligatures and diacritics maintain balanced kerning and proportional stroke weight.
- **Functional Interface Typeface (`Plus Jakarta Sans`):** Used sparingly for utilitarian tags, audio scrubber timestamps, and bottom navigation labels to prevent visual fatigue while keeping the sacred scripture front and center.
- **Line Heights:** Set to generous multipliers (1.6x – 1.8x) across Sanskrit stanzas and English translations to reflect classical folio typesetting and allow room for vowel signs (*matras*) and conjuncts.
- **Italics Policy:** Use true italics only for Latin transliterations of Sanskrit terminology (e.g., *Dharma*, *Kṣetra*); avoid slanted pseudo-Devanagari.

## Layout & Spacing

The layout is anchored in a centered, bookish single-column vertical flow with generous outer margins, reproducing the cadence of a sacred volume.

- **Grid Architecture:** Single-column fluid reading container constrained to a maximum content reading width of `680px` on tablets/foldables, preserving the ideal 60–75 characters per line measure.
- **Verse Stanza Spacing:** Each verse stanza is framed with an intentional `space-xl` separation, ensuring individual verses can be contemplated without distraction from adjacent texts.
- **Safe Reading Gutters:** Mobile edges feature minimum `1.25rem` padding to give edge-to-edge breathing room that feels like a natural manuscript margin.

## Elevation & Depth

To maintain a serene, organic aesthetic, traditional heavy drop shadows and glowing neon blurs are avoided. Depth is conveyed through subtle tonal layering and tactile print boundaries:

- **Tonal Layering:** The viewport progresses from Canvas (`#F7F3EA`) to Container Wells (`#EFE8DA`) to Scripture Cards (`#FFFDF8`).
- **Low-Contrast Hairlines:** Elements are demarcated using crisp 1px borders colored in `#E2D8C7`.
- **Soft Ambient Halo:** Floating controls (such as the audio recitation pill or quick-bookmark dock) use a low-opacity amber-tinted shadow: `0 4px 16px -2px rgba(73, 58, 46, 0.07), 0 2px 6px -1px rgba(185, 154, 96, 0.12)`.
- **Filigree Accent Dividers:** Decorative center-ornamented lines (e.g., stylized lotus or diamond motifs: `— ❖ —`) provide physical section breaks in place of harsh full-bleed horizontal rules.

## Shapes

The shape system adopts a soft, gentle geometry (`roundedness: 1`). Corners evoke precision-cut high-grade archival paper rather than playful bubbly geometry or clinical razor-sharp edges.

- **Core Elements (Buttons, Inputs, Cards):** `0.25rem` (4px) to `0.5rem` (8px) border radii.
- **Recitation Badges & Chapter Markers:** Subtle corner radiuses (`0.25rem`) mimicking stamped wax or embossed seal badges.
- **Audio Control Capsule:** A single intentional pill shape (`9999px`) reserved specifically for persistent audio recitations to signal a floating physical tool.

## Components

### Sacred Verse Cards
- Constructed with `#FFFDF8` background, 1px `#E2D8C7` border, and `rounded-lg` (8px).
- Internal padding utilizes `space-lg`.
- Top edge features a centered verse number marker (e.g., "अध्याय २ • श्लोक ४७") rendered in `label-meta` colored with `#796B5D`.
- Sanskrit text is centered or left-justified with hanging indentation, followed by a delicate `#B99A60` filigree divider mark.

### Buttons & Interactive Controls
- **Primary Button (Sacred Action):** Solid `#B99A60` fill, `#FFFDF8` text, subtle 0.25rem corners, uppercase tracking on Latin text.
- **Secondary Button:** Surface `#FFFDF8`, 1px border `#B99A60`, text `#493A2E`.
- **Icon Action Buttons (Audio playback, Bookmark, Share):** Transparent background with `#796B5D` iconography; shifts to `#B99A60` on active state.

### Word-by-Word Breakdown (Anvaya Chips)
- Used for Sanskrit grammatical parsing.
- Rendered with an `#EFE8DA` background, borderless, with `0.25rem` radius.
- Sanskrit root word in bold `#493A2E`, accompanied by translation in `#796B5D`.

### Checkboxes & Toggle Switches
- Checkboxes feature a gold fill (`#B99A60`) with an ivory tick when checked, and an unselected border of `#E2D8C7`.
- Audio autoplay toggle switches use a warm muted track (`#E2D8C7`) with a solid antique gold thumb.

### Input Fields (Search & Reflection Journal)
- Background in `#FFFDF8`, 1px border in `#E2D8C7`.
- Focused state transitions border to `#B99A60` with no harsh outline ring; subtle internal padding (`space-md`).
- Placeholder text styled in `#796B5D` italicized serif.

### Audio Chant Floating Bar
- Docked at the bottom navigation edge.
- Background colored with `#EFE8DA` with an upper border of `#E2D8C7`.
- Houses playback scrubber in `#B99A60`, verse tempo selectors, and sacred chanter attribution.