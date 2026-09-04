# Forex Factory Faithful Content Client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render Forex Factory detail text faithfully in native SwiftUI with English-first Chinese subtitles, inline full-story links, and Forex Factory-style social clamping.

**Architecture:** Decode normalized segments, links, media, and presentation metadata from the backend. Build native attributed English text and route every external action through `SFSafariViewController`; remove all publisher-document networking and reader screens.

**Tech Stack:** Swift, SwiftUI, Foundation, SafariServices, XCTest, Xcode project `ForexFactoryMVP`

**Spec:** [`forex-backend` design](https://github.com/Runtusroar/forex-backend/blob/codex/news-v2/docs/superpowers/specs/2026-09-04-forex-factory-faithful-content-design.md)

## Global Constraints

- English Forex Factory text is authoritative and rendered first.
- Chinese is a subtitle and never blocks English display.
- `(full story)` is shown once, inline after English prose, with only `full story` linked.
- `Show More` opens the stored social-source URL instead of revealing publisher content.
- The app must not request `/api/v2/news/source-documents/{id}`.

---

### Task 1: Decode the Simplified Segment Contract

**Files:**
- Modify: `ForexFactoryMVP/Models/APIModels.swift`
- Modify: `ForexFactoryMVPTests/APIModelsTests.swift`

**Interfaces:**
- Consumes: backend `segments[].presentation` and simplified links.
- Produces: `NewsSegmentPresentation`, `NewsSegmentDisplayMode`, and `NewsSegmentLink` without source-document metadata.

- [ ] **Step 1: Replace source-document decoding test**

Decode a segment whose English text ends in `...`, whose link is `full_story`, and whose presentation is:

```json
{"mode":"clamped","max_lines":10,"action_label":"Show More"}
```

Assert exact text, URL, label, mode, line count, and action label.

- [ ] **Step 2: Verify the model test fails**

Run: `xcodebuild test -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/forex-ios-model CODE_SIGNING_ALLOWED=NO -only-testing:ForexFactoryMVPTests/APIModelsTests`

- [ ] **Step 3: Implement models**

Add tolerant decoding for `full`/`clamped` presentation values. Remove `SourceDocumentState`, `SourceDocumentSummary`, `SourceDocument`, and `NewsSegmentLink.sourceDocument`.

- [ ] **Step 4: Verify model tests pass**

Run the Task 1 test command again.

- [ ] **Step 5: Commit model update**

```bash
git add ForexFactoryMVP/Models/APIModels.swift ForexFactoryMVPTests/APIModelsTests.swift
git commit -m "refactor: decode faithful news presentation"
```

### Task 2: Remove Publisher-Document Networking

**Files:**
- Modify: `ForexFactoryMVP/Networking/APIClient.swift`
- Modify: `ForexFactoryMVP/News/NewsViewModel.swift`
- Modify: `ForexFactoryMVPTests/APIClientTests.swift`
- Modify: `ForexFactoryMVPTests/ViewModelTests.swift`

**Interfaces:**
- Consumes: existing news, comment, media, calendar, and status endpoints.
- Produces: `ForexAPI` with no source-document method or request builder.

- [ ] **Step 1: Delete source-document test doubles and replace route test with an API-surface regression assertion**

Keep the existing request tests for news detail, comments, and protected media. Ensure no test fixture or fake API implements `sourceDocument(id:)`.

- [ ] **Step 2: Remove source-document methods**

Remove the protocol requirement/default, request builder, API client method, view-model forwarding method, and associated fake state.

- [ ] **Step 3: Build to catch stale callers**

Run: `xcodebuild build-for-testing -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/forex-ios-network CODE_SIGNING_ALLOWED=NO`

Expected: build succeeds with no `SourceDocument` reference.

- [ ] **Step 4: Commit networking removal**

```bash
git add ForexFactoryMVP/Networking/APIClient.swift ForexFactoryMVP/News/NewsViewModel.swift ForexFactoryMVPTests
git commit -m "refactor: remove publisher document requests"
```

### Task 3: Native Inline Link and Clamp Presentation

**Files:**
- Modify: `ForexFactoryMVP/News/NewsSegmentView.swift`
- Modify: `ForexFactoryMVP/News/NewsDetailView.swift`
- Create: `ForexFactoryMVPTests/NewsSegmentPresentationTests.swift`

**Interfaces:**
- Consumes: `NewsSegment.text`, `.links`, `.sourceURL`, `.media`, and `.presentation`.
- Produces: `NewsSegmentPresentationModel.attributedEnglish`, external action URL/label, and native Safari sheet routing.

- [ ] **Step 1: Write failing presentation helper tests**

Assert a helper reconstructs exact visible English text `Forex Factory excerpt... (full story)`, applies a link attribute only to `full story`, chooses ten lines for a clamped segment, and resolves `Show More` to the social source URL.

- [ ] **Step 2: Verify presentation tests fail**

Run: `xcodebuild test -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/forex-ios-presentation CODE_SIGNING_ALLOWED=NO -only-testing:ForexFactoryMVPTests/NewsSegmentPresentationTests`

- [ ] **Step 3: Implement the native presentation**

Create an attributed English value by appending ` (` + linked label + `)` to preserved prose and assigning the URL only to the label run. Intercept `OpenURLAction` to present the existing `SFSafariViewController` wrapper. Apply the API line limit to both language texts for clamped social content, display `Show More`, and route it to `segment.sourceURL`. Keep media in API position order and use the segment external URL for source-linked media taps.

- [ ] **Step 4: Delete publisher reader UI and source-loading copy**

Remove `SourceArticleView`, its state machine, and strings such as `Collecting publisher article…`. Keep one reusable Safari sheet wrapper. Rename generic detail loading/error copy so it describes Forex Factory detail, not a full publisher story.

- [ ] **Step 5: Verify focused presentation tests and build**

Run the Task 3 test command again.

Run: `xcodebuild build-for-testing -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/forex-ios-ui CODE_SIGNING_ALLOWED=NO`

- [ ] **Step 6: Commit UI behavior**

```bash
git add ForexFactoryMVP/News ForexFactoryMVPTests/NewsSegmentPresentationTests.swift
git commit -m "fix: mirror Forex Factory story actions"
```

### Task 4: Client Documentation and Full Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/api-contract.md`

**Interfaces:**
- Consumes: final client code and backend API contract.
- Produces: documented, simulator-tested iPhone application.

- [ ] **Step 1: Update documentation**

Document that only Forex Factory page content is displayed, source URLs open in in-app Safari, and no publisher article is saved or translated.

- [ ] **Step 2: Search for removed behavior**

Run: `rg -n "SourceDocument|sourceDocument|publisher article|Read full story" ForexFactoryMVP ForexFactoryMVPTests README.md docs/api-contract.md`

Expected: no publisher-reader model, request, or claim remains; user-facing inline label may contain lowercase `full story` only.

- [ ] **Step 3: Run the full test suite**

Run: `xcodebuild test -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/forex-ios-final CODE_SIGNING_ALLOWED=NO`

- [ ] **Step 4: Run a generic build and whitespace check**

Run: `xcodebuild build-for-testing -project ForexFactoryMVP.xcodeproj -scheme ForexFactoryMVP -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/forex-ios-generic CODE_SIGNING_ALLOWED=NO`

Run: `git diff --check`

- [ ] **Step 5: Commit documentation or verification fixes**

```bash
git add -A
git commit -m "docs: describe Forex Factory source boundaries"
```

### Task 5: Device Installation and Acceptance

**Files:**
- No repository files unless a device defect is reproduced in a test first.

**Interfaces:**
- Consumes: deployed schema-v4 backend and paired iPhone 15 Pro.
- Produces: signed and installed application verified against live API data.

- [ ] **Step 1: Discover the connected iPhone and confirm its developer pairing state**

- [ ] **Step 2: Build the exact tested client commit for the physical device with automatic signing**

- [ ] **Step 3: Install and launch the app on the iPhone 15 Pro**

- [ ] **Step 4: Verify normal excerpt ellipsis, inline `(full story)`, Safari opening, multi-source order, bilingual subtitles, image display, comments, and social `Show More` behavior**

- [ ] **Step 5: Push the client branch and record the installed commit in the handoff**
