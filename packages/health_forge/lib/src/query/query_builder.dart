import 'package:health_forge_core/health_forge_core.dart';

/// Immutable query specification for fetching health records.
class HealthQuery {
  /// Creates a [HealthQuery].
  const HealthQuery({
    required this.metrics,
    required this.timeRange,
    this.providers,
    this.mergeConfig,
  });

  /// The metric types to fetch.
  final List<MetricType> metrics;

  /// Optional provider filter; null means all registered providers.
  final List<DataProvider>? providers;

  /// The time range to query.
  final TimeRange timeRange;

  /// Optional merge configuration for multi-provider deduplication.
  final MergeConfig? mergeConfig;
}

/// Fluent builder for constructing [HealthQuery] instances.
class QueryBuilder {
  List<MetricType>? _metrics;
  List<DataProvider>? _providers;
  TimeRange? _timeRange;
  MergeConfig? _mergeConfig;

  /// Sets a single metric to query.
  void forMetric(MetricType metric) {
    _metrics = [metric];
  }

  /// Sets multiple metrics to query.
  void forMetrics(List<MetricType> metrics) {
    _metrics = List.of(metrics);
  }

  /// Restricts the query to a single provider.
  void from(DataProvider provider) {
    _providers = [provider];
  }

  /// Restricts the query to the given [providers].
  void fromProviders(List<DataProvider> providers) {
    _providers = List.of(providers);
  }

  /// Queries all registered providers (clears any provider filter).
  void fromAll() {
    _providers = null;
  }

  /// Sets the time range for the query.
  // ignore: use_setters_to_change_properties
  void inRange(TimeRange range) {
    _timeRange = range;
  }

  /// Sets the merge configuration for multi-provider results.
  // ignore: use_setters_to_change_properties
  void withMerge(MergeConfig config) {
    _mergeConfig = config;
  }

  /// Builds the [HealthQuery].
  /// Throws [StateError] if required fields missing.
  HealthQuery build() {
    if (_metrics == null || _metrics!.isEmpty) {
      throw StateError('At least one metric type is required');
    }
    if (_timeRange == null) {
      throw StateError('Time range is required');
    }
    return HealthQuery(
      metrics: _metrics!,
      timeRange: _timeRange!,
      providers: _providers,
      mergeConfig: _mergeConfig,
    );
  }
}
