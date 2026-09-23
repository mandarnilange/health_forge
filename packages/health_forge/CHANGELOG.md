## 0.3.0

- **Breaking:** minimum SDK raised to Dart 3.10 / Flutter 3.38.1.
- `flutter_secure_storage` constraint widened to `>=10.0.0 <12.0.0`, so
  v11 is now supported. Apps that built `FlutterSecureStorage` with options
  removed in v11 should read "Upgrading to 0.3.0" in the README.
- Upgraded `drift` to `^2.35.0`.
- Bumped `health_forge_core` dependency to `^0.3.0`.
- **Fixed:** `TokenStore.read` now returns null instead of the
  `"Data has been reset"` string. On Android, `flutter_secure_storage`
  returns that string after its `resetOnError` default wipes storage
  following a failure, and it was previously handed back as a token.

## 0.2.0

- Bumped `health_forge_core` dependency to `^0.2.0`
  (`HeartRateVariability.sdnnMilliseconds` is now nullable).

## 0.1.1

- Added `example/example.dart` demonstrating `HealthForgeClient` and
  `QueryBuilder` usage
- Added `example/README.md` linking to the workspace Flutter example app
- Bumped `health_forge_core` dependency to `^0.1.1`
- Shortened pubspec description for cleaner pub.dev display

## 0.1.0

- Initial release
- HealthForgeClient — main entry point for multi-provider health data aggregation
- ProviderRegistry — register and discover health data providers
- AuthOrchestrator — authorize/deauthorize flows for all registered providers
- QueryBuilder/QueryExecutor — fluent query API with multi-provider execution
- InMemoryCacheManager and DriftCacheManager (SQLite) for local caching
- SyncManager — sync coordination with deduplication
- TokenStore — secure OAuth token persistence via flutter_secure_storage
- See [getting started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for usage