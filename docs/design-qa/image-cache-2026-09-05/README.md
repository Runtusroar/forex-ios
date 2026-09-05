# Compact headings, article timestamps and image reuse — 2026-09-05

## Requested interface changes

Page title and date share one row at ordinary text sizes: title on the left, date on the right. News keeps its impact filter beside the title. Accessibility text uses wrapping to avoid squeezing essential labels. Both article and discussion Last updated labels were removed from News detail; publication dates and times remain. Root-feed Last updated and manual refresh behavior remain.

Native fixture screenshots: [News](02-news-light.png), [Calendar](01-calendar-light.png), [Contracts](03-contracts-light.png), [article](05-news-article.png), [comments](19-article-discussion-boundary.png), [large text](17-news-large-text.png). These were captured and inspected in this pass. They are not live market data.

## Image investigation

Before this change, NewsArticleCard and the detail fallback thumbnail used AsyncImage with external thumbnail URLs. Protected article media went through APIClient/URLSession, then UIImage(data:). ResponseCache stored JSON only; there was no explicit image data cache or cross-view download coalescing.

This was not a complete absence of caching. The backend already stores media files and serves them with `private, max-age=31536000, immutable` plus ETag. The checked public thumbnail returned `public, max-age=604800` and a CDN HIT. Apple documents that the shared URLSession uses the shared URLCache: [URLSession.shared](https://developer.apple.com/documentation/foundation/urlsession/shared). HTTP caching behavior alone does not provide the app with explicit reusable image state and coalesced downloads across view reconstruction.

A read-only local production snapshot contained 931 completed media records, averaging 21,714 bytes with a maximum of 87,516 bytes; those snapshot figures are not a fresh production inventory. All 285 populated thumbnail URLs in that snapshot used assets.faireconomy.media. Large transfer size was not supported as the dominant cause in that sample.

Current Mac curl checks of three observed thumbnail URLs returned HTTP 200 in 0.394, 0.508 and 1.090 seconds, for 18,536 / 20,908 / 52,236 bytes. A preliminary Python urllib probe was rejected by HTTP and was not used as a phone latency measurement. Protected live media latency was not measured outside the app because local backend credentials were unavailable; no credentials were printed or fetched from unrelated storage.

## Implementation

- Shared ImageDataCache stores valid image bytes in memory (16 MiB) and disk (128 MiB), with one-day entry lifetime, bounded eviction, corrupt-entry recovery, and retry after failures.
- Simultaneous reads of the same image share one download. Leaving a view does not cancel a download needed by another reader.
- Cache identity hashes the full URL and explicit request headers, including backend credentials; keys and servers do not share protected image entries. Cache files contain image data/expiry, not credential strings.
- APIClient checks its normal media-path and credential rules before using the explicit image cache. Protected downloads bypass the generic HTTP cache so a different API key cannot reuse an old generic HTTP response.
- Public thumbnail and fallback views use the same data cache without adding backend authentication headers. No loading animation was introduced.
- The existing eager article stack and tree discussion stay intact.

This targets repeated loading. First-time images still require a network transfer; the change does not establish that every reported delay was caused by cache misses. Static source images can be retained for up to one day by the explicit cache. System HTTP caching remains available for public thumbnail requests.

## Verification

The initial cache tests failed against the uncached implementation for duplicate fetches, concurrent fetches, disk reuse and invalid-image handling. The final integrated run passed 79 tests: 76 regular tests plus three optional capture tests. Added checks cover memory/disk reuse, concurrent download coalescing, expiry, retry, invalid/corrupt data, disk capacity, request-key separation, and APIClient cache reuse across instances and credential changes.

An additional simulator test downloaded a real 18,536-byte public PNG through URLSession:

| Read | Time | Network fetch permitted? |
| --- | ---: | --- |
| First explicit-cache miss | 476.50 ms | Yes, HTTP 200 |
| Memory hit | 0.43 ms | No; test closure throws if invoked |
| Recreated cache, disk hit | 0.19 ms | No; test closure throws if invoked |

These are single-sample simulator measurements, not an end-to-end iPhone speed guarantee. The article scroll regression kept all six reverse-scroll heights at 11639.33 pt and requested all nine fixture images once.

Logs: `/private/tmp/forex-image-cache-red.log`, `/private/tmp/forex-image-cache-verified.log`, `/private/tmp/forex-image-cache-live.log`, `/private/tmp/forex-image-cache-device.log`. Optional native capture and real-network probe files are archived here outside the regular test target. Installation status is recorded in verification.txt.
