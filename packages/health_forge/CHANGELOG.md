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