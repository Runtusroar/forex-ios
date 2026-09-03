# Forex Factory News V2 iPhone Client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the personal SwiftUI application to browse every News V2 section, render bilingual normalized details and protected media, paginate reliably, and install the signed result on the paired iPhone 15 Pro.

**Architecture:** Codable V2 transport models mirror the backend boundary, `APIClient` owns authenticated requests, `NewsViewModel` owns per-section cursor state and caching, and focused SwiftUI views render article, comment, segment, and media content. Calendar remains on V1 and all external asset requests remain free of the backend API key.

**Tech Stack:** iOS 17+, Swift 6, SwiftUI, Observation, Foundation URLSession, XCTest, XcodeGen, Xcode 26.5.

**Spec:** `docs/superpowers/specs/2026-09-03-news-v2-client-design.md`

## Global Constraints

- Preserve the existing Calendar behavior and root Calendar/News/Settings tab structure.
- Keep `shop.zhenmei.ForexFactoryMVP` and automatic signing team `7GD7XPGQ4K`.
- English is always primary; nullable Simplified Chinese is displayed directly below when present.
- Never send `X-API-Key` to Forex Factory, publisher, or public asset hosts.
- Keep the implementation dependency-free and compatible with iOS 17.
- Treat backend cursors as opaque strings.
- Preserve visible cached content whenever refresh or pagination fails.
- Use test-first implementation and commit each independently verified task.

---

### Task 1: News V2 Transport Models and Requests

**Files:**
- Modify: `ForexFactoryMVP/Models/APIModels.swift`
- Modify: `ForexFactoryMVP/Networking/APIClient.swift`
- Modify: `ForexFactoryMVPTests/APIModelsTests.swift`
- Modify: `ForexFactoryMVPTests/APIClientTests.swift`

**Interfaces:**
- Produces: `LocalizedText`, `NewsSectionID`, `NewsSection`, `NewsArticleSummary`, `NewsArticleDetail`, `NewsSegment`, `NewsMedia`, `NewsComment`, `CursorEnvelope<Item>`, `NewsSectionsEnvelope`, and `NewsCommentsEnvelope`.
- Produces: `ForexAPI.newsSections()`, `news(section:impact:limit:cursor:)`, `latestComments(limit:cursor:)`, `newsDetail(id:)`, `articleComments(id:limit:cursor:)`, and `mediaData(path:)`.
- Preserves: `calendar(from:to:)` and `status()`.

- [ ] **Step 1: Write failing full-payload decode tests**

Use a literal payload containing a translated high-impact article, thumbnail, two ordered segments, one complete media object, and one nullable translation. Assert literal IDs, ordering, translation values, and media relative path:

```swift
let detail = try JSONDecoder.api.decode(NewsArticleDetail.self, from: Data(json.utf8))
XCTAssertEqual(detail.title.en, "Yen rises")
XCTAssertEqual(detail.title.zhHans, "日元上涨")
XCTAssertEqual(detail.segments.map(\.position), [0, 1])
XCTAssertEqual(detail.segments[1].media[0].url, "/api/v2/news/media/7")
```

- [ ] **Step 2: Run the model tests and verify missing-type failures**

Run: `xcodebuild build-for-testing -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/forex-ios-task1 CODE_SIGNING_ALLOWED=NO`

Expected: FAIL because the V2 types do not exist.

- [ ] **Step 3: Implement the V2 Codable model boundary**

Use explicit coding keys for `zh_hans`, `source_id`, `next_cursor`, `breaking_impact`, `detail_state`, `thumbnail_url`, and other snake-case fields. Keep URLs as `URL`, dates as nullable `Date`, and relative media paths as `String` because they are not absolute URLs.

- [ ] **Step 4: Write failing request-boundary tests**

Assert the exact request path/query and security boundary:

```swift
let request = try builder.news(section: .technical, impact: .high, limit: 25, cursor: "opaque")
let parts = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)
XCTAssertEqual(parts?.path, "/api/v2/news")
XCTAssertEqual(Dictionary(uniqueKeysWithValues: parts?.queryItems?.map { ($0.name, $0.value) } ?? []), [
    "section": "technical", "impact": "high", "limit": "25", "cursor": "opaque"
])
XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "secret")
```

Also assert `publicURLRequest(url:)` has no API-key header and `media(path:)` rejects an absolute external URL.

- [ ] **Step 5: Implement V2 request construction and API methods**

Add typed builders for all endpoints. Resolve protected media only when `path` begins with `/api/v2/news/media/`; build public thumbnail requests without the API key. Reuse the existing status-code mapping and JSON decoder.

- [ ] **Step 6: Run model and request tests**

Run the generic build-for-testing command and then the two test classes on an available simulator.

Expected: PASS with no warnings.

- [ ] **Step 7: Commit the transport layer**

```bash
git add ForexFactoryMVP/Models/APIModels.swift ForexFactoryMVP/Networking/APIClient.swift ForexFactoryMVPTests/APIModelsTests.swift ForexFactoryMVPTests/APIClientTests.swift
git commit -m "feat: add News V2 transport layer"
```

---

### Task 2: Per-Section Cache and Backend URL Migration

**Files:**
- Modify: `ForexFactoryMVP/Storage/ResponseCache.swift`
- Modify: `ForexFactoryMVP/Settings/AppSettings.swift`
- Modify: `ForexFactoryMVP/Settings/SettingsView.swift`
- Modify: `ForexFactoryMVPTests/ResponseCacheTests.swift`
- Modify: `ForexFactoryMVPTests/AppSettingsTests.swift`

**Interfaces:**
- Produces: `CacheKey.news(section:impact:)` with deterministic V2 filenames.
- Produces: initialization migration from only the old default host to `https://api.juezhou.cc`.

- [ ] **Step 1: Write failing cache identity tests**

Save distinct Latest/All and Latest/High envelopes, reload both, and assert neither overwrites the other. Assert a corrupt V2 file returns nil and is quarantined.

- [ ] **Step 2: Run cache tests and verify failure**

Expected: FAIL because `CacheKey` has no section-aware case.

- [ ] **Step 3: Implement deterministic V2 cache keys**

Replace the raw-value enum with a hashable enum whose filenames are exactly `calendar-v1.json` and `news-v2-<section>-<impact-or-all>.json`. Preserve atomic writes and corruption quarantine.

- [ ] **Step 4: Write failing host migration tests**

Cover no saved URL, `https://zhenmei.shop`, `https://zhenmei.shop/`, and a custom URL. The first three resolve to `https://api.juezhou.cc`; the custom URL remains unchanged. Confirm the Keychain double is not modified.

- [ ] **Step 5: Implement the narrow settings migration**

Add `currentDefaultBaseURL` and `legacyDefaultHosts`. Normalize only for comparison, write the new default to UserDefaults when a legacy default is found, and update Settings placeholder text.

- [ ] **Step 6: Run cache/settings tests and commit**

```bash
git add ForexFactoryMVP/Storage/ResponseCache.swift ForexFactoryMVP/Settings ForexFactoryMVPTests/ResponseCacheTests.swift ForexFactoryMVPTests/AppSettingsTests.swift
git commit -m "feat: cache News V2 sections"
```

---

### Task 3: Section State, Refresh, and Cursor Pagination

**Files:**
- Replace: `ForexFactoryMVP/News/NewsViewModel.swift`
- Modify: `ForexFactoryMVPTests/ViewModelTests.swift`

**Interfaces:**
- Produces: `NewsContentKey(section:impact:)`.
- Produces: observable `sections`, `selectedSection`, `impactFilter`, `currentArticles`, `currentComments`, `canLoadMore`, `isRefreshing`, `isLoadingMore`, `staleSince`, and `errorMessage`.
- Produces: `select(_:)`, `setImpactFilter(_:)`, `refresh()`, `loadMore()`, `detail(id:)`, `comments(id:)`, and `mediaData(path:)`.

- [ ] **Step 1: Replace the API stub with the complete V2 protocol**

The actor stub records section, impact, cursor, and media calls and returns complete literal envelopes. It must not omit protocol methods.

- [ ] **Step 2: Write failing refresh and section-isolation tests**

Assert initial refresh loads section metadata and Latest rows, switching to Technical loads Technical without removing Latest, and switching back restores Latest immediately.

- [ ] **Step 3: Implement keyed section state and cache loading**

Store article pages by `NewsContentKey` and Latest Comments separately. Apply a response only to the request's captured key. On activation, load the selected cache before starting the existing refresh loop.

- [ ] **Step 4: Write failing cursor tests**

Return page one `[a, b]` with cursor `next`, then page two `[b, c]` with nil cursor. Assert visible identities become `[a, b, c]`, the requested cursor is exactly `next`, and a repeated load-more is ignored after nil.

- [ ] **Step 5: Implement idempotent load-more and failure preservation**

Append only unseen IDs, update the cursor only on success, guard concurrent refresh/load-more calls, and keep rows/cursors on failure.

- [ ] **Step 6: Write and pass Latest Comments and filter tests**

Assert selecting Latest Comments invokes only `latestComments`, while setting High on Latest invokes `news(section:.latest, impact:.high, ...)` and uses a distinct cache.

- [ ] **Step 7: Run ViewModel tests and commit**

```bash
git add ForexFactoryMVP/News/NewsViewModel.swift ForexFactoryMVPTests/ViewModelTests.swift
git commit -m "feat: manage News V2 section state"
```

---

### Task 4: All-Section News List Interface

**Files:**
- Replace: `ForexFactoryMVP/News/NewsListView.swift`
- Create: `ForexFactoryMVP/News/NewsSectionPicker.swift`
- Create: `ForexFactoryMVP/News/NewsArticleCard.swift`
- Create: `ForexFactoryMVP/News/NewsCommentCard.swift`
- Modify: `ForexFactoryMVP/Components/ImpactBadge.swift`

**Interfaces:**
- Consumes: Task 3 observable state and navigation by article ID.
- Produces: native eight-section browsing, impact menu, article/comment cards, pull refresh, and pagination trigger.

- [ ] **Step 1: Implement the section picker**

Use a horizontal `ScrollView` with buttons styled as selected/unselected capsules. Use backend English names, display counts when positive, and provide selected accessibility traits.

- [ ] **Step 2: Implement reusable article and comment cards**

Use `BilingualText` for titles/comments. Article cards include public `AsyncImage`, impact, source, time, comments, and teaser. Comment cards include author, time, bilingual body, reply/reaction metadata, and a disclosure indicator.

- [ ] **Step 3: Replace the list container**

Render article or comment lists based on `selectedSection`, keep `ContentStatusBanner`, add pull-to-refresh, trigger `loadMore()` from a bottom row task, and expose the impact filter only for supporting sections.

- [ ] **Step 4: Build with warnings as errors and commit**

```bash
git add ForexFactoryMVP/News ForexFactoryMVP/Components/ImpactBadge.swift
git commit -m "feat: browse every News V2 section"
```

---

### Task 5: Ordered Detail, Protected Media, and Comments

**Files:**
- Replace: `ForexFactoryMVP/News/NewsDetailView.swift`
- Create: `ForexFactoryMVP/News/NewsSegmentView.swift`
- Create: `ForexFactoryMVP/News/ProtectedMediaImage.swift`
- Create: `ForexFactoryMVP/News/NewsCommentsView.swift`
- Create: `ForexFactoryMVPTests/ProtectedMediaTests.swift`

**Interfaces:**
- Consumes: `NewsViewModel.detail(id:)`, `comments(id:)`, and `mediaData(path:)`.
- Produces: ordered bilingual detail rendering and an authenticated media loader that never leaks credentials to external URLs.

- [ ] **Step 1: Write failing protected-media tests**

Use `URLProtocol` to capture a protected request. Assert `/api/v2/news/media/7` resolves against the backend and carries `X-API-Key`. Assert an absolute `https://assets.example/image.png` path throws `APIError.invalidConfiguration` before a request is sent.

- [ ] **Step 2: Implement `ProtectedMediaLoader`**

Create a main-actor observable loader with idle/loading/loaded/failed state, cancellation on deinit, byte decoding through `UIImage(data:)`, and no retry loop. The SwiftUI wrapper displays progress, the image, or a neutral failure placeholder.

- [ ] **Step 3: Implement ordered segment and comment views**

Render segments sorted by `(position, id)`, bilingual text, author/time metadata, media ordered by position, and explicit source/attachment links. Render collected comments with a subset disclosure when incomplete.

- [ ] **Step 4: Replace the detail screen**

Load detail and first comment page concurrently. Preserve the list summary while loading, show retry on failure, render metadata/categories/segments/media/comments, and provide Forex Factory and external full-story links.

- [ ] **Step 5: Run all tests, generic build, and commit**

```bash
git add ForexFactoryMVP/News ForexFactoryMVPTests/ProtectedMediaTests.swift
git commit -m "feat: render complete News V2 stories"
```

---

### Task 6: Live API Acceptance, Documentation, and iPhone Installation

**Files:**
- Modify: `README.md`
- Replace: `docs/api-contract.md`

**Interfaces:**
- Produces: reproducible build/install instructions and a verified signed application on the paired device.

- [ ] **Step 1: Update user and API documentation**

Document all V2 endpoints, eight sections, cursor behavior, bilingual nullability, protected media, `https://api.juezhou.cc`, foreground-only refresh, and the free-account APNs limitation.

- [ ] **Step 2: Regenerate and run the full test suite**

```bash
xcodegen generate
xcodebuild test -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/forex-ios-final CODE_SIGNING_ALLOWED=NO
```

Expected: all tests pass and no warning is promoted to an error.

- [ ] **Step 3: Run a clean generic build**

```bash
xcodebuild build-for-testing -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/forex-ios-generic CODE_SIGNING_ALLOWED=NO
```

Expected: `TEST BUILD SUCCEEDED`.

- [ ] **Step 4: Verify the live JSON and media contract**

Use the phone's stored API key or a non-logging local invocation to request sections, Latest, one detail containing media, and that media object. Confirm eight sections, English content, nullable Chinese, ordered segments, and HTTP 200 image bytes.

- [ ] **Step 5: Build and sign for the paired iPhone**

Use device identifier `B3155DEA-0774-5E49-8C4D-3A641C955EDD`, automatic signing, team `7GD7XPGQ4K`, and a dedicated DerivedData path. Do not disable code signing.

- [ ] **Step 6: Install and launch on the device**

Install the generated `.app` using `xcrun devicectl device install app --device B3155DEA-0774-5E49-8C4D-3A641C955EDD <app-path>`, then launch `shop.zhenmei.ForexFactoryMVP`. If iOS requests Developer Mode, trust, or unlock confirmation, report that exact device-side action.

- [ ] **Step 7: Commit and push**

```bash
git add README.md docs/api-contract.md
git commit -m "docs: document News V2 iPhone app"
git push origin codex/news-v2-client
```

