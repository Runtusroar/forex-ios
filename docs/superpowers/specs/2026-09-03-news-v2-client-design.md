# Forex Factory News V2 iPhone Client Design

Date: 2026-09-03

Status: Approved in chat

## 1. Purpose

Upgrade the existing personal SwiftUI application from the flattened News V1 API to the normalized News V2 API. The application will expose every Forex Factory News section, preserve English as the primary language with Simplified Chinese directly below it, render ordered story segments and cached media, and retain the existing Calendar and Settings experiences.

## 2. Scope

### In scope

- iOS 17+, Swift 6, SwiftUI, and the existing application target and bundle identifier.
- Latest, Hot, Fundamental, Technical, Industry, Entertainment, Educational, and Latest Comments sections.
- News cards containing source, time, breaking impact, comment count, thumbnail, English title/teaser, and nullable Chinese translations.
- Optional high, medium, and low impact filtering for article sections.
- Stable cursor pagination and pull-to-refresh.
- Approximately 30-second foreground refresh for the selected section.
- Per-section last-successful response caches.
- Ordered detail segments, source links, excerpt labels, authenticated cached images, and collected comments.
- Existing API URL and API-key settings, including migration of the old default host to `https://api.juezhou.cc`.
- Unit tests, simulator build verification, and installation on the paired iPhone 15 Pro.

### Out of scope

- App Store distribution, user accounts, writes to Forex Factory, and posting comments.
- APNs remote notifications. A free Personal Team cannot provide the durable production push setup required by this application; push remains a separate paid-account phase.
- Markdown interpretation of source text. Forex Factory text is rendered as native plain text so source content cannot inject formatting.
- Crawling external publisher pages from the phone.

## 3. Chosen Product Structure

The News tab remains one native navigation stack. A horizontally scrollable section selector appears under the navigation bar in the backend-defined stable order. Seven article sections use the same card and pagination behavior. Latest Comments uses a specialized comment card and opens the related article by `article_id`.

This is preferred over one long dashboard because each section can be refreshed, cached, and paginated independently without creating a visually dense page. It is preferred over adding a separate tab for every section because the root tab bar remains limited to Calendar, News, and Settings.

## 4. Data Model

The V2 transport layer mirrors the backend contract rather than flattening data:

- `LocalizedText`: `en` plus nullable `zh_hans`.
- `NewsSectionID`: the eight stable section identifiers.
- `NewsSection`: localized display name, item count, and impact-filter capability.
- `NewsArticleSummary`: canonical metadata returned by section lists.
- `NewsArticleDetail`: summary metadata plus feeds, ordered segments, collected-comment count, and completeness state.
- `NewsSegment`: ordered article/social/update/quote/link content with nullable translation and child media.
- `NewsMedia`: cached relative URL, original URL, type, state, MIME type, caption, and byte size.
- `NewsComment`: identity, related article ID, reply parent, author, timestamp, bilingual text, permalink, and reactions.
- Generic cursor envelopes retain `next_cursor` and `generated_at`.

Unknown optional enum values decode to a safe fallback where future backend values should not make the whole response unreadable. Stable section IDs remain explicit because they control routing and cache identity.

## 5. Networking and Security

`ForexAPI` gains separate methods for sections, article lists, latest comments, article details, article comments, and protected media. Calendar and status remain on V1 until a later coordinated migration.

Every backend JSON and cached-media request carries `X-API-Key`. External thumbnail and publisher URLs never receive the API key. Listing thumbnails use ordinary `AsyncImage` because they point to public asset hosts. Cached detail media uses a dedicated loader that resolves only backend-relative paths and asks `APIClient` for authenticated bytes.

The client rejects non-HTTPS remote base URLs, preserves the key in Keychain, and never writes the key into logs, caches, URLs, or image metadata.

## 6. State, Refresh, and Pagination

`NewsViewModel` owns:

- backend section metadata;
- selected section and optional impact filter;
- article rows keyed by section/filter;
- latest-comment rows;
- next cursors and in-flight flags;
- stale timestamps and user-readable errors.

Selecting a section immediately shows its cached first page when available, then refreshes from the network. A refresh replaces only that section's first page after a successful response. Pagination appends unique identities and advances the opaque cursor. Failed refreshes preserve visible rows and mark them stale. Failed load-more calls preserve the existing cursor so the user can retry.

Only the selected section refreshes every approximately 30 seconds while the app is active. Switching sections cancels no shared network mutation because each request result is applied only to the key that initiated it.

## 7. Views

### News list

- Horizontal section chips show English names and optional item counts.
- A toolbar menu selects All, High, Medium, or Low impact where supported.
- Article cards show a thumbnail when available, impact badge, source, relative publication time, comment count, English title and teaser, then Chinese translations when present.
- Latest Comments cards show author, relative time, English comment and Chinese subtitle, reply/reaction metadata, and navigate to the related article.
- A bottom progress/retry row triggers cursor pagination near the list end.

### News detail

- The header shows source, time, impact, category badges, comment count, bilingual title, teaser, and excerpt/source links.
- Segments render in backend order with a visual distinction for social and quoted content.
- Each segment displays English first and nullable Chinese below.
- Cached images and charts load with authenticated requests; attachments and original-source URLs open through explicit links.
- Collected comments appear after the story. The UI states that comments are a collected subset whenever `comments_complete` is false.
- A partial or pending detail remains readable from list metadata and offers retry.

## 8. Cache and Migration

The old `news-v1.json` cache is not decoded as V2. New cache keys include the section ID and impact filter and use a V2 filename. Corrupt caches are quarantined using the existing behavior.

If the stored backend URL equals the previous application default `https://zhenmei.shop` (with or without a trailing slash), initialization migrates it to `https://api.juezhou.cc`. Any other user-entered URL remains unchanged. The existing Keychain API key remains untouched.

## 9. Error Handling

- Missing Chinese text hides only the Chinese subtitle.
- Invalid or unknown dates fall back to the source time label when available.
- A failed thumbnail or protected-media load shows a neutral placeholder and does not fail the article.
- Unauthorized, missing, rate-limited, server, and malformed responses use the existing typed API errors.
- Empty sections distinguish a valid empty response from a configuration/network failure.
- Pagination and refresh cannot run twice for the same selected content key.

## 10. Testing and Acceptance

Unit tests cover complete V2 decoding, nullable translations, section and cursor request construction, API-key boundaries, per-section cache filenames, URL migration, refresh replacement, pagination deduplication, selection races, and authenticated media requests.

Acceptance requires:

1. XcodeGen regenerates the project successfully.
2. Unit tests pass on an available iOS simulator.
3. A clean generic iOS build succeeds with warnings treated as errors.
4. The app connects to `https://api.juezhou.cc` using the existing Keychain key.
5. All eight sections render and a real detail page shows ordered content and at least one backend-cached image when the selected article contains media.
6. The signed build installs and launches on the paired iPhone 15 Pro.

