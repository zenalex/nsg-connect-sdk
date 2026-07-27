# Server-side integration (S2S)

Your product **backend** talks to nsg-connect over two HTTP calls: issuing
chat session tokens for your users, and sending push notifications to them.
Both are authorized by a single **tenant secret**. No nsg-connect source
access or SDK is required on the backend — the wire contract below plus an
HTTP client is everything (a reference C# implementation ships in
`examples/server-csharp/NsgConnectApi.cs`).

## The tenant secret

Issued by the platform administrator in the Chatista admin UI
(Settings → Platform → your tenant → "Enable & generate secret").

- Shown **exactly once** at generation time; the server stores only a
  SHA-256 hash. Store it like any credential (env / secret manager) —
  never in source control, logs, or client apps.
- Rotation happens in the same admin UI with a **grace window** (default
  5 min): both old and new secrets are accepted during the window, so you
  can roll config without downtime.
- "Disable" is a kill switch: both hashes are wiped, all S2S calls stop
  authorizing immediately.

All failures are deliberately opaque (`400`, no reason): wrong secret,
unknown tenant, rate-limit and validation errors look identical to the
caller (anti-enumeration). The real reason is logged on the nsg-connect
side — ask the platform operator when debugging.

## Wire format

Serverpod RPC over plain HTTP: `POST <apiBaseUrl>/<endpoint>` with a JSON
body `{"method": "<name>", ...named params}`. The method may also go in the
path — `POST <apiBaseUrl>/<endpoint>/<method>` with only the named params in
the body. Both forms are accepted; pick one and stay with it.
Production base URL for the NSG-hosted platform: `https://api.chatista.me`.

**Success** = HTTP 200, JSON object, fields at the top level plus a
`__className__` marker. Do not configure your parser to reject unknown keys:

```json
{"__className__":"ConnectIssuedTokenResult",
 "token":"…","expiresAt":"2026-01-01T00:00:00.000Z"}
```

`DateTime` is always ISO-8601 **in UTC** (trailing `Z`, milliseconds
present) — parse it as a date, not with a fixed format string.

**Failure** = HTTP 400 with a *different* shape: a typed envelope. A parser
written for the success body will break on it, so branch on the status code
first:

```json
{"className":"InvalidTokenException",
 "data":{"__className__":"InvalidTokenException","reason":"issue_denied"}}

{"className":"RateLimitExceededException",
 "data":{"__className__":"RateLimitExceededException",
         "retryAfterSeconds":42,"operation":"connect_token_issue"}}
```

Note the two different keys: the envelope uses `className`, the payload
repeats it as `__className__`. Read the type from the outer `className`.

Retry only `RateLimitExceededException`, honouring `data.retryAfterSeconds`.
`issue_denied` is final: it is deliberately opaque (wrong secret, unknown
tenant/product, disabled mode and inactive user are indistinguishable from
outside — the real reason is in the platform's server log only), so retrying
it just burns your failed-check budget. `ProductNotFoundException` is the one
error that *is* specific: it is raised only after your secret checked out, so
you have already proven you are the product server and can be told your
`productExternalKey` is wrong.

## 1. Issue a chat token (auth bridge)

Your backend endpoint (called by your own authenticated client) exchanges
your product session for a short-lived one-time chat token:

```
POST <apiBaseUrl>/connectToken
{
  "method": "issueToken",
  "tenantExternalKey": "<your tenant>",
  "productExternalKey": "<your product>",
  "serviceSecret": "<tenant secret>",
  "externalUserId": "<stable user id in YOUR system>",
  "displayName": "<user-visible name>",
  "claims": {"your_claim": "value"}        // optional, string→string
}
→ 200 {"token": "…", "expiresAt": "2026-01-01T00:00:00Z"}
```

Your client puts `token` into `MessengerAuthContext.accessToken`
(see `getting_started.md`) and opens the messenger session with it.

- The token is **one-time** and short-lived (5 minutes): issue a fresh one
  per session open / refresh, never cache it.
- Issuance is rate-limited **per tenant**: 60 tokens/min, plus 10 failed
  secret checks per 15 minutes (a successful check refunds the slot).
- The tenant must have issued-token mode enabled (Chatista → Settings →
  Platform, see [CONNECT_PRODUCT_QUICKSTART](../CONNECT_PRODUCT_QUICKSTART.md)).
  Without it — and for a wrong secret, a missing tenant, or a disabled mode —
  the answer is the same opaque `issue_denied`.
- `externalUserId` must be stable per user — it is the user's messenger
  identity within your tenant, and the addressing key for notifications.
- Never forward your product's own long-lived access tokens to the chat:
  that's exactly what this exchange avoids.
- `claims` come back to your backend attached to the session identity
  (useful for role flags like "organizer"); names are your convention.

## 2. Send a push notification

```
POST <apiBaseUrl>/productNotification
{
  "method": "send",
  "tenantExternalKey": "<your tenant>",
  "productExternalKey": "<your product>",
  "serviceSecret": "<tenant secret>",
  "externalUserIds": ["<user id>", …],     // batch is the native shape
  "title": "…",
  "body": "…",
  "idempotencyKey": "match:123:started",   // build from your domain event
  "data": {"deeplink": "yourapp://…"},     // optional, delivered as-is
  "collapseKey": "match:123",              // optional, replaces older unread
  "priority": "high",                      // optional
  "ttlSeconds": 3600                       // optional, drop if undelivered
}
→ 200 {"accepted": N, "deduped": N, "noDevices": N,
       "results": [{"externalUserId": "…", "status": "delivered|deduped|noDevices",
                    "deviceCount": N}, …]}
```

- **Idempotency**: deliveries are deduplicated per
  `(product, idempotencyKey, recipient)` — retrying the same call is safe
  and returns `deduped` instead of double-delivering. Build the key from
  the domain event, not from a timestamp.
- `accepted` means "queued for delivery to N devices", not "shown on
  screen". `noDevices` means the user has never opened the chat from a
  push-capable app — expected for not-yet-onboarded users.
- Notifications arrive with `nsgNotifType: "product"` in the push data, so
  a host app can route them separately from chat/call pushes; your `data`
  map is passed through untouched.
- `collapseKey` / `priority` / `ttlSeconds` are forwarded to the transport:
  on Android as `collapse_key` / `priority` / `ttl`, on iOS as
  `apns-collapse-id` (truncated to 64 bytes) / `apns-priority`. Use
  `collapseKey` for "latest state wins" notifications (score, status) so a
  user coming back online sees one line, not twenty.
- `status` in `results` is `delivered` | `deduped` | `noDevices` today; the
  enum also declares `partial` and `failed`, reserved for per-delivery
  reporting that is not implemented yet — tolerate unknown values.
- Rate limits apply per product (120 sends/min); bursts beyond them get the
  same opaque 400. Batch your fan-outs (one call, many `externalUserIds`)
  instead of looping single sends.

## Operational notes

- Treat both calls as **optional side channels**: a failure to notify must
  not fail your business operation. Log and move on (the reference C#
  client never throws).
- Timeouts: keep them short (the reference uses 10 s) — these calls sit at
  the tail of user-facing requests.
- One secret, two calls: rotating the secret in the admin UI affects both;
  plan config rollout within the grace window.
