# Editorial Newspaper UI Design

## Goal

Restyle the existing iPhone app as a modern financial newspaper while preserving its current navigation, data loading, bilingual content, links, media, settings, and notification behavior. The result should feel deliberately typeset and information-dense rather than like a collection of rounded AI-generated cards.

## Direction

Use a modern editorial treatment inspired by a serious financial newspaper, not a distressed vintage prop.

- Warm paper-colored page surfaces with dark ink text.
- Editorial serif typography for English mastheads and headlines.
- System sans-serif typography for Chinese, metadata, controls, and dense numeric data.
- Thin rules and whitespace establish hierarchy.
- Dark oxblood is the restrained interactive and high-impact accent.
- Rectangular images, controls, rows, and status treatments.
- No capsules, rounded cards, floating shadows, gradients, decorative icons, or artificial paper-noise overlay.

The paper impression comes from color, typography, rhythm, and rules. Avoiding a generated texture keeps text crisp and the interface fast.

## Shared Visual System

Create a small `EditorialTheme` source file containing semantic colors, typography helpers, rule styles, and common spacing. It must support both appearances:

- Light appearance: warm eggshell paper, near-black ink, muted warm gray, subtle taupe rules.
- Dark appearance (the "night edition"): charcoal paper, warm off-white ink, subdued gray rules, and the same restrained oxblood accent.

All screens use the semantic theme instead of one-off card backgrounds. Dynamic Type and system accessibility behavior remain intact.

## Navigation and Mastheads

Keep the existing three-tab information architecture. Give the tab bar a flat paper/ink appearance and remove translucent, floating visual effects where platform APIs permit.

Each primary screen begins with an editorial masthead inside the scrollable content:

- A small uppercase publication line (`FOREX FACTORY · PRIVATE EDITION`).
- A large serif section name.
- A thin double-rule or strong single-rule beneath it.

Navigation bars remain compact for back navigation, but should not duplicate oversized native titles.

## News List

Replace the chip-like section selector with a horizontal newspaper section strip:

- Plain text labels.
- Selected section uses ink weight and an oxblood underline.
- Unselected sections use muted ink.
- Bottom rule separates navigation from the story feed.

Each story becomes a flat article row separated by a full-width hairline:

- Source, time, impact, and comments form a compact metadata line.
- English headline is a prominent serif face.
- Chinese translation sits immediately below in smaller, quieter sans-serif text, like bilingual subtitles.
- Teaser copy is compact and limited to the existing number of lines.
- Images have square corners and a restrained aspect ratio.
- Remove the `Excerpt` icon badge; present it as plain uppercase metadata.

The whole row remains the existing navigation target.

## News Detail

Treat the detail page like a newspaper article:

- Source and publication metadata above a large serif English headline.
- Chinese headline directly underneath.
- A strong rule separates the headline deck from the body.
- English body text has editorial line spacing; Chinese follows each English segment in quieter ink.
- Keep `(full story)` inline and tappable exactly as already implemented.
- `Show More` and `View source` are flat text actions with a bottom rule, not filled buttons.
- Images and attachments are rectangular with captions below.
- Quotes/social posts use a vertical rule or top/bottom rules, with no rounded background.
- Comments are separated as a clearly titled section and use rules instead of cards.

## Economic Calendar

Present the calendar as a financial data sheet:

- Day headings are compact uppercase editorial datelines.
- Each event uses a fixed-feeling row with time and currency leading the hierarchy.
- Impact is shown as a small square marker plus text, never a capsule.
- Actual, Forecast, and Previous values align in a three-column table beneath the event title.
- Thin horizontal and vertical rules reinforce the tabular structure.

## Settings

Use the same masthead and paper background. Replace grouped, rounded form sections with flat editorial sections:

- Uppercase section labels and horizontal rules.
- Rectangular text-entry fields with an underline or one-pixel border.
- Save and Test Connection are flat, full-width rows with clear typographic hierarchy.
- Destructive key removal remains red but unfilled.

No settings behavior changes.

## States and Accessibility

- Loading, empty, stale, and error states use plain editorial copy and simple system symbols only where they materially clarify meaning.
- Status banners use a left rule and subtle tint rather than a rounded alert card.
- Maintain minimum touch targets even when visual controls appear compact.
- Preserve VoiceOver labels and combine article/calendar rows as before.
- Respect Dynamic Type; avoid fixed text heights.
- Preserve readable contrast in both light and dark appearances.

## Implementation Boundaries

This change is limited to the iOS repository. It does not alter API models, backend endpoints, caching, refresh timing, notification behavior, Safari link handling, or navigation destinations.

Expected implementation files:

- New shared editorial theme/components under `ForexFactoryMVP/Components`.
- Existing root navigation, News, Calendar, Settings, bilingual text, impact, status, comment, media, and segment views.
- Project generation metadata only if required to include the new Swift file.

## Verification

- Existing model and API tests remain green.
- Add focused tests only for new pure presentation logic where applicable.
- Build the app for an iOS simulator and the connected iPhone.
- Render and inspect the News list, News detail, Calendar, and Settings screens at iPhone 15 Pro dimensions.
- Confirm there are no rounded cards/chips/images, clipped bilingual text, broken links, unreadable dark-mode colors, or regressions in navigation and refresh controls.
- Install the verified build on the paired iPhone 15 Pro.
