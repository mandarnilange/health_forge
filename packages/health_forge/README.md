# health_forge

Flutter client for [Health Forge](https://github.com/mandarnilange/health_forge_workspace) — aggregate health data from multiple providers (HealthKit, Health Connect, Oura, Strava) into a unified data model with conflict resolution and local caching.

Built on [`health_forge_core`](https://pub.dev/packages/health_forge_core) (pure Dart data model + merge engine).

## Features

- **Provider registry** — register any `HealthProvider` implementation and the client discovers its capabilities
- **Auth orchestration** — authorize/deauthorize/checkAll across all registered providers
- **Fluent query API** — build cross-provider queries by `MetricType` + `TimeRange`, pick a merge strategy per query
- **Caching** — `InMemoryCacheManager` for tests, `DriftCacheManager` (SQLite) for production
- **Sync manager** — coordinate incremental syncs with deduplication and metadata tracking
- **Secure token storage** — `TokenStore` wraps `flutter_secure_storage` for OAuth tokens

## Installation

```yaml
dependencies:
  health_forge: ^0.1.0
  health_forge_apple: ^0.1.0   # iOS — HealthKit
  health_forge_ghc: ^0.1.0     # Android — Health Connect
  health_forge_oura: ^0.1.0    # Oura Ring
  health_forge_strava: ^0.1.0  # Strava
```

Only add the provider packages you need — Health Forge is federated.

## Usage

```dart
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_apple/health_forge_apple.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';

final forge = HealthForgeClient();

forge.use(AppleHealthProvider());
forge.use(GhcHealthProvider());

await forge.auth.authorizeAll();

final builder = forge.query()
  ..forMetrics([MetricType.heartRate, MetricType.sleepSession])
  ..inRange(TimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  ));

final executor = QueryExecutor(
  registry: forge.registry,
  mergeEngine: MergeEngine(config: const MergeConfig()),
);
final result = await executor.execute(builder.build());

for (final record in result.records) {
  print('${record.provider}: ${record.providerRecordType}');
}
```

## Platform setup

See [docs/getting_started.md](https://github.com/mandarnilange/health_forge_workspace/blob/main/docs/getting_started.md) for iOS entitlements, Android manifest, and OAuth redirect setup.

## Related packages

| Package | Purpose |
|---|---|
| [`health_forge_core`](https://pub.dev/packages/health_forge_core) | Pure Dart data model + merge engine (required) |
| [`health_forge_apple`](https://pub.dev/packages/health_forge_apple) | Apple HealthKit adapter |
| [`health_forge_ghc`](https://pub.dev/packages/health_forge_ghc) | Google Health Connect adapter |
| [`health_forge_oura`](https://pub.dev/packages/health_forge_oura) | Oura Ring REST API adapter |
| [`health_forge_strava`](https://pub.dev/packages/health_forge_strava) | Strava REST API adapter |

## License

MIT
