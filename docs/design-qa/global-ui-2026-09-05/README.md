# Global UI redesign — native verification

**Result: passed for the reviewed native layouts and source scope.** Implemented locally on `codex/global-ui-redesign`. This replaces the earlier newspaper and rounded readability designs across Calendar, News, Contracts and Settings.

## Design

The [Precision Ledger concept](../../design-references/global-redesign-2026-09-05/01-precision-ledger.png) supplied the shared light, flat direction. The user's implementation corrections take precedence: all contract metrics appear directly, the interface and displayed content are English, large rounded cards are removed, and article/comment reading receives its own layout.

Shared system: system sans typography; 20-point gutters; continuous white/graphite surfaces; quiet date/column bands; one blue action accent; single row separators; square content and 3-point input/button corners. Native iOS detail back controls retain OS styling. Larger text stacks financial metrics and comment footers instead of shrinking essential content. Bottom-tab text is capped at the largest standard Dynamic Type size to retain four readable labels; page content continues to accessibility sizes.

Contracts expose rank, symbol, price, signed change, turnover, volume, amplitude, high, low and trades without disclosure controls. News articles distinguish headline, source/time, text, quote and discussion. Comments show an honest identity marker, author/time, full text, loaded parent context, supplied reaction count and source permalink. Partial collection, empty discussion and failed requests have distinct feedback and recovery.

## Screen gallery

All 23 PNGs are renders of production SwiftUI views with isolated fixture data, captured on the iPhone 17 Pro simulator. They are not live market data or image-generated implementation mockups.

| Screen | Light | Dark / larger text |
| --- | --- | --- |
| Calendar | [Agenda](01-calendar-light.png) | [Dark](01-calendar-dark.png) · [Accessibility 1](08-calendar-large-text.png) |
| News | [Latest](02-news-light.png) | [Dark](02-news-dark.png) · [Accessibility 1](17-news-large-text.png) |
| Contracts | [All metrics visible](03-contracts-light.png) | [Dark](03-contracts-dark.png) · [Accessibility 1](09-contracts-large-text.png) |
| Settings | [Connection form](04-settings-light.png) | [Dark](04-settings-dark.png) · [Accessibility 1](10-settings-large-text.png) |
| Calendar detail | [Release and history](07-calendar-detail.png) | — |
| News detail | [Article and discussion heading](05-news-article.png) | — |
| Discussion | [Comments and reply](06-news-comments.png) | [Dark](06-news-comments-dark.png) · [Accessibility 3](11-comment-large-text.png) |
| Comment feed | [Latest comments](16-comment-feed.png) | — |
| Impact filter | [Selected high impact](12-impact-filter.png) | — |
| Empty/error | [Calendar failure](13-calendar-empty-error.png) | [Comment failure](14-comments-error.png) · [No comments](15-comments-empty.png) |
| Partial collection | [Reported count exceeds collected count](18-comments-count-mismatch.png) | Refresh remains available even when the envelope says collection is complete. |

## Verification

- Xcode 26.6 / iOS 26.5 simulator; Swift 6, complete strict concurrency and warnings as errors. Project generated with XcodeGen.
- Final standard suite: **56 tests passed, 0 failures**, after archiving the capture harness out of the normal test target. Includes six new comment-presentation regressions for parent context, English fallback, reactions, partial collections and stable page deduplication.
- Final native capture run: **1 capture test passed, 0 failures; 23 screenshots**. Earlier integrated capture run also passed all 57 tests (56 standard + 1 capture).
- Native frames: 402 × 874 points, and 375 × 874 at accessibility sizes; PNG output at 2×. Light and dark root screens retain the actual shared tab bar. Details use the native NavigationStack.
- Visually inspected all represented screen types, including the original whole-app concept and four light roots together. Essential values, comment bodies and titles wrap; standard news-list teasers intentionally remain two-line previews.
- Independent [source review](source-review.md) approved the full change and subsequent scoped fixes. No source-level route, refresh-policy, API, credential-storage, ordering or hidden-metric regression was identified.
- `git diff --check`: passed.

Commands for the final standard run:

```sh
xcodegen generate
xcodebuild test -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP \
  -destination 'platform=iOS Simulator,id=A511E08D-75DC-4773-9BEB-66E13325622C' \
  -derivedDataPath /private/tmp/forex-global-ui-build \
  -resultBundlePath /private/tmp/forex-global-ui-final.xcresult
```

Local evidence: `/private/tmp/forex-global-ui-final.log`, `/private/tmp/forex-global-ui-final.xcresult`, `/private/tmp/forex-global-ui-captures-3.log`, `/private/tmp/forex-global-ui-captures-3.xcresult`. A concise [test summary](test-summary.txt) is retained alongside these screenshots.

The optional [native capture harness](GlobalUICaptureTests.swift) is archived here. To reproduce, temporarily copy it to `ForexFactoryMVPTests/`, regenerate with XcodeGen, and run `-only-testing:ForexFactoryMVPTests/GlobalUICaptureTests`; archive it again afterward. It uses mock API responses and an isolated key store, never production credentials.

## Findings resolved

- Dark primary-button label contrast: adaptive dark ink replaces white on the pale blue dark-mode accent (reviewed contrast approximately 7.85:1).
- Short category targets: minimum width and height of 44 points, including “All”.
- Partial discussion recovery: header and footer share inferred collection state, including count mismatches with a complete envelope.
- News separators: explicit alignment to the common page gutters, including the comment feed.
- Comment footer: secondary source link is compact, shares the reaction footer at standard sizes and stacks at accessibility sizes. Retry, refresh and pagination actions use clear blue semibold text.

No outstanding actionable P0/P1/P2 issue was found within this reviewed scope. Long numeric precision is retained, and category rails remain horizontally scrollable.

## Scope limits

These are fixture-backed native layout captures plus automated model/helper tests and source review. They do not constitute an end-to-end live-backend, physical-device, VoiceOver, keyboard, or external-browser interaction pass. OS status-bar pixels are not included in the hosting-window captures. Article media rendering and processing behavior were preserved and covered by existing helper tests; these text fixtures do not validate newly downloaded images. The work is local and has not been installed on a physical phone or published.
