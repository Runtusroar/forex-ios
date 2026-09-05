# Readability revision — 2026-09-05

This revision responds to feedback that Calendar mixed table and card conventions, used too many lines, and made sustained reading tiring. It supersedes the earlier newspaper styling constraints for the affected views.

## Implemented direction

- Neutral page background and separate light/dark content surfaces.
- Calendar events grouped by UTC+8 date in native inset grouped lists; a single subtle separator between events.
- System type for calendar titles and aligned Actual / Forecast / Previous values without internal borders; Actual carries more weight.
- Calendar value columns become stacked at accessibility text sizes so long values remain readable.
- Compact mastheads and quieter tab labels; serif typography remains on news titles.
- News uses consistent white reading rows, lighter metadata, and shorter previews with full content retained in details.
- Settings uses native form groups. API URL, secure-key storage, save/test/remove actions, refresh behavior, data ordering, routes, and backend interfaces retain their existing implementation.
- Semantic red and green remain separate from the blue action accent, including contract percentage changes and calendar value states.

## Validation

- `git diff --check`: passed during implementation.
- Palette calculation: secondary text contrast is 5.21:1 on the light content surface, 4.86:1 on the page, and 4.53:1 on the subtle surface. Dark secondary text is 7.58:1 on the content surface, 8.73:1 on the page, and 6.42:1 on the subtle surface. This is a token calculation, not a full accessibility audit.
- Shared theme, masthead, bilingual text, status, impact, news rows, and the exact extracted Calendar event row: standalone Swift 6 typecheck passed with strict concurrency and warnings as errors.
- Independent source review: findings on large-text metadata, Specs width, and non-color result-state cues addressed and rechecked; no remaining concrete issue reported.
- Full simulator build and test run: passed on iPhone 17 Pro / iOS 26.5 using Xcode 26.6, Swift 6, strict concurrency, and warnings as errors. All 49 tests passed: 48 existing tests plus one temporary native capture harness.
- Native screenshot review covered light/dark Calendar, accessibility text sizes at 375 pt width, long bilingual titles and values, News, Settings, empty/error Calendar, and event details with result-state labels and sparse Specs. Rounded header-row clipping and crowded News timezone/filter text found during review were corrected and recaptured. No clipping or overlap remains in the reviewed visible content; the long-event view scrolls beyond the captured viewport.
- Final capture test result: `/private/tmp/forex-readability-final-captures.xcresult`; build/test log: `/private/tmp/forex-readability-final-captures.log`.
- After moving the optional harness out of the normal test target and regenerating the Xcode project, the final standard suite passed again: 48 tests, zero failures. Result: `/private/tmp/forex-readability-final-suite.xcresult`; log: `/private/tmp/forex-readability-final-suite.log`. Final `git diff --check` passed.

## Native captures

These captures use illustrative fixture data rather than live releases. They render the production SwiftUI content views in a native hosting window at 2× scale. They do not cover live API connectivity, the root tab bar, OS status chrome, or the full interaction flow.

| Capture | State |
| --- | --- |
| [Calendar](01-calendar-light.png) | Light, 402 × 874 pt |
| [Calendar dark](02-calendar-dark.png) | Dark, 402 × 874 pt |
| [Calendar large text](03-calendar-large-text.png) | Accessibility 1, 375 × 874 pt |
| [News](04-news-light.png) | Light, fixture news |
| [Settings](05-settings-light.png) | Light, isolated settings without a saved key |
| [Long event](06-long-event-large-text.png) | Accessibility 3, long bilingual title and numeric values |
| [Empty/error Calendar](07-calendar-empty-error.png) | Empty state with error banner |
| [Event detail](08-calendar-detail.png) | Value states, sparse Specs, and History |

## Reproduce

The optional [capture harness](ReadabilityCaptureTests.swift) is stored here rather than in the normal test target. To regenerate captures, temporarily copy it to `ForexFactoryMVPTests/ReadabilityCaptureTests.swift`, run `xcodegen generate`, and run:

```sh
xcodebuild test \
  -project ForexFactoryMVP.xcodeproj \
  -scheme ForexFactoryMVP \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

Images are retained as XCTest attachments; the test also prints each exported PNG path prefixed with `READABILITY_CAPTURE`. Copy those files here, remove the temporary copy from the test directory, and regenerate the project. No credentials or live market data are needed.
