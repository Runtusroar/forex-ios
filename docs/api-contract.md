# Backend API contract

The app communicates with the backend only through HTTPS JSON under `/api/v1`. Every endpoint
below requires the `X-API-Key` request header.

## Endpoints

- `GET /api/v1/calendar?from=<ISO8601>&to=<ISO8601>`
- `GET /api/v1/news?limit=50&before=<optional ISO8601>`
- `GET /api/v1/news/{source_id}`
- `GET /api/v1/binance/futures/top-contracts?limit=20`
- `GET /api/v1/status`

Calendar and news list responses use:

```json
{
  "items": [],
  "generated_at": "2026-09-01T12:00:00Z"
}
```

All timestamps are UTC ISO-8601. English fields such as `title_en`, `summary_en`, and `body_en` are
the source of truth. Corresponding `*_zh` fields are nullable while asynchronous Kimi translation
is pending or unavailable. The app must always show available English content and omit empty
Chinese subtitle views.

The backend owns the contract. A breaking response change requires a new API version or a
coordinated iOS update; adding an optional field is non-breaking.
