import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/merge/merge_config.dart';
import 'package:health_forge_core/src/models/health_record.dart';

/// Interface for conflict resolution strategies used by the
/// merge engine.
// ignore: one_member_abstracts
abstract class ConflictStrategyHandler {
  /// Resolves a group of overlapping [conflicts] for [metricType].
  List<HealthRecordMixin> resolve(
    List<HealthRecordMixin> conflicts,
    MergeConfig config,
    MetricType metricType,
  );
}
