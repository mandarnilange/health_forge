import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/merge/merge_config.dart';
import 'package:health_forge_core/src/merge/strategies/conflict_strategy_handler.dart';
import 'package:health_forge_core/src/models/health_record.dart';

/// Resolves conflicts by selecting the record with the shortest duration.
class MostGranularStrategy implements ConflictStrategyHandler {
  @override
  List<HealthRecordMixin> resolve(
    List<HealthRecordMixin> conflicts,
    MergeConfig config,
    MetricType metricType,
  ) {
    if (conflicts.length <= 1) return conflicts;

    final sorted = List<HealthRecordMixin>.from(conflicts)
      ..sort((a, b) => a.duration.compareTo(b.duration));

    return [sorted.first];
  }
}
