# Global UI redesign review

## Verdict

Task 2 (article/discussion): **approved at source level** after scoped re-review of the partial-discussion recovery fix. The reader implementation satisfies the reviewed source-level requirements: English-only body/comment presentation, independent article and discussion failures, loaded-comment preservation on pagination failure, API order with stable deduplication, bounded reply context, honest identities/reactions, retained segment clamping/media/source navigation, and visible detail navigation.

Whole change: **approved at source level; no outstanding actionable findings** after re-reading all three fixes in the current production files. Final native visual QA remains with the parent. No source-level route, API contract, refresh-policy, credential-storage, contract-order, or hidden-contract-metric regression was identified. All six secondary contract metrics are always rendered and stack at accessibility sizes.

## Resolved findings

### [P2] Offer recovery for all inferred partial discussion states

Location: `ForexFactoryMVP/News/NewsDetailView.swift:195–200`.

The heading correctly treats `loadedCount < totalCount` as partial even when `commentsComplete` is true, but the recovery control uses only `commentsComplete == false`. For example, a detail reporting four comments followed by a comments response with two items, `comments_complete: true`, and no cursor displays “2 of 4 comments available” with no refresh action. Detail and discussion are independent requests, so count/collection snapshots can differ; the helper test explicitly recognizes this combination as partial. There is no pull-to-refresh on this detail screen, and loading more is impossible without a cursor, leaving the reader unable to retry that collection without leaving the screen. Use the same inferred presentation state for the heading and footer; when it is partial and has no cursor, provide refresh/retry. Refreshing article metadata as appropriate can also resolve a stale reported count.

**Resolved:** `NewsDetailView.swift:139–147` centralizes the inferred presentation state; the heading uses it at line 156 and the footer checks `commentsPresentation?.isPartial == true` at line 201. A complete/count-mismatch response without a cursor now receives the Refresh comments action at line 205. Cursor pagination and explicit failure retry retain precedence.

### [P2] Give short category labels a 44-point minimum width

Location: `ForexFactoryMVP/Components/InterfaceComponents.swift:64–65`.

The shared CategoryTab enforces a 44-point height but its width is just the label plus four points. Contracts’ “All” is therefore substantially narrower than the specified 44 × 44 hit target at normal text size. The surrounding HStack spacing does not belong to the button's rectangular content shape. Apply a minimum width of 44 inside the button label/content shape so the shortest filter remains easy to hit without changing the shared rail behavior.

**Resolved:** `InterfaceComponents.swift:65` now applies `.frame(minWidth: 44, minHeight: 44)` inside the label before its rectangular content shape, covering short labels as requested.

### [P2] Use an adaptive foreground on the primary button

Reviewed location: `ForexFactoryMVP/Components/InterfaceComponents.swift:85–86`; supporting color: `ForexFactoryMVP/Components/EditorialTheme.swift:30–31`.

The originally reviewed primary style always used white text on the accent background. Dark appearance changes that accent to RGB (0.48, 0.69, 0.98), yielding approximately 2.23:1 contrast for the Save settings label.

**Resolved:** `EditorialTheme.swift:37–40` defines white on-accent text for light appearance and dark ink RGB (0.06, 0.10, 0.17) for dark appearance. `InterfaceComponents.swift:85` uses this token for primary labels. The dark primary foreground/background pair now has approximately 7.85:1 contrast. Final native visual verification remains with the parent.

## Scope and evidence

- Read the complete review-package diff, authorized global redesign spec, Task 2 report, current changed source files, shared components, model shapes, and relevant backend comments envelope/collection code.
- Reviewed Calendar list/detail, News list/filters/reader/comments/media/source actions, Contracts, Settings, shared tokens/controls, and root selection/refresh lifecycle. Feed comment cards do not enable their internal permalink; detail cards do, avoiding nested Link controls inside feed Buttons.
- The existing price/compact-number precision behavior is retained; no new numeric precision regression was identified. English translations remain in API models but are no longer used as display fallbacks in the reviewed readers.
- Did not rerun tests, compile, alter app code, make commits, or use screenshot fixtures as live data. The reader report records six mutation-checked helper tests and parsing verification. During review, the parent reported the integrated iOS run passed 56 tests with zero failures.
- Scoped re-review read only the three corrected production implementations and updated this report. No tests were rerun. The parent reports a subsequently fixed test-only capture-harness Swift 6 self-qualification error; the native capture run is underway. That capture run is not claimed complete by this review.
- This is source-level functional/spec/accessibility review. Narrow-width and large-text rendering, light/dark visual consistency, keyboard presentation, native hit testing, and screen captures remain the parent's visual QA responsibility; no unobserved clipping or screenshot result is claimed here.

## Final visual-polish source recheck

Re-read only the subsequent NewsCommentCard footer, NewsDetailView action styling, and NewsListView separator changes. **No new actionable findings; Task 2 and overall source approval stand.**

- The comment footer still uses the real optional reaction label (including supplied zero); it introduces no reaction button. The permalink remains opt-in with `showsPermalink = false` by default, so feed Buttons contain no Link. Detail links retain the source permalink, the explicit “View comment on Forex Factory” accessibility label, and 44-point minimum height. The footer changes to a leading VStack at accessibility sizes and removes the horizontal spacer there.
- Article/comment retry, pagination, and refresh actions retain their original handlers, state conditions, and minimum heights; explicit blue semibold styling changes presentation only.
- News list separator guides do not alter row destinations, content shapes, or data ordering. Both row types retain their 20-point horizontal insets. Exact native separator placement remains part of the parent's capture review.
- No app code was edited and no builds or tests were run for this recheck. The native capture rerun was reported underway, not complete.
