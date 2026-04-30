import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/merge/merge_config.dart';
import 'package:health_forge_core/src/merge/strategies/conflict_strategy_handler.dart';
import 'package:health_forge_core/src/models/health_record.dart';

/// Resolves conflicts by selecting the record from the
/// highest-priority provider.
class PriorityBasedStrategy implements ConflictStrategyHandler {
  @override
  List<HealthRecordMixin> resolve(
    List<HealthRecordMixin> conflicts,
    MergeConfig config,
    MetricType metricType,
  ) {
    if (conflicts.length <= 1) return conflicts;

    final priority = config.priorityFor(metricType);
    if (priority.isEmpty) return [conflicts.first];

    final sorted = List<HealthRecordMixin>.from(conflicts)
      ..sort((a, b) {
        final aIndex = priority.indexOf(a.provider);
        final bIndex = priority.indexOf(b.provider);
        final aRank = aIndex == -1 ? priority.length : aIndex;
        final bRank = bIndex == -1 ? priority.length : bIndex;
        return aRank.compareTo(bRank);
      });

    return [sorted.first];
  }
}
