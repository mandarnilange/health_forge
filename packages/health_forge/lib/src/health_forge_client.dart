import 'package:health_forge/src/auth/auth_orchestrator.dart';
import 'package:health_forge/src/cache/cache_manager.dart';
import 'package:health_forge/src/query/query_builder.dart';
import 'package:health_forge/src/registry/provider_registry.dart';
import 'package:health_forge/src/sync/sync_manager.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Main entry point for the Health Forge SDK.
class HealthForgeClient {
  /// Creates a [HealthForgeClient] with optional [mergeConfig] and [cache].
  ///
  /// By default, uses an [InMemoryCacheManager] which loses data on restart.
  /// For persistence, pass a `DriftCacheManager`:
  ///
  /// ```dart
  /// final db = HealthCacheDatabase(NativeDatabase.createInBackground(file));
  /// final forge = HealthForgeClient(cache: DriftCacheManager(database: db));
  /// ```
  HealthForgeClient({
    MergeConfig? mergeConfig,
    CacheManager? cache,
  })  : _mergeConfig = mergeConfig ?? const MergeConfig(),
        _cache = cache ?? InMemoryCacheManager() {
    _mergeEngine = MergeEngine(config: _mergeConfig);
    _auth = AuthOrchestrator(registry: _registry);
    _syncManager = SyncManager(
      registry: _registry,
      cache: _cache,
      mergeEngine: _mergeEngine,
    );
  }

  final MergeConfig _mergeConfig;
  final CacheManager _cache;
  final ProviderRegistry _registry = ProviderRegistry();
  late final MergeEngine _mergeEngine;
  late final AuthOrchestrator _auth;
  late final SyncManager _syncManager;

  /// The provider registry.
  ProviderRegistry get registry => _registry;

  /// The auth orchestrator.
  AuthOrchestrator get auth => _auth;

  /// The cache manager.
  CacheManager get cache => _cache;

  /// Registers a health [provider] for use.
  void use(HealthProvider provider) {
    _registry.register(provider);
  }

  /// Creates a new query builder.
  QueryBuilder query() => QueryBuilder();

  /// Syncs records from a [provider] for a [metric] within [range].
  Future<SyncResult> sync({
    required DataProvider provider,
    required MetricType metric,
    required TimeRange range,
  }) {
    return _syncManager.sync(
      provider: provider,
      metric: metric,
      range: range,
    );
  }

  /// Disposes resources held by this client.
  void dispose() {
    // Reserved for future resource cleanup.
  }
}
