import 'package:health_forge/src/query/query_builder.dart';
import 'package:health_forge/src/query/query_result.dart';
import 'package:health_forge/src/registry/provider_registry.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Executes [HealthQuery] instances against registered providers.
class QueryExecutor {
  /// Creates a [QueryExecutor].
  QueryExecutor({
    required ProviderRegistry registry,
    required MergeEngine mergeEngine,
  })  : _registry = registry,
        _mergeEngine = mergeEngine;

  final ProviderRegistry _registry;
  final MergeEngine _mergeEngine;

  /// Executes [query] and returns a [QueryResult].
  Future<QueryResult> execute(HealthQuery query) async {
    final stopwatch = Stopwatch()..start();
    final allRecords = <HealthRecordMixin>[];
    final errors = <DataProvider, String>{};

    for (final metric in query.metrics) {
      final providers = _resolveProviders(query, metric);

      for (final provider in providers) {
        try {
          final records = await provider.fetchRecords(
            metricType: metric,
            timeRange: query.timeRange,
          );
          allRecords.addAll(records);
        } on Exception catch (e) {
          errors[provider.providerType] = e.toString();
          // Providers are external adapters; a misbehaving one throwing an
          // Error (e.g. ArgumentError) must not abort the whole fan-out.
          // ignore: avoid_catching_errors
        } on Error catch (e) {
          errors[provider.providerType] = e.toString();
        }
      }
    }

    stopwatch.stop();

    MergeResult? mergeResult;
    final List<HealthRecordMixin> finalRecords;

    if (query.mergeConfig != null && allRecords.isNotEmpty) {
      mergeResult = _mergeEngine.merge(allRecords);
      finalRecords = mergeResult.resolved;
    } else {
      finalRecords = allRecords;
    }

    return QueryResult(
      records: finalRecords,
      mergeResult: mergeResult,
      errors: errors,
      fetchDuration: stopwatch.elapsed,
    );
  }

  List<HealthProvider> _resolveProviders(
    HealthQuery query,
    MetricType metric,
  ) {
    if (query.providers != null) {
      return query.providers!
          .map(_registry.provider)
          .whereType<HealthProvider>()
          .toList();
    }
    return _registry.supporting(metric);
  }
}
