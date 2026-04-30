# health_forge_apple example

Constructs an `AppleHealthProvider` and prints its capabilities (the metric
types it can read from HealthKit). The example doesn't authorize or fetch —
that requires a running Flutter app on iOS, the HealthKit entitlement, and
the `NSHealthShareUsageDescription` key in `ios/Runner/Info.plist`.

For a complete runnable iOS demo with authorization and queries, see the
[Flutter example app](https://github.com/mandarnilange/health_forge/tree/main/example)
in the workspace root.

The
[Getting Started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md)
covers the full iOS setup checklist.
