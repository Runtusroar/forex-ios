# Task 2 report — News article and discussion

Implementation is ready for parent integration. No commits, worktrees, simulator builds, model/API changes, or shared theme changes were made.

## Changed files

- `ForexFactoryMVP/News/NewsDetailView.swift`: sans English reading layout, full source/date/time metadata, fallback image preservation, in-app original link, visible detail navigation bar, independent article/comment load failures, tinted square discussion heading with count/collection status, empty/partial/retry states, cursor pagination preserving API order, bounded reply indentation, cancellation checks, retained media-processing polling and retry behavior.
- `ForexFactoryMVP/News/NewsSegmentView.swift`: English body only, preserved attributed full-story links, clamping and media routes; a single left rule for quotes/social segments; shared in-app browser wrappers used by article original and comment permalinks.
- `ForexFactoryMVP/News/NewsCommentCard.swift`: honest square SF Symbol identity, author/date/time, full English comment, loaded parent context (generic context for missing parent), actual reactions including zero, optional in-app permalink. Default initializer remains noninteractive for cards embedded inside feed Buttons.
- `ForexFactoryMVP/News/NewsCommentsPresentation.swift` (new): parent resolution scoped to loaded comments from the same article, English unavailable fallback, reaction formatting, partial collection inference, stable page deduplication.
- `ForexFactoryMVPTests/NewsCommentsPresentationTests.swift` (new): six meaningful regression tests for the above behavior.

## Verification evidence

- Wrote tests first; the initial standalone Swift package run failed because the new presentation types were not implemented. This initial failure was compilation, not a behavioral assertion failure.
- Ran the six real XCTest cases using a temporary host Swift package at `/tmp/forex-news-tests`, containing exact copies of production APIModels and the new presentation helper: six passed, zero failures.
- Mutated only the temporary copy to remove page deduplication, missing-parent article scope, self-parent protection, zero reaction display, cursor/count partial detection, and English-only fallback. Every test failed (seven assertion failures), proving the assertions detect those regressions. Restored the production helper and reran: six passed, zero failures.
- `swiftc -frontend -parse` passed for all four owned production files.
- `git diff --check` passed.
- Parent owns the integrated iOS compile, full test suite, real device/simulator screenshots, light/dark review, and accessibility-size captures. Host helper tests and parsing do not prove SwiftUI type checking or native rendering.

## Self-review

- English rendering contains no `zhHans`, `BilingualText`, or serif usage in the three views. Missing English shows a clear unavailable message rather than translation fallback.
- Full comment text wraps, author/time metadata stacks, and reply inset stays 12 pt regardless of nesting depth.
- Quotes have exactly one restrained outer rule. Removed the former inner plus outer quote rule.
- Reactions are labels, never buttons. No fake portraits, composer, or social data.
- Default `NewsCommentCard(comment:)` has no nested Link. Only article detail opts into the permalink.
- Article and comments load concurrently, with separate error/loading state. Comments can fail while the article remains displayed; pagination failures retain previously loaded comments. Canceled loads do not replace state or show errors.
- Original article, segment source, media destination, and comment permalink all retain source URLs and use the in-app Safari reader.
- Thumbnail fallback and five two-second processing-media retries remain. Article retry also restarts processing checks.

## Integration notes / limitations

- Regenerate the Xcode project via its existing XcodeGen workflow so the new helper and test file enter their targets.
- Discussion state is held in the detail view, while only pure presentation/page logic is unit tested here. Native integration should inspect loaded, partial, empty, comment-failure, and narrow accessibility layouts.
- Parent name resolution uses the loaded comment collection only and never fetches or invents an identity. The generic missing-parent label is intentional.
