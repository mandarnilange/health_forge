import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/merge/merge_config.dart';
import 'package:health_forge_core/src/merge/strategies/conflict_strategy_handler.dart';
import 'package:health_forge_core/src/models/cardiovascular/heart_rate_sample.dart';
import 'package:health_forge_core/src/models/health_record.dart';

/// Averages numeric values across conflicting records.
///
/// Currently supports [HeartRateSample]. For unsupported types,
/// falls back to returning the first record.
class AverageStrategy implements ConflictStrategyHandler {
  @override
  List<HealthRecordMixin> resolve(
    List<HealthRecordMixin> conflicts,
    MergeConfig config,
    MetricType metricType,
  ) {
    if (conflicts.length <= 1) return conflicts;

    if (conflicts.every((r) => r is HeartRateSample)) {
      return _averageHeartRate(conflicts.cast<HeartRateSample>());
    }

    // Unsupported type — fall back to first record
    return [conflicts.first];
  }

  List<HealthRecordMixin> _averageHeartRate(List<HeartRateSample> records) {
    final avg =
        records.map((r) => r.beatsPerMinute).reduce((a, b) => a + b) ~/
        records.length;

    return [records.first.copyWith(beatsPerMinute: avg)];
  }
}
