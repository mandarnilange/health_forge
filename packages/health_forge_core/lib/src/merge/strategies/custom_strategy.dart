import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/merge/merge_config.dart';
import 'package:health_forge_core/src/merge/strategies/conflict_strategy_handler.dart';
import 'package:health_forge_core/src/models/health_record.dart';

/// Delegates conflict resolution to a user-supplied callback.
class CustomStrategy implements ConflictStrategyHandler {
  /// Creates a [CustomStrategy] with the given [resolver] callback.
  const CustomStrategy({required this.resolver});

  /// The callback that performs the actual resolution.
  final List<HealthRecordMixin> Function(
    List<HealthRecordMixin> records,
    MetricType metricType,
  ) resolver;

  @override
  List<HealthRecordMixin> resolve(
    List<HealthRecordMixin> conflicts,
    MergeConfig config,
    MetricType metricType,
  ) {
    return resolver(conflicts, metricType);
  }
}
