# Editorial UI Design QA

- Source visual truth: `docs/design-references/editorial-news-home-selected.png`
- Final implementation: `docs/design-qa/editorial-news-implementation.png`
- Side-by-side evidence: `docs/design-qa/editorial-news-comparison.png`
- Additional screen evidence: `docs/design-qa/editorial-calendar.png`, `docs/design-qa/editorial-settings.png`
- Viewport: iPhone 17 Pro simulator, 402 × 874 points
- Source pixels: 853 × 1844
- Implementation pixels: 1206 × 2622 (@3x)
- Comparison normalization: both images scaled to 603 × 1311 pixels; device frames excluded; equivalent portrait aspect ratio retained
- State: light appearance, News / Latest Stories, live backend data, bilingual content

## Full-view comparison evidence

The final capture preserves the selected concept's newspaper hierarchy: compact private-edition kicker and date, large English serif masthead, double rules, oxblood section state, warm paper field, serif English story headlines, muted Chinese subtitle lines, hairline story separators, and a flat persistent navigation strip. The implementation intentionally adds an impact filter and bilingual section labels because they are functional product requirements. The currently fetched first story has no source image or teaser; the absence is data-driven rather than a layout substitution.

The full-resolution comparison is legible enough to evaluate type hierarchy, section spacing, color, rules, article density, and bottom navigation. A separate focused crop was not needed because the combined artifact retains readable text at the normalized size.

## Required fidelity surfaces

- Fonts and typography: English display and story headings use the iOS serif design; Chinese and utility copy use the system sans; metadata is compact and uppercase where appropriate. Wrapping is natural and no headline truncation is visible.
- Spacing and layout rhythm: content uses consistent 16–20 point gutters, square media, flat rows, rules instead of cards, and no app-authored corner radii, shadows, or gradients. The horizontal section rail deliberately scrolls to preserve complete long section names.
- Colors and tokens: adaptive eggshell paper, near-black ink, warm gray metadata, and restrained oxblood selection match the concept. Impact remains semantic green/amber/red.
- Image quality and assets: live source imagery is rendered at source aspect ratio with square edges and no artificial crop. Current live lead items contain no media; the UI does not invent placeholders.
- Copy and content: live Forex Factory section names, sources, relative times, English headlines, Chinese translations, impact, comments, calendar values, and settings copy are preserved.

## Findings

No actionable P0, P1, or P2 mismatch remains.

- P3: a partially visible next section title acts as the horizontal-scroll affordance. This is acceptable for the MVP; a subtle edge fade could be explored later without changing the flat visual language.
- P3: live content can produce a text-only lead story, while the concept uses an image-led example. This is expected source-data variance.

## Comparison history

### Iteration 1

- Evidence: `docs/design-qa/editorial-news-iteration-1.png`, `docs/design-qa/editorial-calendar-status-iteration-1.png`
- [P1] Native iOS navigation and tab chrome introduced rounded glass surfaces that contradicted the selected flat newspaper concept.
- [P1] The status banner's decorative rectangle accepted an unbounded vertical proposal and expanded the banner over most of the calendar screen.
- [P2] The native toolbar reserved excessive blank space above the masthead.

Fixes made:

- Replaced the native tab presentation with a flat custom tab strip separated by a strong rule.
- Changed the status accent from a layout child to a bounded overlay.
- Hid empty navigation bars and moved the impact filter into the newspaper header as a flat text control.

### Iteration 2

- Evidence: `docs/design-qa/editorial-news-comparison.png`, `docs/design-qa/editorial-calendar.png`, `docs/design-qa/editorial-settings.png`
- The earlier P1/P2 issues are absent. Mastheads begin directly below the safe area, error/status content remains intrinsically sized, navigation is flat, and calendar/settings retain the same editorial system.

## Interaction checks

- News, Calendar, and Settings states launched successfully at the target phone viewport.
- News loaded live backend data and displayed English/Chinese content.
- Custom tab targets retain 44-point-or-larger hit areas and selected accessibility traits.
- Dynamic Type uses scalable fonts and masthead scaling with a single-line minimum scale factor.

final result: passed
