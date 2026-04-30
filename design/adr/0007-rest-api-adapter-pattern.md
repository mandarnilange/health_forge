# ADR 0007 — REST API Adapter Pattern

## Status

Accepted

## Date

2026-03-17

## Context

health_forge integrates with cloud-based health data providers (Oura, Strava,
Garmin) that expose REST APIs behind OAuth 2.0 authentication. These providers
share common concerns — token management, rate limiting, pagination, and
incremental sync — but differ in endpoint schemas and scopes. We need a
reusable pattern that each REST-based adapter can follow without duplicating
boilerplate.

## Decision

### Dio Interceptor Chain

Each REST adapter uses **Dio** with a composable interceptor stack:

1. **AuthInterceptor** — injects the `Authorization: Bearer <token>` header on
   every request. If a 401 response is received, it attempts a token refresh
   and retries the original request once.
2. **RateLimiter** — enforces provider-specific rate limits (e.g., Oura allows
   5 requests/second) by tracking recent request timestamps and delaying when
   the window is full. Uses an injectable clock for deterministic testing.

This layered design keeps each concern isolated and testable independently of
the HTTP transport.

### OAuth 2.0 PKCE Flow

All REST providers use the **Authorization Code with PKCE** grant:

1. Adapter generates a `code_verifier` (128-char random string from the
   unreserved character set defined in RFC 7636) and derives a
   `code_challenge` via SHA-256 + base64url encoding.
2. Adapter constructs an authorization URL and delegates browser launch to an
   **injectable URL launcher callback** (`Future<void> Function(Uri)`). This
   keeps the adapter free of direct Flutter plugin dependencies, enabling
   unit testing with a stub launcher.
3. A registered deep-link or localhost redirect captures the authorization
   code, which the adapter exchanges for tokens at the provider's token
   endpoint.

### Token Lifecycle

Tokens are represented as an immutable `OuraToken` value object holding:

- `accessToken` — short-lived bearer credential.
- `refreshToken` — long-lived credential for obtaining new access tokens.
- `expiresAt` — absolute expiry timestamp.

The `isExpired` getter allows the auth interceptor to proactively refresh
before making a request, avoiding unnecessary 401 round-trips. Token
persistence is handled by the Flutter-layer secure storage, not the adapter
itself.

### Incremental Sync with Cursors

Oura's API returns a `next_token` in paginated responses. The adapter stores
this cursor between sync sessions so subsequent fetches retrieve only new or
updated data. This maps to `SyncModel.incrementalCursor` in the core
capability model.

## Alternatives Considered

1. **http package instead of Dio** — Dio's built-in interceptor chain,
   automatic retries, and request cancellation make it a better fit for the
   layered architecture. The `http` package would require manual middleware
   wiring.
2. **Provider-specific auth packages** — Using pre-built OAuth packages
   (e.g., `flutter_appauth`) would reduce code but introduces opaque
   dependencies and limits control over token refresh timing and error
   handling.
3. **Shared base class instead of interceptors** — A `RestHealthProvider`
   base class was considered but rejected in favor of composition. Interceptors
   can be mixed, matched, and tested independently without deep inheritance
   hierarchies.

## Consequences

- Each new REST provider only needs to define its endpoints, token URLs, and
  response mappers; the interceptor infrastructure is reused.
- The injectable URL launcher and clock make the entire auth and rate-limiting
  flow unit-testable without network or UI dependencies.
- Adding new interceptors (e.g., logging, retry-on-5xx) is a single-line
  change in the Dio setup.
