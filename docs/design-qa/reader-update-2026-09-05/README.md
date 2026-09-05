# Reader stability and quiet updates — 2026-09-05

Implemented, verified, and installed on the connected iPhone 15 Pro. The app launched successfully after installation.

## Changes

- Removed app-owned loading spinners, including header, details, image placeholders, Settings and pagination. Native pull-to-refresh indicators are removed. Existing automatic refresh intervals remain; tapping the root page's update timestamp manually refreshes without animation.
- Display last update as `yyyy-MM-dd HH:mm:ss UTC+8`, using server response/cache dates. A failure retains the last successful data timestamp; no current-time substitute is invented for stale or absent data. News uses the selected feed/filter's own date. Initial unavailable timestamps show an em dash. Settings reports the last successful connection check separately.
- News cards show source and full publication date/time on separate lines. Article and comment publication metadata uses the same second-precision timestamp format.
- News detail uses a continuous eager layout. Loaded media stays in the view hierarchy when returning from the bottom, avoiding repeated image requests and height estimation changes.
- Discussion occupies a full-width gray surface, with a blue DISCUSSION label, bold Comments title and generous separation from the white article. Comment body uses scalable subheadline text, one size below article body; author, reply, reaction and original-link presentation remains intact. The distinction persists midway through comments and in dark appearance.

## Reproduction and verification

The native scrolling regression uses a real production NewsDetailView, 36 paragraphs of varying height and 9 portrait images supplied asynchronously through a fixture API. Before the fix, reverse scrolling changed the loaded document height by 1,901 points, returned a 725-point offset after requesting the top, and requested some images three times. Changing only the lazy article layout to eager layout made the same test pass. In the final design, all six reverse-scroll measurements were 12,118 points and all nine images were requested exactly once; return-to-top passed.

- Final standard simulator suite: **60 tests passed, 0 failures**. Includes the retained scrolling regression, UTC+8 midnight/second formatting, cached timestamp preservation on failure, feed timestamp selection, and existing data/media/refresh tests.
- Integrated capture run: 61 tests passed (60 standard + one native capture), producing 23 PNGs. One subsequent boundary capture test passed, producing 3 additional PNGs.
- Native visual inspection covered timestamps at ordinary and accessibility sizes, Calendar/News/Contracts roots, light/dark discussion, article-to-discussion transition, and large comment text.
- Focused independent source review: approved; no actionable new regression. The reviewer confirmed no app-owned ProgressView or refreshable references, retained refresh actions, timestamp semantics, and the scrolling mechanism. No independent runtime/a11y pass was claimed by the reviewer.
- iOS device build succeeded. Device installation and launch succeeded on 2026-09-05. Source whitespace check passed.

Evidence logs: `/private/tmp/forex-reader-scroll-before.log`, `/private/tmp/forex-reader-scroll-after.log`, `/private/tmp/forex-reader-update-verified.log`, `/private/tmp/forex-reader-update-verified.xcresult`, `/private/tmp/forex-reader-update-captures.log`, `/private/tmp/forex-reader-boundary.log`, `/private/tmp/forex-reader-update-device.log`. Selected regression evidence is retained in [verification.txt](verification.txt).

## Screens

| Surface | Preview |
| --- | --- |
| News dates and last update | [Light](02-news-light.png) · [Large text](17-news-large-text.png) |
| Calendar last update | [Light](01-calendar-light.png) · [Large text](08-calendar-large-text.png) |
| Contracts last update | [Light](03-contracts-light.png) · [Large text](09-contracts-large-text.png) |
| Article/discussion boundary | [Light](19-article-discussion-boundary.png) · [Dark](19-article-discussion-boundary-dark.png) |
| Discussion | [Light](06-news-comments.png) · [Dark](06-news-comments-dark.png) · [Large text](20-discussion-large-text.png) |
| Comment error/empty | [Error](14-comments-error.png) · [Empty](15-comments-empty.png) |

These screenshots are native fixture-backed layout captures, not live market content. The optional [capture harness](GlobalUICaptureTests.swift) is archived outside the normal test target. The durable scrolling test remains in ForexFactoryMVPTests.

The scrolling regression specifically covers already-loaded mixed text/media content and reversing scroll direction. Initial or processing-media arrivals can still legitimately grow the document once; this is not a claim that every remote article, device gesture or network timing has been exhaustively tested. Eager detail layout retains loaded content in memory; root feed lists remain lazy and comment pagination remains explicit.
