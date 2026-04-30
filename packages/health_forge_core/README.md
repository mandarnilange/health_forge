# health_forge_core

Pure Dart core library for [Health Forge](https://github.com/mandarnilange/health_forge_workspace) — a federated, zero-backend Flutter toolkit for aggregating health data from multiple providers into a unified data model.

This package has **zero Flutter dependencies** and is isolate-safe. It defines the shared data model, provider interfaces, and conflict resolution engine used by every other `health_forge_*` package.

## What's inside

- **21 health record types** across 6 families — activity, cardiovascular, sleep, recovery, respiratory, body
- **7 enums** — `MetricType`, `DataProvider`, `DataOrigin`, `ConflictStrategy`, `Freshness`, `AccessMode`, `SyncModel`
- **Envelope mixin** — `HealthRecordMixin` (id, provider, timestamps, provenance, extensions) on every record
- **Provider interfaces** — `HealthProvider`, `ProviderCapabilities`, `AuthResult`, `AuthStatus`
- **MergeEngine** — 5 conflict resolution strategies: priority-based, keep-all, average, most-granular, custom
- **DuplicateDetector** — clusters overlapping records per `MetricType` using a configurable `timeOverlapThresholdSeconds`
- **Provider extensions** — type-safe registry for provider-specific metrics (`OuraSleepExtension`, `StravaWorkoutExtension`, `GarminSleepExtension`)

## Installation

```yaml
dependencies:
  health_forge_core: ^0.1.0
```

You typically won't depend on this package directly — use [`health_forge`](https://pub.dev/packages/health_forge) (Flutter client) plus the provider adapters you need.

## Usage

```dart
import 'package:health_forge_core/health_forge_core.dart';

final engine = MergeEngine(
  config: const MergeConfig(
    defaultStrategy: ConflictStrategy.priorityBased,
    providerPriority: [DataProvider.oura, DataProvider.apple],
  ),
);

final merged = engine.merge(records);
for (final record in merged.records) {
  print('${record.provider}: ${record.providerRecordType}');
}
```

## Related packages

| Package | Purpose |
|---|---|
| [`health_forge`](https://pub.dev/packages/health_forge) | Flutter client (registry, auth, queries, cache) |
| [`health_forge_apple`](https://pub.dev/packages/health_forge_apple) | Apple HealthKit adapter |
| [`health_forge_ghc`](https://pub.dev/packages/health_forge_ghc) | Google Health Connect adapter |
| [`health_forge_oura`](https://pub.dev/packages/health_forge_oura) | Oura Ring REST API adapter |
| [`health_forge_strava`](https://pub.dev/packages/health_forge_strava) | Strava REST API adapter |

## Documentation

- [Getting started guide](https://github.com/mandarnilange/health_forge_workspace/blob/main/docs/getting_started.md)
- [Architecture decision records](https://github.com/mandarnilange/health_forge_workspace/tree/main/design/adr)

## License

MIT
