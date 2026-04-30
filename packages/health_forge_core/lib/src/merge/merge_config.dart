import 'package:health_forge_core/src/enums/conflict_strategy.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/metric_type.dart';

/// Configuration controlling conflict resolution strategies,
/// provider priorities, and duplicate-detection thresholds.
class MergeConfig {
  /// Creates a [MergeConfig] with sensible defaults.
  const MergeConfig({
    this.defaultStrategy = ConflictStrategy.priorityBased,
    this.providerPriority = const [],
    this.perMetricStrategy = const {},
    this.perMetricPriority = const {},
    this.valueSimilarityThreshold = 0.05,
    this.timeOverlapThresholdSeconds = 300,
  });

  /// The default conflict resolution strategy when no per-metric
  /// override exists.
  final ConflictStrategy defaultStrategy;

  /// Global provider priority list (index 0 = highest priority).
  final List<DataProvider> providerPriority;

  /// Per-metric overrides of the conflict resolution strategy.
  final Map<MetricType, ConflictStrategy> perMetricStrategy;

  /// Per-metric overrides of the provider priority list.
  final Map<MetricType, List<DataProvider>> perMetricPriority;

  /// Reserved for future duplicate detection: fractional tolerance for
  /// treating two numeric samples as the same event (0.05 = 5%).
  ///
  /// Not used for overlap clustering in v0.1.x (time threshold only).
  final double valueSimilarityThreshold;

  /// Maximum seconds between record times to consider
  /// them overlapping.
  final int timeOverlapThresholdSeconds;

  /// Returns the conflict strategy for [metric], falling back
  /// to [defaultStrategy].
  ConflictStrategy strategyFor(MetricType metric) =>
      perMetricStrategy[metric] ?? defaultStrategy;

  /// Returns the provider priority list for [metric], falling
  /// back to [providerPriority].
  List<DataProvider> priorityFor(MetricType metric) =>
      perMetricPriority[metric] ?? providerPriority;
}
