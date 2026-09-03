# Source Article Reader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render Forex Factory details without teaser duplication and open full-story links in a native bilingual reader with an in-app-browser fallback.

**Architecture:** V2 models preserve segment links and source-document state. The detail view presents Forex Factory content exactly once; a dedicated source reader fetches native content only when available, while `SFSafariViewController` handles pending, blocked, and failed documents.

**Tech Stack:** iOS 17, Swift 6, SwiftUI, URLSession, SafariServices, XCTest, XcodeGen

**Spec:** `../../../../forex-backend/.worktrees/news-v2/docs/superpowers/specs/2026-09-03-full-story-acquisition-design.md`

## Global Constraints

- English remains primary and optional Simplified Chinese appears directly below.
- Never show list teaser and matching detail prose together.
- Never render `full story` as ordinary text.
- Never send the API key to a publisher URL.
- Preserve the existing bundle ID, signing team, Keychain key, and backend hostname.

---

### Task 1: Source Models and Requests

**Files:**
- Modify: `ForexFactoryMVP/Models/APIModels.swift`
- Modify: `ForexFactoryMVP/Networking/APIClient.swift`
- Modify: `ForexFactoryMVPTests/APIModelsTests.swift`
- Modify: `ForexFactoryMVPTests/APIClientTests.swift`

**Interfaces:**
- Produces: `NewsSegmentLink`, `SourceDocumentSummary`, `SourceDocument`, and `sourceDocument(id:)`.

- [x] Add decoding tests for complete and blocked source documents and segment links.
- [x] Add request tests proving only backend source-document requests receive `X-API-Key`.
- [x] Run focused tests and confirm failure before implementation.
- [x] Implement models and authenticated backend request.
- [x] Run focused tests and commit `feat: add source-document transport`.

### Task 2: Correct Detail and Reader UI

**Files:**
- Modify: `ForexFactoryMVP/News/NewsDetailView.swift`
- Modify: `ForexFactoryMVP/News/NewsSegmentView.swift`
- Modify: `ForexFactoryMVP/News/NewsViewModel.swift`
- Create: `ForexFactoryMVP/News/SourceArticleView.swift`
- Create: `ForexFactoryMVP/News/InAppBrowserView.swift`
- Modify: `ForexFactoryMVPTests/ViewModelTests.swift`

**Interfaces:**
- Consumes: `sourceDocument(id:)` and segment link summaries.
- Produces: a non-duplicated Forex Factory detail and full-story navigation.

- [x] Add a failing view-model test for complete and blocked source-document loading.
- [x] Stop rendering teaser after detail segments load; retain it only as loading context.
- [x] Render one `Read full story` action per structured full-story link.
- [x] Show native English-first/Chinese-below paragraphs for complete documents.
- [x] Open publisher URL with `SFSafariViewController` for unavailable native content.
- [x] Run focused and full tests, regenerate the project, and commit `feat: read complete source stories`.

### Task 3: Final Verification and iPhone Installation

**Files:**
- Modify: `README.md`
- Modify: `docs/api-contract.md`

**Interfaces:**
- Produces: verified simulator and signed iPhone builds.

- [x] Update documentation for provenance and fallback behavior.
- [ ] Run the full simulator suite and generic build with zero failures/warnings.
- [ ] Validate live detail and source-document decoding against `https://api.juezhou.cc` without logging the key.
- [ ] Build/sign, install, and launch on device `B3155DEA-0774-5E49-8C4D-3A641C955EDD`.
- [ ] Push `codex/news-v2-client` and confirm local/remote synchronization.
