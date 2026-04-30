# health_forge example

The example constructs a `HealthForgeClient`, builds a multi-metric query
spanning the past 7 days via `QueryBuilder`, and prints summary information.
It does not execute the query — you'd register platform-specific
`HealthProvider` implementations (e.g. `AppleHealthProvider`,
`GhcHealthProvider`) via `forge.use(...)` first, which requires a running
Flutter app context.

For a complete runnable demo with real providers, query execution, conflict
resolution, and a UI, see the
[Flutter example app](https://github.com/mandarnilange/health_forge/tree/main/example)
in the workspace root.

The
[Getting Started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md)
walks through platform setup (HealthKit entitlements, Health Connect
permissions, OAuth deep-link configuration) end to end.
