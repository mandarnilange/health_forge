# health_forge

Flutter client for [Health Forge](https://github.com/mandarnilange/health_forge) — aggregate health data from multiple providers (HealthKit, Health Connect, Oura, Strava) into a unified data model with conflict resolution and local caching.

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
  health_forge: ^0.3.0
  health_forge_apple: ^0.3.0   # iOS — HealthKit
  health_forge_ghc: ^0.3.0     # Android — Health Connect
  health_forge_oura: ^0.3.0    # Oura Ring
  health_forge_strava: ^0.3.0  # Strava
```

Only add the provider packages you need — Health Forge is federated.

> **Using an AI coding agent?** Install the matching skill so Claude Code, Cursor, Codex, or any of the [50+ supported agents](https://skills.sh) can wire this in for you:
> ```bash
> npx skills add mandarnilange/health_forge --skill integrate-health-forge
> ```

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

See [docs/getting_started.md](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for iOS entitlements, Android manifest, and OAuth redirect setup.

## Token storage on Android

Create the `FlutterSecureStorage` you pass to `TokenStore` with
`resetOnError` turned off. This needs `flutter_secure_storage` as a direct
dependency of your app (`>=10.0.0 <12.0.0`):

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health_forge/health_forge.dart';

final tokenStore = TokenStore(
  storage: const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  ),
);
```

With the default (`true`), a failed read or write on Android silently deletes
everything in secure storage. `TokenStore` defends against this: `read`
returns null instead of the plugin's reset message, and `save` throws a
`TokenStoreException` if the token wasn't stored. Turning the option off means
failures surface as a `PlatformException` instead of a wipe.

## Upgrading to 0.3.0

`health_forge` now accepts `flutter_secure_storage` `>=10.0.0 <12.0.0`, so
a fresh `pub get` picks up v11. `TokenStore` only uses read, write, and delete,
so the change doesn't affect it. Check how your app creates the
`FlutterSecureStorage` you pass in:

- **Default options:** nothing to do. Every earlier `health_forge` release
  required `flutter_secure_storage` v10, so tokens were written with v10's
  default ciphers, which v11 keeps.
- **Options that v11 removed** (`encryptedSharedPreferences`,
  `sharedPreferencesName`, `RSA_ECB_PKCS1Padding`, `AES_CBC_PKCS7Padding`):
  switch to the v11 equivalents, such as `storageNamespace`. Tokens saved with
  the removed ciphers can't be read after the upgrade, so users have to sign
  in to Oura/Strava again. To defer this, keep `flutter_secure_storage` on
  `^10.0.0` in your app; `health_forge` 0.3.0 still resolves with it. On v11,
  `FlutterSecureStorage.checkUpgradeStatus()` reports whether any data was
  lost in the upgrade.

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
