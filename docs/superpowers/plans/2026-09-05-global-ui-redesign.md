# Global UI Redesign Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development for the independent reader task; the primary agent integrates shared components and native validation. Continue without intermediate user approval; implementation is authorized.

**Goal:** Ship one English, flat UI across all four tabs and details, with always-visible contract metrics and a designed article/comment experience.

**Architecture:** Keep the SwiftUI app, view models, API contracts, persistence, and refresh policy. Centralize type, colors, flat controls, and root header spacing; retain feature-specific presentation in its current folders.

**Tech Stack:** Swift 6, SwiftUI, iOS 17+, XcodeGen, XCTest.

**Spec:** `docs/superpowers/specs/2026-09-05-global-ui-redesign.md`

## Global Constraints

- English interface and displayed content; retain translation data in models.
- Square content regions; at most 3 pt control corners; no rounded inset groups, pills, or decorative double borders.
- System sans, 20 pt gutters, semantic type scaling, 44 pt targets, tabular figures and one blue action accent.
- Preserve routes, refresh activation, ordering/timezone, credentials, media and source-reader behavior.
- Contracts: all current headline and secondary metrics visible without interaction; signs/text accompany color.
- News: recognizable comments, honest author/context/reaction data, English body, correct empty/partial/error states.
- No deployment, external posts, fabricated live data, or changes to backend contracts.

### Task 1: Shared system and all root screens

**Files:** `Components/EditorialTheme.swift`, `EditorialMasthead.swift`, `BilingualText.swift`, new `InterfaceComponents.swift`; `App/RootTabView.swift`; `Calendar/CalendarView.swift`, `CalendarDetailView.swift`; `Contracts/ContractsView.swift`; `News/NewsListView.swift`, `NewsArticleCard.swift`, `NewsSectionPicker.swift`; `Settings/SettingsView.swift`.

**Interfaces:** Retain `EditorialTheme` color names and `headline(_:weight:)`; change headline to sans. Keep existing view initializers. Root tab selection may gain a defaulted initial value for isolated native captures. Replace the view-only `BilingualText` with `ContentText(english:font:)`; do not remove model translations.

- [x] Implement common palette/header/controls using flat `.background(EditorialTheme.surface)` and `.listStyle(.plain)`; small input/button outlines only.
- [x] Calendar: full-width agenda with straight date bands, English names, aligned values, stacked accessibility layout, flat details.
- [x] Contracts: aligned price row plus always-visible turnover/volume/amplitude and high/low/trades grid; signed changes; stacked accessibility layout.
- [x] News: same header/category rail/gutters/separators; remove Chinese category/teaser presentation.
- [x] Settings: flat ScrollView form, labeled rectangular fields, blue Save, secondary Test, destructive Remove, nearby feedback and informational refresh rows.
- [x] Preserve refresh/navigation handlers and validate in the integrated run.

### Task 2: News article and discussion experience

**Files:** `News/NewsDetailView.swift`, `News/NewsSegmentView.swift`, `News/NewsCommentCard.swift`; optional focused `News/NewsCommentsSection.swift` or presentation helper and regression tests under `ForexFactoryMVPTests/`.

**Interfaces:** Retain `NewsDetailView(articleID:summary:model:)`, `NewsSegmentView(segment:model:)`, `NewsCommentCard(comment:)` (extra defaulted parameters allowed). Existing `EditorialTheme` colors remain stable; parent changes `headline` to sans. Do not edit Task 1 files or models/API. The root comment feed wraps cards in Buttons: avoid nested permalink/reaction controls in default card presentation. Render English with `Text` directly, since the parent replaces BilingualText.

- [x] Read actual News models and existing media/link behavior. Read the spec's News section. Use supplied author/time/parent/reaction/permalink fields only.
- [x] Build readable English article layout: source/date/time, headline, optional teaser, body, quote, media and original-source action. Quotes have exactly one visual treatment.
- [x] Build comment row: square identity marker (SF Symbol or initials), author/time, English body, actual reaction count and parent context. Resolve parent names only from loaded comments; preserve API order and keep indentation bounded.
- [x] Comments section: count/collection status, distinct surface or spacing, honest loading/error/empty states. Preserve article access if comments fail. No fake reply composer or interactive liking.
- [x] Preserve media fallback/processing retries and in-app source links. Add focused tests only for new presentation/state logic, including missing parent, partial collection and reactions; do not mirror visual constants.
- [x] Self-review English-only, nested buttons, truncation, cancellation and retained routes. Write a report listing changed files and validation evidence. Do not commit, spawn subagents, or run simulator builds concurrently with the parent.

### Task 3: Integration and native visual verification

**Files:** capture harness temporarily in tests, archived under `docs/design-qa/global-ui-2026-09-05/`; screenshots/QA report; `design-qa.md`.

- [x] Generate project and run existing suite plus focused regressions on iPhone 17 Pro simulator, Swift 6 strict concurrency/warnings as errors.
- [x] Fixture-backed native captures: all four tabs with actual tab bar; Calendar detail; News article and comments/replies; dark; narrow accessibility text; empty/error/filter states.
- [x] Inspect captures; compare original Precision Ledger board with all four native light root screenshots in the same visual review, honoring the user's always-visible metrics and improved reader/comments overrides.
- [x] Fix visible clipping/overflow/inconsistent spacing; rerun affected validation only after changes justify it.
- [x] Whole-change source review; resolve actionable findings. Archive optional capture harness, regenerate, run final standard suite and `git diff --check`.
- [x] Deliver native screenshots with concise verification and limits; leave changes local.
