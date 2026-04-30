import 'package:health_forge/src/cache/cache_manager.dart';
import 'package:health_forge/src/registry/provider_registry.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Result of a sync operation.
class SyncResult {
  /// Creates a [SyncResult].
  const SyncResult({
    required this.recordsFetched,
    required this.recordsCached,
    required this.duplicatesDetected,
    required this.duration,
    this.error,
  });

  /// Number of records fetched from the provider.
  final int recordsFetched;

  /// Number of records stored in cache after merge.
  final int recordsCached;

  /// Number of duplicate/conflict groups detected.
  final int duplicatesDetected;

  /// Total time the sync operation took.
  final Duration duration;

  /// Error message if the sync failed, or null on success.
  final String? error;
}

/// Manages syncing health data from providers into the cache.
class SyncManager {
  /// Creates a [SyncManager].
  SyncManager({
    required ProviderRegistry registry,
    required CacheManager cache,
    required MergeEngine mergeEngine,
  })  : _registry = registry,
        _cache = cache,
        _mergeEngine = mergeEngine;

  final ProviderRegistry _registry;
  final CacheManager _cache;
  final MergeEngine _mergeEngine;

  /// Syncs records for a single [provider] and [metric]
  /// within [range].
  Future<SyncResult> sync({
    required DataProvider provider,
    required MetricType metric,
    required TimeRange range,
  }) async {
    final stopwatch = Stopwatch()..start();

    final p = _registry.provider(provider);
    if (p == null) {
      stopwatch.stop();
      return SyncResult(
        recordsFetched: 0,
        recordsCached: 0,
        duplicatesDetected: 0,
        duration: stopwatch.elapsed,
        error: 'Provider ${provider.name} is not registered',
      );
    }

    try {
      final records = await p.fetchRecords(
        metricType: metric,
        timeRange: range,
      );

      // Merge with existing cached records to detect duplicates
      final existing = await _cache.get(
        metric: metric,
        range: range,
        provider: provider,
      );
      final all = [...existing, ...records];
      final mergeResult = _mergeEngine.merge(all);

      // Replace cached records only for this provider/metric/range.
      // Scoped invalidation prevents wiping records outside the sync window.
      await _cache.invalidate(
        provider: provider,
        metric: metric,
        range: range,
      );
      await _cache.put(mergeResult.resolved);

      await _cache.updateSyncMetadata(
        provider,
        metric,
        lastSync: DateTime.now(),
      );

      stopwatch.stop();
      return SyncResult(
        recordsFetched: records.length,
        recordsCached: mergeResult.resolved.length,
        duplicatesDetected: mergeResult.conflicts.length,
        duration: stopwatch.elapsed,
      );
    } on Exception catch (e) {
      stopwatch.stop();
      return SyncResult(
        recordsFetched: 0,
        recordsCached: 0,
        duplicatesDetected: 0,
        duration: stopwatch.elapsed,
        error: e.toString(),
      );
    }
  }

  /// Syncs all registered providers for the given [metrics]
  /// within [range].
  Future<Map<DataProvider, SyncResult>> syncAll({
    required List<MetricType> metrics,
    required TimeRange range,
  }) async {
    final results = <DataProvider, SyncResult>{};

    for (final metric in metrics) {
      final providers = _registry.supporting(metric);
      for (final provider in providers) {
        final result = await sync(
          provider: provider.providerType,
          metric: metric,
          range: range,
        );

        // Accumulate results per provider
        final existing = results[provider.providerType];
        if (existing == null) {
          results[provider.providerType] = result;
        } else {
          results[provider.providerType] = SyncResult(
            recordsFetched: existing.recordsFetched + result.recordsFetched,
            recordsCached: existing.recordsCached + result.recordsCached,
            duplicatesDetected:
                existing.duplicatesDetected + result.duplicatesDetected,
            duration: existing.duration + result.duration,
            error: result.error ?? existing.error,
          );
        }
      }
    }

    return results;
  }
}
