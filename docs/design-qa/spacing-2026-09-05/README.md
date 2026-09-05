# App spacing and discussion refinement — 2026-09-05

The user clarified that lines are welcome as part of a visual hierarchy; an interface made only of lines is the problem. They requested analysis, changes across every app page, and installation on their phone. `Last updated` must remain fully spelled out, with date, time, seconds and timezone.

## Follow-up: remove redundant branding

Removed the FOREX FACTORY masthead label from all root pages. The existing date aligns left; Settings has no empty metadata row. Full Last updated remains unchanged. The before/after screenshots below precede this small follow-up. Device build passed; build log: `/private/tmp/forex-remove-masthead-brand.log`.

## Findings and changes

Fresh native captures were produced before editing, using fixture data, then repeated after implementation. These are actual SwiftUI renders, not mockups. The same capture harness is archived here outside the normal test target.

1. **News:** the old header stacked a 44 pt timestamp target, 24 pt bottom padding, an independent 44 pt right-aligned filter, and another 12 pt gap. The filter now sits beside News as a filled square control in the left title group. Full Last updated remains directly below. The category rail and story rows use tighter spacing. At accessibility sizes the filter wraps beneath the title, still left aligned. [Before](before/02-news-light.png) · [After](after/02-news-light.png).
2. **Calendar:** reduced masthead gaps, day-band padding, row padding, and spacing within an event. Related Actual/Forecast/Previous values remain aligned. Date bands retain a tinted surface. [Before](before/01-calendar-light.png) · [After](after/01-calendar-light.png).
3. **Contracts:** tightened the shared header, filter rail, row padding, summary/metric gap, and metric-row spacing. Every contract metric remains expanded. [Before](before/03-contracts-light.png) · [After](after/03-contracts-light.png).
4. **Settings:** reduced the header-to-form gap, field-group gaps, and spacing between major sections. Filled inputs and clear action buttons retain their usable dimensions. [Before](before/04-settings-light.png) · [After](after/04-settings-light.png).
5. **Event detail:** moved Last updated into the event identity group and kept larger spacing for separate content sections. Value and history surfaces remain distinct. [Before](before/07-calendar-detail.png) · [After](after/07-calendar-detail.png).
6. **Article and comments:** grouped the update time with article metadata, reduced paragraph-section and end-of-article gaps, and replaced the large Discussion/Comments panel with a compact tinted Comments bar. Comments use square initial markers, author-aligned bodies, grouped footer information, and indented replies with a subtle connector. Comment-feed double padding was removed. [Before](before/19-article-discussion-boundary.png) · [After](after/19-article-discussion-boundary.png).

## Spacing principles

Shared roles: 4 pt for closely related labels, 8 pt for related content, 12 pt for component spacing, 14 pt for ordinary list row padding, 20 pt page gutters, and 24 pt between distinct sections. News row padding remains 16 pt. These are semantic roles, not a rule to make every gap identical. Full timestamps, English UI, existing refresh behavior and the eager article scrolling stack are preserved.

Typography, surface tint, alignment and lines work together. No global ban on lines or blanket reduction in text size was introduced. Standard controls retain their 44 pt or larger touch targets. Comment identity markers are neutral initials because the current API has no avatar URL.

## Verification

- 62 simulator tests passed with zero failures: 60 existing tests plus two optional capture tests.
- 26 before and 26 after PNGs captured; inspected roots, article/event detail, comment boundary/feed, empty/error comments, impact dialog, dark appearance and accessibility text samples.
- Loaded article scroll regression: initial and all six reverse-scroll content heights were 11680 pt. Top remained reachable; all nine images were requested once each.
- Device build succeeded with Swift warnings treated as errors.
- Installed on the connected iPhone 15 Pro on 2026-09-05 at approximately 17:10 Asia/Shanghai, using the existing app bundle identifier.
- Source whitespace check passed. No app-owned ProgressView or refreshable was introduced.

Logs: `/private/tmp/forex-spacing-before.log`, `/private/tmp/forex-spacing-after.log`, `/private/tmp/forex-spacing-device.log`. Selected test evidence is retained in `verification.txt`.

## Limits

Screenshots use controlled fixtures at 402 × 874 pt and accessibility samples at 375 pt; the connected phone uses live content. Screenshot 20 is a standalone large-text comment fixture on a tinted test background, not the full article section. This is not a claim of exhaustive VoiceOver, keyboard, or all-device accessibility testing. Remote media can still grow a document as it initially arrives; the scrolling regression covers already-loaded content.
