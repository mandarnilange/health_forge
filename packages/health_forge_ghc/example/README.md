# health_forge_ghc example

Constructs a `GhcHealthProvider` and prints its capabilities (the metric
types it can read from Google Health Connect). The example doesn't authorize
or fetch — that requires a running Flutter app on Android with the Health
Connect read permissions declared in
`android/app/src/main/AndroidManifest.xml`.

For a complete runnable Android demo with authorization and queries, see the
[Flutter example app](https://github.com/mandarnilange/health_forge/tree/main/example)
in the workspace root.

The
[Getting Started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md)
covers the full Android setup checklist.
