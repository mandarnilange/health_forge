---
name: integrate-health-forge
description: >
  Integrate the `health_forge` Flutter client into a user's app — registry,
  auth orchestration, fluent query builder, sync manager, and local cache
  (InMemory or Drift/SQLite). Trigger when the user wants to aggregate health
  data from multiple providers in a Flutter app. Pair with one or more adapter
  skills (`integrate-health-forge-apple`, `-ghc`, `-oura`, `-strava`) for
  actual data sources.
---

# Integrate health_forge

`health_forge` is the Flutter client that ties everything together: a provider registry, auth orchestrator, fluent query API, sync manager, and cache. It depends on [`health_forge_core`](../integrate-health-forge-core/SKILL.md) transitively.

This skill is the **foundation** — invoke alongside one or more adapter skills for the user's target providers.

## Integration steps

### 1. Add dependencies

```yaml
dependencies:
  health_forge: ^0.1.0
  # Add each adapter the user needs — see related skills:
  health_forge_apple: ^0.1.0     # iOS HealthKit
  health_forge_ghc: ^0.1.0       # Android Health Connect
  health_forge_oura: ^0.1.0      # Oura Ring
  health_forge_strava: ^0.1.0    # Strava
```

Run `flutter pub get`.

### 2. Create the client

```dart
import 'package:health_forge/health_forge.dart';

final forge = HealthForgeClient();
```

**With persistent SQLite cache (recommended for production):**

```dart
import 'dart:io';
import 'package:drift/native.dart';
import 'package:health_forge/health_forge.dart';
import 'package:path_provider/path_provider.dart';

Future<HealthForgeClient> createClient() async {
  final dir = await getApplicationSupportDirectory();
  final db = HealthCacheDatabase(
    NativeDatabase.createInBackground(File('${dir.path}/health_cache.db')),
  );
  return HealthForgeClient(cache: DriftCacheManager(database: db));
}
```

Without a cache argument, an `InMemoryCacheManager` is used (data lost on restart).

**With custom merge config:**

```dart
final forge = HealthForgeClient(
  mergeConfig: const MergeConfig(
    defaultStrategy: ConflictStrategy.priorityBased,
    providerPriority: [DataProvider.apple, DataProvider.oura],
    perMetricStrategy: {
      MetricType.heartRate: ConflictStrategy.keepAll,  // high-frequency data
    },
  ),
);
```

### 3. Register providers

Use platform detection for native adapters:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health_forge_apple/health_forge_apple.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';

if (!kIsWeb && Platform.isIOS) {
  forge.use(AppleHealthProvider());
} else if (!kIsWeb && Platform.isAndroid) {
  forge.use(GhcHealthProvider());
}

// REST providers work on all platforms — see adapter skills for OAuth setup.
forge.use(ouraProvider);
forge.use(stravaProvider);
```

### 4. Authorize

```dart
final results = await forge.auth.authorizeAll();
for (final entry in results.entries) {
  if (!entry.value.isSuccess) {
    print('${entry.key} not authorized: ${entry.value.status}');
  }
}
```

Individual: `await forge.auth.authorize(DataProvider.apple)`.
Check status: `await forge.auth.isAuthorized(DataProvider.oura)`.

### 5. Query (live fetch)

```dart
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
  if (record is HeartRateSample) {
    print('${record.provider}: ${record.beatsPerMinute} bpm');
  }
}

if (result.errors.isNotEmpty) {
  // Provider failures do NOT block others — inspect per-provider errors here.
  result.errors.forEach((p, e) => print('$p: $e'));
}
```

Filter providers: `..from(DataProvider.oura)` or `..fromProviders([…])`.
Per-query merge override: `..withMerge(MergeConfig(...))`.

### 6. Sync (fetch + cache + dedup)

```dart
final syncResult = await forge.sync(
  provider: DataProvider.apple,
  metric: MetricType.heartRate,
  range: TimeRange(
    start: DateTime.now().subtract(const Duration(days: 1)),
    end: DateTime.now(),
  ),
);

print('Fetched ${syncResult.recordsFetched}, cached ${syncResult.recordsCached}');

// Later — read from cache
final cached = await forge.cache.get(
  metric: MetricType.heartRate,
  range: lastDay,
);
```

### 7. Persist OAuth tokens (REST providers)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStore = TokenStore(const FlutterSecureStorage());

// Wire into the auth manager — see adapter skills for provider specifics.
final ouraAuth = OuraAuthManager(
  clientId: '...',
  redirectUri: '...',
  urlLauncher: launchAndWaitForRedirect,
  initialToken: await _restoreToken(tokenStore, DataProvider.oura),
  onTokenChanged: (t) => _saveToken(tokenStore, DataProvider.oura, t),
);
```

## Key APIs

| API | Use for |
|---|---|
| `HealthForgeClient` | Main entry point |
| `forge.use(provider)` / `forge.registry` | Register and discover providers |
| `forge.auth.*` | `authorize`, `authorizeAll`, `isAuthorized`, `checkAll` |
| `forge.query()` → `QueryBuilder` → `QueryExecutor` | On-demand fetch (optionally merged) |
| `forge.sync(...)` | Fetch + merge-with-cache + store |
| `forge.cache.get / put / invalidate / clear` | Direct cache access |
| `DriftCacheManager` | Persistent SQLite cache (dedup by provider+metric+time+device) |
| `TokenStore` | Secure OAuth token persistence |
| `MergeConfig` | Configure strategies + provider priority + overlap threshold |

## Query vs sync — pick one

| | `query()` | `sync()` |
|---|---|---|
| Fetches from | All or filtered providers | One provider |
| Caches | No | Yes |
| Merges | Only if `withMerge()` set | Always (new + cache) |
| Use for | Real-time UI | Background pulls, offline |

Typical app: periodic `sync()` to keep cache fresh; UI reads from cache. Use `query()` for one-off multi-provider fetches.

## Gotchas

- **Provider failures don't block queries** — always check `result.errors` as well as `result.records`.
- **iOS HealthKit `hasPermissions` is unreliable** — track auth state locally after a successful `authorize()`; don't rely on repeatedly calling `isAuthorized()` as ground truth on iOS.
- **High-frequency metrics** (steps, HR from Apple Watch) are recorded in small ~5-minute increments. Default `ConflictStrategy.priorityBased` with a 5-minute overlap threshold will collapse them. Use `ConflictStrategy.keepAll` per-metric if you want every sample preserved.
- **`DriftCacheManager` dedups** on natural key (provider + metric + time + device). If you `put()` the same record twice, the second call is a no-op.

## Related skills

Pair this skill with one or more adapter skills:

- [`integrate-health-forge-apple`](../integrate-health-forge-apple/SKILL.md) — iOS HealthKit
- [`integrate-health-forge-ghc`](../integrate-health-forge-ghc/SKILL.md) — Android Health Connect
- [`integrate-health-forge-oura`](../integrate-health-forge-oura/SKILL.md) — Oura Ring OAuth
- [`integrate-health-forge-strava`](../integrate-health-forge-strava/SKILL.md) — Strava OAuth
- [`integrate-health-forge-core`](../integrate-health-forge-core/SKILL.md) — pure Dart core (advanced: custom providers)
