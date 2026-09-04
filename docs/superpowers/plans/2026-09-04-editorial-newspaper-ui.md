# Editorial Newspaper UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the existing iPhone interface as the selected modern financial-newspaper concept without changing its data, navigation, refresh, link, or notification behavior.

**Architecture:** Add one semantic editorial theme and a few focused reusable layout primitives, then migrate each existing SwiftUI screen from rounded system-card styling to paper surfaces, typographic hierarchy, and rules. Keep all current view models and API models intact; visual verification uses the selected 390 × 844 reference image and simulator screenshots.

**Tech Stack:** Swift 6, SwiftUI, UIKit appearance APIs where needed, XCTest, XcodeGen, Xcode simulator/device tooling.

**Spec:** `docs/superpowers/specs/2026-09-04-editorial-newspaper-ui-design.md`

**Visual Reference:** `docs/design-references/editorial-news-home-selected.png`

## Global Constraints

- Preserve the existing three-tab information architecture and all navigation destinations.
- Preserve backend contracts, caching, refresh intervals, notifications, Safari link handling, and settings behavior.
- Use warm paper/ink semantic colors with a charcoal "night edition" dark appearance.
- Use an editorial serif only for English mastheads and headlines; Chinese, controls, metadata, and numbers remain system sans-serif.
- Use no rounded cards, capsules, clipped rounded images, shadows, gradients, glass effects, or artificial paper texture.
- Maintain Dynamic Type, VoiceOver labels, minimum touch targets, and readable contrast.
- Do not add third-party fonts, icon libraries, or other dependencies.

---

### Task 1: Shared Editorial Theme and Primitives

**Files:**
- Create: `ForexFactoryMVP/Components/EditorialTheme.swift`
- Create: `ForexFactoryMVP/Components/EditorialMasthead.swift`
- Create: `ForexFactoryMVPTests/EditorialThemeTests.swift`
- Modify: `project.yml`
- Modify: `ForexFactoryMVP.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `EditorialTheme.paper`, `ink`, `mutedInk`, `rule`, `accent`, `subtleSurface`, `headline(_:)`, and `metadata`.
- Produces: `EditorialMasthead(section:kicker:date:)` and `EditorialRule(weight:)` for later screens.
- Consumes: SwiftUI `Color`, `Font`, `EnvironmentValues.colorScheme`, and standard system fonts only.

- [ ] **Step 1: Write the failing semantic presentation tests**

Add tests for the pure formatting helpers used by the masthead:

```swift
@testable import ForexFactoryMVP
import XCTest

final class EditorialThemeTests: XCTestCase {
    func testPublicationDateUsesUppercaseAbbreviatedEditorialFormat() {
        let date = Date(timeIntervalSince1970: 1_788_523_200)
        let value = EditorialDateFormatter.publicationDate(
            date,
            calendar: Calendar(identifier: .gregorian),
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        XCTAssertEqual(value, "SEP 4, 2026")
    }

    func testImpactMarkerMapsEveryKnownImpactToAStableLabel() {
        XCTAssertEqual(Impact.high.editorialLabel, "HIGH")
        XCTAssertEqual(Impact.medium.editorialLabel, "MEDIUM")
        XCTAssertEqual(Impact.low.editorialLabel, "LOW")
        XCTAssertEqual(Impact.holiday.editorialLabel, "HOLIDAY")
        XCTAssertEqual(Impact.unknown.editorialLabel, "UNKNOWN")
    }
}
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
xcodebuild test -quiet -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ForexFactoryMVPTests/EditorialThemeTests
```

Expected: compilation fails because `EditorialDateFormatter` and `Impact.editorialLabel` do not exist.

- [ ] **Step 3: Implement the semantic theme and masthead primitives**

Create focused, dependency-free types. Use adaptive UIColor providers for semantic paper colors:

```swift
enum EditorialTheme {
    static let paper = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.085, blue: 0.075, alpha: 1)
            : UIColor(red: 0.965, green: 0.945, blue: 0.90, alpha: 1)
    })
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.94, green: 0.92, blue: 0.87, alpha: 1)
            : UIColor(red: 0.075, green: 0.07, blue: 0.06, alpha: 1)
    })
    static let accent = Color(red: 0.48, green: 0.06, blue: 0.055)

    static func headline(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .serif, weight: weight)
    }
}
```

Implement `EditorialRule` as one or two rectangular hairlines without rounded clipping, and implement `EditorialMasthead` with a small uppercase kicker, a large serif section title, optional date, and the selected reference's double rule. Implement `EditorialDateFormatter` with injected calendar, locale, and time zone so the test is deterministic. Add `Impact.editorialLabel` without changing API decoding.

- [ ] **Step 4: Regenerate the Xcode project and run focused tests**

Run:

```bash
xcodegen generate
xcodebuild test -quiet -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ForexFactoryMVPTests/EditorialThemeTests
```

Expected: both tests pass and the new Swift files compile under strict concurrency.

- [ ] **Step 5: Commit the shared visual system**

```bash
git add ForexFactoryMVP/Components/EditorialTheme.swift \
  ForexFactoryMVP/Components/EditorialMasthead.swift \
  ForexFactoryMVPTests/EditorialThemeTests.swift \
  project.yml ForexFactoryMVP.xcodeproj/project.pbxproj
git commit -m "feat: add editorial visual system"
```

### Task 2: App Surface and Shared Content Components

**Files:**
- Modify: `ForexFactoryMVP/App/ForexFactoryMVPApp.swift`
- Modify: `ForexFactoryMVP/App/RootTabView.swift`
- Modify: `ForexFactoryMVP/Components/BilingualText.swift`
- Modify: `ForexFactoryMVP/Components/ContentStatusBanner.swift`
- Modify: `ForexFactoryMVP/Components/ImpactBadge.swift`

**Interfaces:**
- Consumes: theme and primitives from Task 1.
- Produces: shared bilingual headline/body styling, square impact marker, paper-colored tab/navigation surfaces, and rule-based status presentation.

- [ ] **Step 1: Establish the app-level paper surface**

Apply the semantic palette at the root and configure flat navigation/tab surfaces without changing tab destinations:

```swift
TabView { /* existing destinations */ }
    .tint(EditorialTheme.accent)
    .toolbarBackground(EditorialTheme.paper, for: .tabBar)
    .toolbarBackground(.visible, for: .tabBar)
```

Keep `scenePhase` activation exactly as implemented.

- [ ] **Step 2: Convert bilingual typography to editorial roles**

Extend `BilingualText` with an explicit role while preserving existing call sites through a default:

```swift
enum BilingualTextRole { case headline, sectionHeadline, body }

struct BilingualText: View {
    let english: String
    let chinese: String?
    var role: BilingualTextRole = .headline
    // Map English headline roles to serif; Chinese and body metadata remain sans-serif.
}
```

Ensure Chinese remains directly beneath English with 3–5 points of spacing.

- [ ] **Step 3: Replace pill and banner treatments**

Change `ImpactBadge` to an HStack containing a 6–8 point square marker and uppercase label. Change `ContentStatusBanner` to a flat full-width row with an oxblood leading rule and subtle surface tint. Remove every `Capsule`, rounded background, and filled alert treatment from these shared components.

- [ ] **Step 4: Build the app**

Run:

```bash
xcodebuild build-for-testing -quiet -project ForexFactoryMVP.xcodeproj \
  -scheme ForexFactoryMVP -destination 'generic/platform=iOS Simulator'
```

Expected: build succeeds with zero warnings.

- [ ] **Step 5: Commit shared component restyling**

```bash
git add ForexFactoryMVP/App ForexFactoryMVP/Components
git commit -m "feat: apply editorial app surfaces"
```

### Task 3: Newspaper News Front Page

**Files:**
- Modify: `ForexFactoryMVP/News/NewsListView.swift`
- Modify: `ForexFactoryMVP/News/NewsSectionPicker.swift`
- Modify: `ForexFactoryMVP/News/NewsArticleCard.swift`
- Modify: `ForexFactoryMVP/News/NewsCommentCard.swift`

**Interfaces:**
- Consumes: `EditorialMasthead`, `EditorialRule`, `EditorialTheme`, existing `NewsViewModel`, and current article/comment models.
- Produces: selected-reference front page layout with flat section navigation and rule-separated article rows.

- [ ] **Step 1: Add the selected-reference masthead to the News screen**

Replace the oversized native navigation title with an inline/hidden title and place this at the top of the content surface:

```swift
EditorialMasthead(
    section: "News",
    kicker: "FOREX FACTORY · PRIVATE EDITION",
    date: Date()
)
```

The masthead scrolls naturally with content and the filter remains an accessible toolbar menu.

- [ ] **Step 2: Rebuild section navigation as a newspaper strip**

Replace capsule backgrounds with plain buttons. The selected section uses ink weight plus a 3-point oxblood underline; unselected sections use muted ink. Keep horizontal scrolling and existing `model.select` behavior. Add one bottom hairline across the strip.

- [ ] **Step 3: Rebuild story rows around typographic hierarchy**

Update `NewsArticleCard` in this order:

```swift
VStack(alignment: .leading, spacing: 8) {
    metadataLine
    BilingualText(..., role: .sectionHeadline)
    squareCornerImage
    bilingualTeaser
    footerMetadata
}
```

Use a serif English headline, smaller Chinese subtitle, plain uppercase `EXCERPT`, compact comments, and a full-width bottom rule supplied by the list row rather than card chrome. Keep real API images through `AsyncImage`; remove `RoundedRectangle` clipping.

- [ ] **Step 4: Flatten latest-comment rows**

Use uppercase author/time metadata, editorial body typography, and rules. Preserve the existing navigation target and reaction count semantics.

- [ ] **Step 5: Build and run existing tests**

Run:

```bash
xcodebuild test -quiet -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: all existing and new tests pass.

- [ ] **Step 6: Commit the News front page**

```bash
git add ForexFactoryMVP/News/NewsListView.swift \
  ForexFactoryMVP/News/NewsSectionPicker.swift \
  ForexFactoryMVP/News/NewsArticleCard.swift \
  ForexFactoryMVP/News/NewsCommentCard.swift
git commit -m "feat: build newspaper news front page"
```

### Task 4: Editorial Article Detail

**Files:**
- Modify: `ForexFactoryMVP/News/NewsDetailView.swift`
- Modify: `ForexFactoryMVP/News/NewsSegmentView.swift`
- Modify: `ForexFactoryMVP/News/NewsMediaView.swift`
- Modify: `ForexFactoryMVPTests/APIModelsTests.swift`

**Interfaces:**
- Consumes: existing `NewsSegmentPresentationModel`, Safari sheet behavior, media loader, and editorial theme.
- Produces: flat newspaper article hierarchy without changing inline full-story link semantics.

- [ ] **Step 1: Extend presentation tests to protect link behavior during restyling**

Keep the current exact `Forex Factory excerpt... (full story)` assertion and add an assertion that the external action remains plain semantic data:

```swift
XCTAssertEqual(presentation.externalAction?.label, "Show More")
XCTAssertEqual(
    presentation.externalAction?.url,
    URL(string: "https://truthsocial.com/post/1")
)
```

Run the focused test before and after styling to prove the visual rewrite does not alter behavior.

- [ ] **Step 2: Recompose the article header**

Use uppercase source metadata, a large serif English headline, Chinese subtitle, and a strong rule before the body. Keep the existing teaser fallback while detail data is loading. Use paper background edge-to-edge and compact horizontal margins matching the selected reference.

- [ ] **Step 3: Flatten body segments and social/quote blocks**

Use editorial line spacing for English, quieter sans-serif Chinese, and a leading rule for quote/social segments. Remove the rounded background and clipping. Render `Show More` and `View source` as underlined oxblood text actions with at least a 44-point tap region. Preserve inline `(full story)` interception into `SFSafariViewController`.

- [ ] **Step 4: Square media and captions**

Remove rounded clipping from `NewsMediaView`, retain aspect-fit content, use a subtle rule around pale images only when needed, and place captions in small muted sans-serif below.

- [ ] **Step 5: Verify and commit detail styling**

Run:

```bash
xcodebuild test -quiet -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ForexFactoryMVPTests/APIModelsTests
```

Expected: all API/presentation tests pass.

```bash
git add ForexFactoryMVP/News/NewsDetailView.swift \
  ForexFactoryMVP/News/NewsSegmentView.swift \
  ForexFactoryMVP/News/NewsMediaView.swift \
  ForexFactoryMVPTests/APIModelsTests.swift
git commit -m "feat: typeset editorial news detail"
```

### Task 5: Financial Calendar and Editorial Settings

**Files:**
- Modify: `ForexFactoryMVP/Calendar/CalendarView.swift`
- Modify: `ForexFactoryMVP/Settings/SettingsView.swift`

**Interfaces:**
- Consumes: existing calendar/settings models and Task 1 theme primitives.
- Produces: flat financial data sheet and editorial configuration screen with unchanged actions.

- [ ] **Step 1: Rebuild the Calendar as a ruled data sheet**

Add `EditorialMasthead(section: "Economic Calendar", ...)`, use uppercase day datelines, and switch away from `.insetGrouped`. Each event retains time, currency, impact, bilingual title, and three values, but values align beneath a thin top rule with subtle vertical separators:

```swift
HStack(spacing: 0) {
    ValueCell(label: "ACTUAL", value: event.actual)
    Divider()
    ValueCell(label: "FORECAST", value: event.forecast)
    Divider()
    ValueCell(label: "PREVIOUS", value: event.previous)
}
```

- [ ] **Step 2: Rebuild Settings as flat editorial sections**

Replace rounded grouped form appearance with a paper-backed scroll layout or plain list. Use uppercase section headers, horizontal rules, rectangular underlined fields, and flat full-width Save/Test rows. Preserve secure Keychain copy and all actions exactly.

- [ ] **Step 3: Verify all states still compile**

Run:

```bash
xcodebuild build-for-testing -quiet -project ForexFactoryMVP.xcodeproj \
  -scheme ForexFactoryMVP -destination 'generic/platform=iOS Simulator'
```

Expected: Calendar and Settings compile with strict concurrency and no model changes.

- [ ] **Step 4: Commit remaining screens**

```bash
git add ForexFactoryMVP/Calendar/CalendarView.swift \
  ForexFactoryMVP/Settings/SettingsView.swift
git commit -m "feat: restyle calendar and settings editorially"
```

### Task 6: Visual QA, Device Build, and Installation

**Files:**
- Create: `design-qa.md`
- Create: `docs/design-references/editorial-news-home-implementation.png`
- Modify: any visual source file with a P0/P1/P2 discrepancy found during QA

**Interfaces:**
- Consumes: selected reference image, all completed screens, simulator/device tooling.
- Produces: a passing visual QA report, verified build, pushed branch, and installed iPhone app.

- [ ] **Step 1: Run the complete automated suite and hygiene checks**

Run:

```bash
xcodebuild test -quiet -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild build-for-testing -quiet -project ForexFactoryMVP.xcodeproj \
  -scheme ForexFactoryMVP -destination 'generic/platform=iOS Simulator'
git diff --check
```

Expected: all tests pass, both builds succeed, and no whitespace errors are reported.

- [ ] **Step 2: Launch at the reference viewport and capture the four screens**

Build/install on the iPhone 17 Pro simulator, then capture News, News Detail, Calendar, and Settings at 390 × 844 points. Save the News capture as:

```text
docs/design-references/editorial-news-home-implementation.png
```

Use live API content when credentials are available; otherwise use the app's existing cached content. Do not add permanent mock data to production code.

- [ ] **Step 3: Compare the selected reference and implementation**

Read the Product Design `design-qa` skill, inspect both images at the same viewport, and write `design-qa.md`. It must cover hierarchy, color, typography, spacing, rules, image corners, navigation, Dynamic Type risk, and visible interaction states. Fix every P0/P1/P2 and repeat capture/comparison until the file contains:

```text
final result: passed
```

- [ ] **Step 4: Commit visual QA evidence**

```bash
git add design-qa.md docs/design-references
git add ForexFactoryMVP ForexFactoryMVPTests project.yml ForexFactoryMVP.xcodeproj/project.pbxproj
git commit -m "test: verify editorial interface fidelity"
```

- [ ] **Step 5: Push the feature branch**

```bash
git push -u origin codex/editorial-ui
```

Expected: local branch and `origin/codex/editorial-ui` have no commits ahead or behind.

- [ ] **Step 6: Build, install, and launch on the paired iPhone 15 Pro**

Run:

```bash
xcodebuild -quiet -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP \
  -configuration Debug -destination 'id=00008130-000E69241412001C' \
  -derivedDataPath /tmp/forex-factory-editorial-device \
  -allowProvisioningUpdates build
xcrun devicectl device install app \
  --device B3155DEA-0774-5E49-8C4D-3A641C955EDD \
  /tmp/forex-factory-editorial-device/Build/Products/Debug-iphoneos/ForexFactoryMVP.app
xcrun devicectl device process launch \
  --device B3155DEA-0774-5E49-8C4D-3A641C955EDD \
  shop.zhenmei.ForexFactoryMVP
```

Expected: installation succeeds; launch succeeds when the iPhone is unlocked. Confirm the installed bundle with `devicectl device info apps` even if launch is blocked by lock state.
