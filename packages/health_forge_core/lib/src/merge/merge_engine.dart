import 'package:health_forge_core/src/enums/conflict_strategy.dart';
import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/merge/duplicate_detector.dart';
import 'package:health_forge_core/src/merge/merge_config.dart';
import 'package:health_forge_core/src/merge/merge_result.dart';
import 'package:health_forge_core/src/merge/strategies/average_strategy.dart';
import 'package:health_forge_core/src/merge/strategies/conflict_strategy_handler.dart';
import 'package:health_forge_core/src/merge/strategies/custom_strategy.dart';
import 'package:health_forge_core/src/merge/strategies/keep_all_with_attribution.dart';
import 'package:health_forge_core/src/merge/strategies/most_granular.dart';
import 'package:health_forge_core/src/merge/strategies/priority_based.dart';
import 'package:health_forge_core/src/models/activity/activity_session.dart';
import 'package:health_forge_core/src/models/activity/calories_burned.dart';
import 'package:health_forge_core/src/models/activity/distance_sample.dart';
import 'package:health_forge_core/src/models/activity/elevation_gain.dart';
import 'package:health_forge_core/src/models/activity/step_count.dart';
import 'package:health_forge_core/src/models/activity/workout_route.dart';
import 'package:health_forge_core/src/models/body/blood_glucose.dart';
import 'package:health_forge_core/src/models/body/blood_pressure.dart';
import 'package:health_forge_core/src/models/body/body_fat.dart';
import 'package:health_forge_core/src/models/body/weight.dart';
import 'package:health_forge_core/src/models/cardiovascular/heart_rate_sample.dart';
import 'package:health_forge_core/src/models/cardiovascular/heart_rate_variability.dart';
import 'package:health_forge_core/src/models/cardiovascular/resting_heart_rate.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/recovery/readiness_score.dart';
import 'package:health_forge_core/src/models/recovery/recovery_metric.dart';
import 'package:health_forge_core/src/models/recovery/stress_score.dart';
import 'package:health_forge_core/src/models/respiratory/blood_oxygen_sample.dart';
import 'package:health_forge_core/src/models/respiratory/respiratory_rate.dart';
import 'package:health_forge_core/src/models/sleep/sleep_score.dart';
import 'package:health_forge_core/src/models/sleep/sleep_session.dart';
import 'package:health_forge_core/src/models/sleep/sleep_stage_segment.dart';

/// Deduplicates and merges health records from multiple providers.
///
/// Groups records by [MetricType], detects overlapping entries, and applies
/// the configured [ConflictStrategy] to resolve each conflict group.
class MergeEngine {
  /// Creates a [MergeEngine] with the given [config].
  ///
  /// Pass a [customStrategy] when using [ConflictStrategy.custom].
  MergeEngine({
    required this.config,
    CustomStrategy? customStrategy,
  }) : _customStrategy = customStrategy;

  /// The merge configuration controlling strategies and thresholds.
  final MergeConfig config;
  final CustomStrategy? _customStrategy;

  static final _strategies = <ConflictStrategy, ConflictStrategyHandler>{
    ConflictStrategy.priorityBased: PriorityBasedStrategy(),
    ConflictStrategy.keepAll: KeepAllWithAttributionStrategy(),
    ConflictStrategy.average: AverageStrategy(),
    ConflictStrategy.mostGranular: MostGranularStrategy(),
  };

  /// Merges [records], returning resolved records and
  /// conflict reports.
  MergeResult merge(List<HealthRecordMixin> records) {
    if (records.isEmpty) {
      return const MergeResult(resolved: [], conflicts: [], rawSources: []);
    }

    final resolved = <HealthRecordMixin>[];
    final conflicts = <ConflictReport>[];
    final detector = DuplicateDetector(config: config);

    // Group by MetricType
    final byMetric = <MetricType, List<HealthRecordMixin>>{};
    for (final record in records) {
      final metric = _metricTypeFor(record);
      (byMetric[metric] ??= []).add(record);
    }

    // Process each metric group
    for (final entry in byMetric.entries) {
      final metricType = entry.key;
      final metricRecords = entry.value
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      final groups = detector.detectOverlaps(metricRecords);

      for (final group in groups) {
        if (group.length == 1) {
          resolved.add(group.first);
          continue;
        }

        final strategy = config.strategyFor(metricType);
        final handler = _handlerFor(strategy);
        final result = handler.resolve(group, config, metricType);

        resolved.addAll(result);
        conflicts.add(
          ConflictReport(
            metricType: metricType,
            strategy: strategy,
            inputRecords: group,
            resolvedRecord: result.isNotEmpty ? result.first : null,
            reason: 'Resolved ${group.length} overlapping records '
                'using ${strategy.name}',
          ),
        );
      }
    }

    return MergeResult(
      resolved: resolved,
      conflicts: conflicts,
      rawSources: List.unmodifiable(records),
    );
  }

  ConflictStrategyHandler _handlerFor(ConflictStrategy strategy) {
    if (strategy == ConflictStrategy.custom) {
      if (_customStrategy == null) {
        throw StateError(
          'ConflictStrategy.custom requires a CustomStrategy instance',
        );
      }
      return _customStrategy;
    }
    return _strategies[strategy]!;
  }

  /// Resolves [MetricType] from the record's concrete type.
  ///
  /// Uses exhaustive type matching on all 21 core record classes so that
  /// provider-specific `providerRecordType` strings cannot cause
  /// misclassification.
  static MetricType _metricTypeFor(HealthRecordMixin record) {
    return switch (record) {
      HeartRateSample() => MetricType.heartRate,
      HeartRateVariability() => MetricType.hrv,
      RestingHeartRate() => MetricType.restingHeartRate,
      StepCount() => MetricType.steps,
      CaloriesBurned() => MetricType.calories,
      DistanceSample() => MetricType.distance,
      ElevationGain() => MetricType.elevation,
      ActivitySession() => MetricType.workout,
      WorkoutRoute() => MetricType.workout,
      SleepSession() => MetricType.sleepSession,
      SleepStageSegment() => MetricType.sleepSession,
      SleepScore() => MetricType.sleepScore,
      ReadinessScore() => MetricType.readiness,
      StressScore() => MetricType.stress,
      RecoveryMetric() => MetricType.recovery,
      BloodOxygenSample() => MetricType.bloodOxygen,
      RespiratoryRate() => MetricType.respiratoryRate,
      Weight() => MetricType.weight,
      BodyFat() => MetricType.bodyFat,
      BloodPressure() => MetricType.bloodPressure,
      BloodGlucose() => MetricType.bloodGlucose,
      _ => _metricTypeFromProviderRecordType(record.providerRecordType),
    };
  }

  static MetricType _metricTypeFromProviderRecordType(String type) {
    return switch (type.toLowerCase()) {
      'heartrate' || 'heart_rate' => MetricType.heartRate,
      'hrv' || 'heart_rate_variability' => MetricType.hrv,
      'sleep' || 'sleepsession' || 'sleep_session' => MetricType.sleepSession,
      'steps' || 'step_count' => MetricType.steps,
      'weight' => MetricType.weight,
      'bodyfat' || 'body_fat' => MetricType.bodyFat,
      'bloodpressure' || 'blood_pressure' => MetricType.bloodPressure,
      'bloodglucose' || 'blood_glucose' => MetricType.bloodGlucose,
      'calories' || 'calories_burned' => MetricType.calories,
      'distance' || 'distance_sample' => MetricType.distance,
      'elevation' || 'elevation_gain' => MetricType.elevation,
      'workout' || 'activity_session' => MetricType.workout,
      'readiness' || 'readiness_score' => MetricType.readiness,
      'stress' || 'stress_score' => MetricType.stress,
      'recovery' || 'recovery_metric' => MetricType.recovery,
      'bloodoxygen' || 'blood_oxygen' => MetricType.bloodOxygen,
      'respiratoryrate' || 'respiratory_rate' => MetricType.respiratoryRate,
      'restingheartrate' || 'resting_heart_rate' => MetricType.restingHeartRate,
      'sleepscore' || 'sleep_score' => MetricType.sleepScore,
      _ => throw ArgumentError(
          'Unknown providerRecordType: $type',
        ),
    };
  }
}
