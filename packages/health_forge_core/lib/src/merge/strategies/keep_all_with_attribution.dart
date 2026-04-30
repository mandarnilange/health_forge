import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/merge/merge_config.dart';
import 'package:health_forge_core/src/merge/strategies/conflict_strategy_handler.dart';
import 'package:health_forge_core/src/models/health_record.dart';

/// Resolves conflicts by keeping all records with their original attribution.
class KeepAllWithAttributionStrategy implements ConflictStrategyHandler {
  @override
  List<HealthRecordMixin> resolve(
    List<HealthRecordMixin> conflicts,
    MergeConfig config,
    MetricType metricType,
  ) {
    return conflicts;
  }
}
