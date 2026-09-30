---
name: Hanuman Chalisa for iPhone
description: Native SwiftUI practice for reading, listening, and recalling the Hanuman Chalisa offline.
colors:
  accent-light: "rgb(62% 23% 12%)"
  accent-dark: "rgb(100% 62% 40%)"
  prominent-label-light: "#ffffff"
  prominent-label-dark: "#000000"
typography:
  navigation:
    fontFamily: "system-ui"
  passage-title:
    fontFamily: "system-ui"
    fontWeight: 700
  headline:
    fontFamily: "system-ui"
  supporting:
    fontFamily: "system-ui"
  prayer:
    fontFamily: "ui-serif"
  prayer-word:
    fontFamily: "ui-serif"
  progress-count:
    fontFamily: "ui-rounded"
    fontWeight: 700
  caption:
    fontFamily: "system-ui"
rounded:
  hidden-word: "8pt"
  illustration: "14pt"
  practice-surface: "20pt"
spacing:
  intro-copy: "4pt"
  primary-extra-vertical: "5pt"
  word-flow: "6pt"
  line-content: "8pt"
  line-top: "10pt"
  playback-group: "12pt"
  section-content: "14pt"
  screen-inset: "20pt"
  line-bottom: "22pt"
  practice-sections: "24pt"
components:
  prayer-surface:
    rounded: "{rounded.practice-surface}"
  assessment-surface:
    rounded: "{rounded.practice-surface}"
    padding: "{spacing.screen-inset}"
  hidden-word:
    rounded: "{rounded.hidden-word}"
    padding: "0 10pt"
  line-audio:
    width: "44pt"
    height: "44pt"
  illustration:
    rounded: "{rounded.illustration}"
    width: "60pt"
    height: "60pt"
---

# Design System: Hanuman Chalisa for iPhone

## Overview

**Creative North Star: "Apple Human Interface Guidelines"**

The user pinned Apple's native interface conventions as the design direction. The implemented system uses SwiftUI navigation, controls, semantic colors, and text styles. Prayer text has a serif voice; the surrounding interface stays familiar and quiet so reading, listening, and recall remain the focus.

This document describes `ios/Chalisa` only. The existing web `dist` is a separate interface, not the source of native layout rules. Values are extracted from `ChalisaApp.swift`, `PracticeView.swift`, `LibraryView.swift`, and `Assets.xcassets/AccentColor.colorset/Contents.json`. This is an implementation record, not a claim of completed HIG or accessibility certification.

**Key Characteristics:**
- System Practice, Read, Library, and Progress tabs with independent navigation stacks. Read is a calm, continuous page: an accent passage label (D1, 1–40, D3) above two serif `.title3` lines in grouped list sections.
- Semantic grouped surfaces, adaptive light/dark tint, and Dynamic Type.
- Serif prayer text with clear listening and recall controls.
- Bundled text and synthetic audio for offline practice.

## Colors

Warm rust in light appearance and peach in dark appearance give the native controls a devotional accent without recoloring the whole interface.

### Primary

- **Warm rust** (`accent-light`): the light-appearance asset tint for actions, selected navigation, hidden words, and review indicators.
- **Peach** (`accent-dark`): the dark-appearance variant of the same asset. SwiftUI resolves the appearance automatically.
- Prominent action labels use `prominent-label-light` in light appearance and `prominent-label-dark` in dark appearance.

### Brand palette (`Theme.swift`)

Added on 2026-09-26, when Season asked for a bolder look. These are fixed colors drawn from the Hanuman artwork. They are used for brand moments, never for text or grouped surfaces.

- **Night** `#0E172B`: the navy behind the artwork and the Practice hero card.
- **Saffron** `#F58529` and **marigold** `#FFC24D`: the `saffronGlow` gradient for the progress ring, stat icons, streak pill and mastery tiles.
- **Ember** `#B83812`: the `emberGlow` gradient for primary buttons. It stays dark enough for white labels in both appearances.
- The hero's Devanagari title uses marigold on night.

### Neutral

Use `Color(uiColor: .systemGroupedBackground)` for the Practice canvas and `.secondarySystemGroupedBackground` for its prayer and assessment surfaces. Library, Progress, and Settings inherit native `List` presentation. Text uses `.primary`, `.secondary`, and `.tertiary`; dividers use system `Divider` styling. These are adaptive platform roles, not fixed hex tokens, and are intentionally absent from the CSS-color frontmatter.

Use `Color("AccentColor")` explicitly, not `Color.accentColor`, which resolved to system blue in this project. A hidden word uses the accent at 10% opacity. The line being played uses it at 7% opacity, with a 4pt saffron bar on its leading edge. Their text and audio control also communicate state; the tint alone is not the instruction.

**The Semantic Surface Rule.** Preserve native semantic background and text roles instead of substituting fixed light-mode colors.

## Typography

The frontmatter font families express design roles for portable readers. SwiftUI semantic text styles are the implementation authority; there are no hard-coded text sizes or bundled typefaces.

- **Navigation:** native navigation titles, drawn bold serif through `UINavigationBar.appearance()`. Settings uses an inline title.
- **Hero:** `.system(.title, design: .serif).bold()`, in white on night.
- **Passage title:** `.system(.title2, design: .serif).bold()`.
- **Line label:** `.caption` semibold, uppercase, with 1.2pt tracking; it turns accent while its line plays.
- **Headline:** `.headline` for section prompts, library titles, and the introduction.
- **Supporting:** `.subheadline` for instructions, playback options, counts, and secondary copy. Passage position uses monospaced digits.
- **Prayer:** `.system(.title2, design: .serif)`, with 6pt extra line spacing and unrestricted vertical growth.
- **Prayer word:** `.system(.title3, design: .serif)` for wrapped hint and recall words.
- **Progress count:** 40pt bold serif inside the ring; the stats use `.title3` rounded bold, with `.numericText()` transitions.
- **Caption:** `.caption` for review labels; the library chevron adds semibold weight.

**The Native Type Rule.** Keep semantic text styles and their Dynamic Type behavior; do not replace them with fixed pixel sizes to preserve a screenshot.

## Layout

Practice is a vertically scrolling, leading-aligned stack. Its outer inset and spacing between sections use `screen-inset` and `practice-sections`. The introduction and major content groups use `section-content`; playback controls use `playback-group`. Each prayer line has 20pt horizontal, 10pt top, and 22pt bottom padding, with 8pt between internal elements. Dividers are inset to the text edges. Assessment uses the screen inset on all sides.

At accessibility Dynamic Type sizes, the decorative introduction is removed, the passage title and position stack vertically with 8pt spacing, and the segmented practice-mode picker becomes a labeled menu with a minimum 44pt height. This is a semantic content-size transition, not a screen-width breakpoint. Hint words wrap through the custom `WordFlow` layout with 6pt gaps and width constrained to the available content.

Custom line-audio targets are 44pt square. Hidden words have minimum 44pt width and height; text actions and list rows set minimum 44pt heights. Native tab, navigation, picker, search, and large button controls retain platform behavior and sizing. Do not interpret the minimum target as a fixed height that clips larger text.

Library, Progress, and Settings use system lists and sections. Let iOS determine their margins, row separators, safe-area behavior, and navigation chrome rather than copying Practice's custom surface layout into every screen.

## Elevation & Depth

Grouped background roles and rounded surfaces still provide the main separation. Brand moments have their own depth:
- The hero card has a navy shadow (radius 18, y 10) and a hairline marigold border.
- Primary buttons have a saffron glow (radius 14, y 6) that tightens and scales to 0.97 when pressed.
- The prayer card has a soft shadow in light appearance only.
- The progress ring's stroke has a saffron glow.

Motion is limited to meaningful state changes:
- The speaker icon uses `.variableColor` while its line plays.
- A revealed word springs in with `.bouncy`.
- The stat pills and the result icon use `.bounce`.
- A successful recall fires `CelebrationBurst` (18 sparks, 0.9s ease-out) with success haptics; "Need more practice" gives a warning haptic.

Sheets, menus, navigation and tabs keep the operating system's treatment.

## Shapes

Prayer and assessment surfaces share the `practice-surface` radius. The decorative image uses the `illustration` radius, and hidden-word controls use `hidden-word`. The illustration is clipped to a square. Native buttons, segmented controls, search fields, sheets, and lists retain their platform shapes; no app-specific corner radius is assigned to them.

## Components

### Navigation

A native `TabView` contains Practice (`sparkles`), Library (`books.vertical`), and Progress (`flame`). Each tab owns a `NavigationStack`. Labels remain visible alongside their SF Symbols according to system presentation. The asset tint indicates selection. Changing the tab or passage stops audio.

### Prayer surface and hidden words

The two prayer lines share one grouped surface with a divider. Each line has a secondary label and a trailing speaker/stop control with an accessible name. Read mode shows the full serif text. Hints reveals alternating words; Recall initially conceals all words. Concealed-word buttons reveal individually and expose position-based accessibility labels and a reveal hint. The app uses native focus and activation behavior.

### Playback and action buttons

Listen to passage and "I remembered it" use `GlowButtonStyle`: a full-width ember capsule with a minimum height of 54pt and a white headline label. It switches to Stop listening while playback is active. Playback speed uses a native menu; Repeat 3× changes its text, tint, and accessibility value. The per-line audio glyph changes with its state.

Recall assessment uses a prominent remembered action and a bordered more-practice action. Previous and Next use text with directional symbols and native disabled states at the passage boundaries. Reset is a destructive system action behind a confirmation dialog.

### Library and search

A native searchable list groups opening dohas, the Chalisa, and the closing doha. Rows contain a headline, a two-line secondary preview, optional review status, and a disclosure chevron. A recalled passage shows an additional labeled checkmark. Search uses `.searchable` and a native empty-results view, not a custom text-field skin.

### Progress and Settings

Progress opens with a 132pt `ProgressRing` showing "N of 43 recalled", which has a spoken count, next to the streak, reviews due and passages tried. `MasteryGrid` shows all 43 passages as a 7-column grid: D1, D2, 1–40, D3. Tile brightness follows the review stage, due passages are outlined, and tapping a tile practises it. The Reminder section, with a toggle and a time picker, follows. Review actions come after that. Settings opens as a native sheet with an inline navigation title and Done action; informational text and destructive controls remain standard list content.

### Illustration and asset provenance

The existing AI-generated Hanuman artwork is reused and resized for `Assets.xcassets/Hanuman.imageset/Hanuman.png` and the app icon. No new illustration was authored for the native implementation. On Practice, the artwork sits at the trailing edge of the `HeroCard`, faded in from the left. It is decorative, hidden from accessibility, and the card is omitted at accessibility text sizes. The imageset is a 768px copy of `dist/hanuman.png`. The Settings copy discloses AI provenance. Existing bundled synthetic Hindi pronunciation clips remain learning guides, as described in PRODUCT.md and Settings.

The accompanying `.impeccable/design.json` includes self-contained browser previews so the design panel has renderable examples. They are explicitly approximate translations of native components. SwiftUI source, semantic platform behavior, and the tokens above take precedence over those previews; the previews do not redesign the web app.

## Do's and Don'ts

### Do:
- **Do** preserve the user's Apple HIG direction and native tab, navigation, list, search, and sheet patterns.
- **Do** use semantic text styles, adaptive background roles, and the appearance-aware accent asset.
- **Do** preserve the accessibility-size layout and minimum 44pt custom interaction targets.
- **Do** keep prayer text serif and allow it to grow and wrap.
- **Do** keep text and audio available offline and retain the existing artwork's AI provenance.

### Don't:
- **Don't** import the separate web interface's CSS, layouts, or fixed typography into the iPhone app.
- **Don't** replace native controls with decorative imitations. The saffron brand layer was requested; extend it, rather than adding another visual direction.
- **Don't** hard-code light-mode surface colors or shrink text to preserve a compact composition.
- **Don't** present the illustration as newly authored or the synthetic audio as a traditional recitation.
- **Don't** treat browser component previews as native rendering or verification evidence.
