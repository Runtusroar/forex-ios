# Backend API contract

The app communicates with `https://api.juezhou.cc` over HTTPS. Every endpoint below requires an
`X-API-Key` header. Keys never appear in URLs, logs, JSON caches, or external asset requests.

## Calendar

- `GET /api/v1/calendar?from=<ISO8601>&to=<ISO8601>`
- `GET /api/v1/status`

## News V2

- `GET /api/v2/news/sections`
- `GET /api/v2/news?section=<id>&impact=<optional>&limit=50&cursor=<optional>`
- `GET /api/v2/news/{source_id}`
- `GET /api/v2/news/comments/latest?limit=50&cursor=<optional>`
- `GET /api/v2/news/{source_id}/comments?limit=50&cursor=<optional>`
- `GET /api/v2/news/media/{media_id}`

The eight section IDs are `latest`, `hot`, `fundamental`, `technical`, `industry`,
`entertainment`, `educational`, and `latest-comments`. Cursor strings are opaque: the client returns
the server's `next_cursor` unchanged and stops when it is null.

Article summaries contain feed metadata and optional thumbnails. Article details add ordered feed
placements and ordered content segments. Segments may represent articles, social posts, updates,
quotes, or links, and may contain cached images/charts. A segment's ordered `links` array preserves
the semantic `full_story` anchor as a label and external URL. Its `presentation` object identifies
normal content or Forex Factory-clamped content with an optional line count and action label. The
client retrieves only backend-relative
`/api/v2/news/media/...` paths with authentication; public thumbnails are fetched without the API
key.

Forex Factory segment text is never merged with publisher text. The app reconstructs the inline
`(full story)` action after the exact Forex Factory English excerpt and opens the stored URL with
`SFSafariViewController`. Long social content uses the server-provided clamp and `Show More`
action. Publisher requests do not use `APIClient` and therefore cannot inherit `X-API-Key`.

Localized fields have this shape:

```json
{
  "en": "English source text",
  "zh_hans": "可为空的中文翻译"
}
```

English is the source of truth. `zh_hans` is nullable while asynchronous Kimi translation is
pending or has failed, and translation failure never blocks collection or storage. The iPhone
always renders available English and omits an empty Chinese subtitle rather than treating it as an
article failure.

All timestamps are UTC ISO-8601. A breaking response change requires a new API version or a
coordinated iOS update; adding an optional field is non-breaking.
