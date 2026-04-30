# health_forge_oura example

Wires up `OuraAuthManager`, `OuraApiClient`, and `OuraHealthProvider` to show
the typical construction order. It does not run a real OAuth flow — that
requires:

1. A registered app at https://cloud.ouraring.com/oauth/applications with a
   client ID and a configured redirect URI.
2. A `urlLauncher` callback that opens the auth URL in the user's browser
   and returns the redirect-callback URL once they complete the flow
   (typically via a deep link your Flutter app handles).
3. Persistent token storage (use `flutter_secure_storage` or
   `health_forge`'s `TokenStore`).

For a complete runnable demo with real PKCE authorization and data queries,
see the
[Flutter example app](https://github.com/mandarnilange/health_forge/tree/main/example)
in the workspace root.

The
[Getting Started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md)
walks through deep-link setup, callback handling, and token persistence.
