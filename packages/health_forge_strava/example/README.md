# health_forge_strava example

Wires up `StravaAuthManager`, `StravaApiClient`, and `StravaHealthProvider`
to show the typical construction order. It does not run a real OAuth flow —
that requires:

1. A registered app at https://www.strava.com/settings/api with a client ID
   and client secret.
2. A `urlLauncher` callback that opens the auth URL and returns the
   redirect-callback URL (typically via a deep link your Flutter app
   handles).
3. **A token-exchange strategy.** Strava requires a `client_secret` even
   with PKCE. For production, supply a `StravaTokenExchange` that performs
   the exchange on your backend so the secret never ships in the app
   binary. The example uses a direct `clientSecret` call — fine for local
   development, not for release builds.

For a complete runnable demo with real authorization, backend exchange,
and data queries, see the
[Flutter example app](https://github.com/mandarnilange/health_forge/tree/main/example)
in the workspace root.

The
[Getting Started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md)
covers the production-grade setup with a backend exchange.
