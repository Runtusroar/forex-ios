# Global UI redesign

Status: implemented and verified locally; see [native QA and screen gallery](../../design-qa/global-ui-2026-09-05/README.md). Use the recommended Precision Ledger light direction as the starting point, with a matching dark appearance. User corrections: show all Contracts metrics directly, and give News articles and comments a deliberately designed reading/discussion layout. This supersedes earlier newspaper and rounded readability directions.

## Product and goal

Forex Factory is an iPhone information app with four peer tabs: Calendar, News, Contracts, and Settings. Its primary tasks are scanning economic releases, reading market news, comparing futures contracts, and configuring the connection. The redesign must reduce reading effort and make all screens feel like the same product.

## Hard requirements

- Design all four tabs together, including their details, filters, forms, feedback, and navigation.
- English interface and English content presentation. Retain translation data and API fields, but do not render Chinese alongside English. Missing English content must use a clear English unavailable state, not silently switch languages.
- Content surfaces, sections, and rows use square corners. Inputs and buttons use 0–3 pt corners. Avoid pill controls, oversized rounded cards, nested cards, decorative borders, shadows, and glass effects.
- Establish hierarchy through alignment, whitespace, size, and weight. Use only the row separators necessary for scanning; no vertical cell borders or double rules.
- Retain API contracts, ordering, refresh policy, credentials, source links, and media behaviors.

## Shared visual system

| Element | Rule |
| --- | --- |
| Typography | System sans throughout; no newspaper serif mastheads. Use semantic Dynamic Type styles. |
| Screen titles | Approx. 26–28 pt, semibold; same placement and scale on all four tabs. |
| Body | Approx. 15–17 pt, regular; article body with comfortable line spacing. |
| Secondary text | Approx. 12–13 pt; readable contrast, no long uppercase paragraphs. |
| Numbers | Tabular figures; preserve precision; prices right aligned; never shrink essential values to fit. |
| Spacing | 4 pt base unit; 20 pt page gutters; 12–16 pt within groups; 24–32 pt between sections. |
| Geometry | Square content regions; 0–3 pt control corners; no large rounded native inset groups. |
| Color | Neutral canvas, one restrained blue action color, semantic red and green supported by text or signs. |
| Separators | At most one subtle horizontal separator per data row; no ornamental rule stacks. |
| Navigation | Same four-item bottom bar on every root screen; stable icon and label positions; active state indicated by color and selected accessibility trait. |
| Controls | At least 44 × 44 pt hit areas; consistent selected, pressed, disabled, loading, and error states. |

## Visual directions

Each concept board shows all four root tabs using the same direction. These are alternatives, not styles to mix between tabs.

- **Precision Ledger:** bright, flat white surfaces; quiet date/column bands; clear aligned financial data; balanced density. Recommended starting direction for the user's readability and square-geometry preferences.
- **Quiet Workspace:** more whitespace; time-aligned calendar entries; type-led news hierarchy; full-width contract quote rows. Lower initial information density.
- **Graphite Desk:** dark graphite surfaces; compact continuous rows; explicit data columns; subdued high-contrast text. A denser hierarchy with no neon or decorative terminal elements.

The chosen direction must also receive a matching light/dark pair; selecting a concept does not restrict the app to one appearance.

Generated concept boards, in chat display order:

1. [Precision Ledger](../../design-references/global-redesign-2026-09-05/01-precision-ledger.png)
2. [Quiet Workspace](../../design-references/global-redesign-2026-09-05/02-quiet-workspace.png)
3. [Graphite Desk](../../design-references/global-redesign-2026-09-05/03-graphite-desk.png)

These were generated with the built-in image tool. See concept-review corrections below before treating generated copy or affordances as implementation requirements.

## Screen specifications

### Calendar

Use a continuous agenda with straight-edged date headers. Each event has a clear time/currency/impact line, a full English event name, and consistently aligned Actual, Forecast, and Previous values. Give Actual more weight; do not make every event a floating card. Dates remain chronological in UTC+8. Events remain tappable with an accessible combined label.

At accessibility sizes, stack metadata and numeric values while preserving label/value adjacency. Long titles wrap. Upcoming or unavailable values show an em dash with an understandable accessibility label.

Event details reuse the same title scale, spacing, and number treatment. Present values in a flat strip, descriptive information as labeled text, and history as aligned rows. Related stories and source links use the same link treatment as News. Better/Worse labels accompany semantic colors. Loading, empty history, and retry states follow the global pattern.

### News

Use one continuous reading surface. The root header uses the same title placement as other tabs. The English category rail and impact control have the same selected state and hit areas as Contracts filters.

Rows contain source/time, English headline, a short English teaser, and comment count. Avoid redundant translations, excessive badges, repeated metadata, and separator stacks. Preserve thumbnails when supplied by the source; do not invent images for text-only stories.

Article details use the same sans typography, source/time treatment, and spacing. Use a clear headline, source metadata, separated English article body, contextual source actions, and a distinct Comments section with count and collection status. Each comment has an honest identity marker, author name and date/time, full English body, real reaction count when supplied, and source permalink. Show parent context when the parent exists; keep reply indentation bounded on mobile. No fake portraits, reaction controls, reply composer, or fabricated social data. Quotes use one restrained inset or rule. Preserve excerpt/clamping, media and external-reader behavior. Loading, partial comments, empty comments, and retry states use plain English feedback.

### Contracts

Use a recognizable market table with column labels, aligned prices, and signed percentage changes. The market selector uses the same category-rail component as News. Show exchange, ranking basis, update time, and UTC+8 once in the header.

Each row exposes rank, symbol, last price, and 24h change. Always show turnover, volume, amplitude, high, low, and trade count directly below in an aligned two-row metrics grid. Do not use expansion, disclosure, or another action to reveal these values. At accessibility sizes the grid becomes labeled vertical rows. Preserve contract order and every underlying value.

Negative values include a minus sign; positive values include a plus sign. Long symbols and large prices wrap or switch layout rather than overlap. Crypto, TradFi, and All retain their existing filtering behavior. Loading, empty data, stale data, and connection errors remain distinct.

### Settings

Use a flat form with clear section headings and externally labeled rectangular inputs. Keep Server address and Private API key together under Connection. Save settings is the primary action, Test connection is secondary, and Remove API key is destructive. Keep feedback near those actions.

Show refresh behavior as aligned label/value rows for Calendar & news, Contracts, and background suspension. Keep stored credentials masked and preserve Keychain storage and existing save/test/remove behavior. Do not add account, subscription, trading, or notification features.

## Cross-screen states and accessibility

- Loading: a small progress indicator and short English label; stable page geometry.
- Refreshing: retain visible content, preserve the refresh gesture, and show lightweight progress.
- Empty: a short title, reason, and one relevant action when available.
- Error/stale: concise message near the affected content; distinguish cached data from an empty response.
- Dynamic Type: verify normal, accessibility 1, and accessibility 3 at narrow width.
- Color: verify readable light/dark text contrast; no semantic meaning conveyed by color alone.
- Navigation: visible back navigation on details, consistent bottom-bar behavior, labeled icons and selected states.

## Acceptance and rollout

1. Select one complete visual direction and resolve any requested refinements.
2. Implement shared tokens, header, navigation, controls, surface, and feedback patterns first.
3. Apply them to all four root tabs and both detail flows in the same redesign pass.
4. Verify native screenshots for every tab, details, representative filters/states, both appearances, and accessibility text sizes.
5. Run the existing test suite, review source/data invariants, and deliver the full screen set together.

Concept boards use illustrative market data anchored to September 5, 2026. They are design proposals, not screenshots of an implemented or connected app.

## Concept-review corrections for implementation

- Calendar values use normal ink unless the API supplies a result state. Do not copy a generated mock's indiscriminate green Actual values or infer result semantics from value magnitude.
- The API key is stored in this iPhone's Keychain and is sent to the configured backend for authenticated requests. The second concept's generated phrase “never sent to our servers” is inaccurate and must not be used. Retain accurate copy: “Your API key is stored in this iPhone’s Keychain. Kimi credentials remain on the server.”
- Refresh frequency rows are informational. Do not introduce dropdowns or edit controls suggested by a generated glyph.
- A concept's success status is illustrative; show successful connection only after a successful real test. Do not prepopulate credentials or a connected state.
- Preserve the existing contract filter choices and access to every secondary metric even if a generated board abbreviates them.
- Keep the product name Forex Factory in the app. Concept-direction names are review labels only; the third board's Graphite Desk branding does not authorize renaming the product. Use the same system sans family and consistent navigation icons in the implementation.
