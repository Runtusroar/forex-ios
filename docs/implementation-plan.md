# Forex Factory Lightweight iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native personal iPhone app that shows the backend economic calendar and news in English-first, Chinese-subtitle form with reliable foreground refresh and offline last-good data.

**Architecture:** A small SwiftUI app has Calendar, News, and Settings tabs. A typed URLSession client feeds focused observable view models; a shared refresh coordinator runs only while the scene is active; JSON files retain the last successful list response.

**Tech Stack:** iOS 17, Swift 6, SwiftUI, URLSession, Codable, Security/Keychain, XCTest, XcodeGen

**Spec:** `docs/superpowers/specs/2026-09-01-forex-factory-lightweight-mvp-design.md`

## Global Constraints

- Native SwiftUI only, with no third-party runtime dependencies.
- No APNs, notification entitlement, background fetch, pairing, account system, analytics, Markdown/HTML renderer, or App Store work.
- English is always primary; Chinese appears directly below only when non-empty.
- Refresh immediately on foreground entry, then every 30 seconds while active; cancel in background and never overlap requests.
- Store the base URL in UserDefaults, the API key in Keychain, and no Kimi credential on the device.
- Support iOS 17+, Swift 6 strict concurrency, and iPhone only.
- Every implementation task follows red-green-refactor and ends with focused tests.

---

### Task 1: Replace the legacy app with the minimal project and domain models

**Files:**
- Replace: `ios/project.yml`
- Create: `ios/Config/Debug.xcconfig`
- Create: `ios/Config/Release.xcconfig`
- Create: `ios/ForexFactoryMVP/App/ForexFactoryMVPApp.swift`
- Create: `ios/ForexFactoryMVP/App/RootTabView.swift`
- Create: `ios/ForexFactoryMVP/Models/APIModels.swift`
- Create: `ios/ForexFactoryMVP/Resources/Info.plist`
- Create: `ios/ForexFactoryMVPTests/APIModelsTests.swift`

**Interfaces:**
- Produces: `CalendarEvent`, `NewsItem`, `NewsDetail`, `ListEnvelope<Item>`, `ServiceStatus`, and `Impact`.
- Produces: a three-tab app shell with Calendar, News, and Settings placeholders.

- [ ] **Step 1: Remove the legacy iOS source tree and generated project, preserving no APNs entitlement or pairing code**

The replacement target is `ForexFactoryMVP`; deployment target is iOS 17; strict Swift concurrency and warnings-as-errors remain enabled.

- [ ] **Step 2: Write failing bilingual and nullable-decoding tests**

```swift
func testCalendarEventDecodesWithoutChineseTranslation() throws {
    let event = try JSONDecoder.api.decode(CalendarEvent.self, from: fixture("calendar_untranslated"))
    XCTAssertEqual(event.titleEN, "ISM Manufacturing PMI")
    XCTAssertNil(event.titleZH)
    XCTAssertEqual(event.impact, .high)
}

func testNewsDetailDecodesBilingualBody() throws {
    let item = try JSONDecoder.api.decode(NewsDetail.self, from: fixture("news_detail"))
    XCTAssertEqual(item.bodyEN, "The dollar advanced...")
    XCTAssertEqual(item.bodyZH, "美元上涨……")
}
```

- [ ] **Step 3: Run the focused test and verify missing model types fail**

Run `xcodegen generate` followed by `xcodebuild test -scheme ForexFactoryMVP -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:ForexFactoryMVPTests/APIModelsTests`.

- [ ] **Step 4: Implement the project, app shell, API date decoder, and Codable models**

Map snake-case JSON explicitly, parse UTC ISO-8601 with and without fractional seconds, and keep every Chinese property optional. Do not add UI networking yet.

- [ ] **Step 5: Generate the Xcode project, rerun model tests, and run `git diff --check`**

- [ ] **Step 6: Commit `chore: reset iOS app to lightweight MVP`**

---

### Task 2: Add settings persistence and the authenticated API client

**Files:**
- Create: `ios/ForexFactoryMVP/Settings/AppSettings.swift`
- Create: `ios/ForexFactoryMVP/Settings/APIKeyStore.swift`
- Create: `ios/ForexFactoryMVP/Networking/APIClient.swift`
- Create: `ios/ForexFactoryMVP/Networking/APIError.swift`
- Test: `ios/ForexFactoryMVPTests/AppSettingsTests.swift`
- Test: `ios/ForexFactoryMVPTests/APIKeyStoreTests.swift`
- Test: `ios/ForexFactoryMVPTests/APIClientTests.swift`
- Test: `ios/ForexFactoryMVPTests/Support/URLProtocolStub.swift`

**Interfaces:**
- Produces: `AppSettings.baseURL: URL?` backed by UserDefaults.
- Produces: `APIKeyStoring` with `read()`, `save(_:)`, and `delete()`; production implementation uses Security.framework.
- Produces: `APIClient.calendar(from:to:)`, `news(limit:before:)`, `newsDetail(id:)`, and `status()`.

- [ ] **Step 1: Write failing URL/header and error-mapping tests**

```swift
func testCalendarRequestUsesV1PathQueryAndAPIKey() async throws {
    URLProtocolStub.handler = { request in
        XCTAssertEqual(request.url?.path, "/api/v1/calendar")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "secret")
        XCTAssertNotNil(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems)
        return (.ok, fixture("calendar_list"))
    }
    _ = try await client.calendar(from: start, to: end)
}

func testUnauthorizedMapsToReadableError() async {
    URLProtocolStub.statusCode = 401
    await XCTAssertThrowsErrorAsync(try await client.news(limit: 50, before: nil)) {
        XCTAssertEqual($0 as? APIError, .unauthorized)
    }
}
```

- [ ] **Step 2: Run the focused tests and verify failure**

- [ ] **Step 3: Implement settings and generic Keychain storage**

Reject non-HTTPS production URLs while allowing `http://127.0.0.1` for development. Use a fixed Keychain service/account, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, and replace existing values atomically.

- [ ] **Step 4: Implement URLSession requests and decoding**

Use `URLComponents`, a 15-second request timeout, `Accept: application/json`, and `X-API-Key`. Map 401, 404, 429, 5xx, connectivity, invalid configuration, and decoding failures to short English errors without logging the key or response bodies.

- [ ] **Step 5: Run settings/client tests and the app build**

- [ ] **Step 6: Commit `feat: add settings and authenticated API client`**

---

### Task 3: Add atomic last-good JSON caching and foreground refresh control

**Files:**
- Create: `ios/ForexFactoryMVP/Storage/ResponseCache.swift`
- Create: `ios/ForexFactoryMVP/Refresh/RefreshLoop.swift`
- Test: `ios/ForexFactoryMVPTests/ResponseCacheTests.swift`
- Test: `ios/ForexFactoryMVPTests/RefreshLoopTests.swift`

**Interfaces:**
- Produces: `ResponseCaching.load(_:as:)`, `save(_:as:)`, and `remove(_:)`.
- Produces: `RefreshLoop.start(operation:)`, `stop()`, and `refreshNow()` isolated to `@MainActor`.

- [ ] **Step 1: Write failing cache round-trip and corrupt-cache tests**

```swift
func testCacheRoundTripsAtomically() throws {
    try cache.save(envelope, as: .calendar)
    XCTAssertEqual(try cache.load(.calendar, as: CalendarEnvelope.self), envelope)
}

func testCorruptCacheReturnsNilAndDoesNotCrash() throws {
    try Data("{".utf8).write(to: cache.url(for: .news))
    XCTAssertNil(try cache.load(.news, as: NewsEnvelope.self))
}
```

- [ ] **Step 2: Write failing refresh timing and overlap tests using an injected clock**

```swift
@MainActor
func testStartRefreshesImmediatelyThenEveryThirtySeconds() async {
    let counter = Counter()
    loop.start { await counter.increment() }
    await clock.advance(by: .seconds(30))
    XCTAssertEqual(await counter.value, 2)
}

@MainActor
func testSlowRequestDoesNotOverlap() async {
    loop.start { await gate.runBlockedOperation() }
    await clock.advance(by: .seconds(60))
    XCTAssertEqual(await gate.maximumConcurrency, 1)
}
```

- [ ] **Step 3: Implement Application Support cache with atomic writes**

Use one versioned file per endpoint and return `nil` for missing/corrupt data after quarantining the corrupt file name. Cache writes occur only after successful decoding.

- [ ] **Step 4: Implement cancellable refresh loop**

The injected sleeper defaults to `ContinuousClock`. `start` cancels the prior task, invokes once immediately, sleeps 30 seconds after completion, and repeats. `stop` cancels and clears state. `refreshNow` joins an in-flight operation instead of starting another.

- [ ] **Step 5: Run cache/refresh tests and app build**

- [ ] **Step 6: Commit `feat: add offline cache and foreground refresh`**

---

### Task 4: Build the bilingual economic calendar

**Files:**
- Create: `ios/ForexFactoryMVP/Calendar/CalendarViewModel.swift`
- Create: `ios/ForexFactoryMVP/Calendar/CalendarView.swift`
- Create: `ios/ForexFactoryMVP/Components/BilingualText.swift`
- Create: `ios/ForexFactoryMVP/Components/ImpactBadge.swift`
- Create: `ios/ForexFactoryMVP/Components/LoadStateView.swift`
- Test: `ios/ForexFactoryMVPTests/CalendarViewModelTests.swift`

**Interfaces:**
- Produces: `CalendarViewModel.events`, `isRefreshing`, `staleSince`, `errorMessage`, `activate()`, `deactivate()`, and `refresh()`.
- Consumes: Task 2 API client and Task 3 cache/refresh loop.

- [ ] **Step 1: Write failing view-model tests for cache-first and failure-preserves-data behavior**

```swift
@MainActor
func testActivateLoadsCacheBeforeNetworkCompletes() async {
    let model = CalendarViewModel(api: suspendedAPI, cache: seededCache, refreshLoop: loop)
    model.activate()
    await Task.yield()
    XCTAssertEqual(model.events.first?.titleEN, "Cached event")
    XCTAssertNotNil(model.staleSince)
}

@MainActor
func testRefreshFailureKeepsExistingRows() async {
    model.events = [fixtureEvent]
    api.nextError = .offline
    await model.refresh()
    XCTAssertEqual(model.events, [fixtureEvent])
    XCTAssertEqual(model.errorMessage, "Unable to refresh. Showing saved data.")
}
```

- [ ] **Step 2: Implement the view model and run its tests**

Query from local start-of-day through seven days ahead, group rows by local calendar date, replace data only after a successful response, and save successful envelopes to cache.

- [ ] **Step 3: Implement the Calendar SwiftUI hierarchy**

Use a `List` with date sections. Each row shows local time, currency, impact badge, `BilingualText`, and an aligned three-column Actual/Forecast/Previous strip. Pull-to-refresh calls `refresh()`. A compact stale/error banner does not cover existing rows.

- [ ] **Step 4: Add accessibility labels and Dynamic Type checks**

The combined row label reads time, currency, impact, English title, Chinese title when available, and the three values. Do not communicate impact by color alone.

- [ ] **Step 5: Run the focused tests and build for the simulator**

- [ ] **Step 6: Commit `feat: add bilingual economic calendar`**

---

### Task 5: Build bilingual news listing and detail

**Files:**
- Create: `ios/ForexFactoryMVP/News/NewsViewModel.swift`
- Create: `ios/ForexFactoryMVP/News/NewsListView.swift`
- Create: `ios/ForexFactoryMVP/News/NewsDetailView.swift`
- Test: `ios/ForexFactoryMVPTests/NewsViewModelTests.swift`

**Interfaces:**
- Produces: `NewsViewModel.items`, `isRefreshing`, `staleSince`, `errorMessage`, `activate()`, `deactivate()`, and `refresh()`.
- Produces: detail loading by source ID through `APIClient.newsDetail(id:)`.

- [ ] **Step 1: Write failing list refresh and untranslated-detail tests**

```swift
@MainActor
func testSuccessfulRefreshSortsNewestFirstAndCaches() async {
    await model.refresh()
    XCTAssertEqual(model.items.map(\.sourceID), ["new", "old"])
    XCTAssertEqual(cache.savedNews?.items.count, 2)
}

func testDetailAllowsNilChineseBody() throws {
    let detail = try JSONDecoder.api.decode(NewsDetail.self, from: fixture("news_untranslated"))
    XCTAssertNil(detail.bodyZH)
    XCTAssertFalse(detail.bodyEN.isEmpty)
}
```

- [ ] **Step 2: Implement and test the news view model**

Load cache immediately, fetch the latest 50 items, sort by published time then first-seen time, keep old content on failure, and use the shared 30-second active-only refresh behavior.

- [ ] **Step 3: Implement listing cards**

Show source/time metadata, English title, optional Chinese subtitle, English/Chinese summaries, and an asynchronously loaded image with a neutral placeholder. Navigation uses stable source IDs.

- [ ] **Step 4: Implement plain-text detail rendering**

Show English title/body first and optional Chinese title/body below with secondary styling. Do not interpret remote HTML or Markdown. Show a retry control when detail loading fails.

- [ ] **Step 5: Run news tests and simulator build**

- [ ] **Step 6: Commit `feat: add bilingual news views`**

---

### Task 6: Build Settings and wire scene-phase lifecycle

**Files:**
- Create: `ios/ForexFactoryMVP/Settings/SettingsViewModel.swift`
- Create: `ios/ForexFactoryMVP/Settings/SettingsView.swift`
- Modify: `ios/ForexFactoryMVP/App/RootTabView.swift`
- Modify: `ios/ForexFactoryMVP/App/ForexFactoryMVPApp.swift`
- Test: `ios/ForexFactoryMVPTests/SettingsViewModelTests.swift`
- Test: `ios/ForexFactoryMVPTests/LifecycleTests.swift`

**Interfaces:**
- Produces: editable base URL/API-key fields, `save()`, and `testConnection()`.
- Wires `ScenePhase.active` to visible-view activation and inactive/background to deactivation.

- [ ] **Step 1: Write failing validation and secret-display tests**

```swift
@MainActor
func testSaveRejectsInvalidBaseURLWithoutReplacingStoredValue() async {
    model.baseURLText = "not a url"
    await model.save()
    XCTAssertEqual(model.message, "Enter a valid HTTPS URL.")
    XCTAssertEqual(settings.baseURL, originalURL)
}

@MainActor
func testExistingKeyIsNeverLoadedIntoVisibleText() {
    XCTAssertEqual(model.apiKeyText, "")
    XCTAssertTrue(model.hasStoredAPIKey)
}
```

- [ ] **Step 2: Implement settings save and connection test**

Blank key input means retain the existing key; an explicit Remove Key button deletes it after confirmation. `testConnection()` calls `/api/v1/status` and displays a short English success/failure message.

- [ ] **Step 3: Wire real dependencies and scene phase**

Create one settings/key-store/client/cache dependency graph at app startup. Calendar and News activate only when their tab is visible and the scene is active; both stop when backgrounded. Configuration changes rebuild the API client without restarting the app.

- [ ] **Step 4: Run settings/lifecycle tests and build**

- [ ] **Step 5: Commit `feat: add API settings and app lifecycle`**

---

### Task 7: Verify on simulator and free-account iPhone

**Files:**
- Create: `ios/README.md`
- Create: `ios/ForexFactoryMVPUITests/ForexFactoryMVPUITests.swift`
- Modify: `ios/project.yml`

**Interfaces:**
- Produces documented XcodeGen, simulator, signing, device-run, and API-configuration steps.

- [ ] **Step 1: Add deterministic launch fixtures for one calendar and two news states**

The UI-test-only environment flag swaps the API client for local bundled JSON. It contains one translated and one untranslated record and is excluded from Release behavior.

- [ ] **Step 2: Add UI tests for English-first/Chinese-subtitle order and tab navigation**

```swift
func testCalendarShowsEnglishBeforeChinese() {
    app.launchEnvironment["UITEST_FIXTURE"] = "bilingual"
    app.launch()
    let english = app.staticTexts["ISM Manufacturing PMI"]
    let chinese = app.staticTexts["ISM 制造业采购经理指数"]
    XCTAssertTrue(english.waitForExistence(timeout: 3))
    XCTAssertTrue(chinese.exists)
    XCTAssertLessThan(english.frame.minY, chinese.frame.minY)
}
```

- [ ] **Step 3: Document exact local and device workflow**

Include `xcodegen generate`, simulator test command, opening the project, choosing the user's free Apple team, trusting the device, entering the public HTTPS API base URL and app API key, and the limitation that free-account builds expire and the MVP has no APNs.

- [ ] **Step 4: Run final automated verification**

Run XcodeGen, all unit tests, the fixture UI tests, a Debug simulator build, and `git diff --check`. Resolve every warning because warnings are errors.

- [ ] **Step 5: Run on the paired iPhone and verify live calendar/news refresh**

Confirm English-first/Chinese-subtitle rendering, pull-to-refresh, a second automatic request after approximately 30 seconds, cached display after temporarily disabling network, and absence of notification permission prompts.

- [ ] **Step 6: Commit `docs: add iPhone MVP run guide`**
