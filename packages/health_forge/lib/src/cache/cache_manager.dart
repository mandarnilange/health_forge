import 'package:health_forge_core/health_forge_core.dart';

/// Resolves [MetricType] from a record's concrete type, falling back to
/// [HealthRecordMixin.providerRecordType] string matching for mocks or
/// unknown subtypes.
///
/// Shared logic used by both [InMemoryCacheManager] and DriftCacheManager.
MetricType? metricTypeForRecord(HealthRecordMixin record) {
  // Primary: exhaustive type matching on core record classes.
  final byType = switch (record) {
    HeartRateSample() => MetricType.heartRate,
    RestingHeartRate() => MetricType.restingHeartRate,
    HeartRateVariability() => MetricType.hrv,
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
    _ => null,
  };
  if (byType != null) return byType;

  // Fallback: string-based matching for mocks and forward-compatibility.
  return _providerRecordTypeToMetric[record.providerRecordType.toLowerCase()];
}

const _providerRecordTypeToMetric = <String, MetricType>{
  'heart_rate': MetricType.heartRate,
  'heartrate': MetricType.heartRate,
  'hrv': MetricType.hrv,
  'heart_rate_variability': MetricType.hrv,
  'sleep_session': MetricType.sleepSession,
  'sleep': MetricType.sleepSession,
  'steps': MetricType.steps,
  'step_count': MetricType.steps,
  'weight': MetricType.weight,
  'body_fat': MetricType.bodyFat,
  'blood_pressure': MetricType.bloodPressure,
  'blood_glucose': MetricType.bloodGlucose,
  'calories': MetricType.calories,
  'calories_burned': MetricType.calories,
  'distance': MetricType.distance,
  'distance_sample': MetricType.distance,
  'elevation': MetricType.elevation,
  'elevation_gain': MetricType.elevation,
  'workout': MetricType.workout,
  'activity_session': MetricType.workout,
  'readiness': MetricType.readiness,
  'readiness_score': MetricType.readiness,
  'stress': MetricType.stress,
  'stress_score': MetricType.stress,
  'recovery': MetricType.recovery,
  'recovery_metric': MetricType.recovery,
  'blood_oxygen': MetricType.bloodOxygen,
  'respiratory_rate': MetricType.respiratoryRate,
  'resting_heart_rate': MetricType.restingHeartRate,
  'sleep_score': MetricType.sleepScore,
};

/// Abstract interface for caching health records.
abstract class CacheManager {
  /// Stores [records] in the cache.
  Future<void> put(List<HealthRecordMixin> records);

  /// Retrieves cached records matching the given filters.
  Future<List<HealthRecordMixin>> get({
    required MetricType metric,
    required TimeRange range,
    DataProvider? provider,
  });

  /// Invalidates cached records matching the given filters.
  ///
  /// When [range] is provided, only records overlapping that time window
  /// are removed, preventing unintended data loss outside the range.
  Future<void> invalidate({
    DataProvider? provider,
    MetricType? metric,
    TimeRange? range,
  });

  /// Clears all cached records and metadata.
  Future<void> clear();

  /// Returns the last sync time for a provider/metric pair.
  Future<DateTime?> lastSyncTime(DataProvider provider, MetricType metric);

  /// Updates sync metadata for a provider/metric pair.
  Future<void> updateSyncMetadata(
    DataProvider provider,
    MetricType metric, {
    DateTime? lastSync,
    String? cursor,
  });
}

/// In-memory implementation of [CacheManager].
class InMemoryCacheManager implements CacheManager {
  final List<HealthRecordMixin> _records = [];
  final Map<String, DateTime> _lastSyncTimes = {};
  final Map<String, String> _cursors = {};

  static String _metaKey(DataProvider provider, MetricType metric) =>
      '${provider.name}_${metric.name}';

  @override
  Future<void> put(List<HealthRecordMixin> records) async {
    _records.addAll(records);
  }

  @override
  Future<List<HealthRecordMixin>> get({
    required MetricType metric,
    required TimeRange range,
    DataProvider? provider,
  }) async {
    return _records.where((r) {
      if (metricTypeForRecord(r) != metric) return false;
      if (provider != null && r.provider != provider) return false;
      if (r.startTime.isAfter(range.end) || r.endTime.isBefore(range.start)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> invalidate({
    DataProvider? provider,
    MetricType? metric,
    TimeRange? range,
  }) async {
    _records.removeWhere((r) {
      if (provider != null && r.provider != provider) return false;
      if (metric != null && metricTypeForRecord(r) != metric) {
        return false;
      }
      if (range != null) {
        if (r.startTime.isAfter(range.end) || r.endTime.isBefore(range.start)) {
          return false;
        }
      }
      return true;
    });
  }

  @override
  Future<void> clear() async {
    _records.clear();
    _lastSyncTimes.clear();
    _cursors.clear();
  }

  @override
  Future<DateTime?> lastSyncTime(
    DataProvider provider,
    MetricType metric,
  ) async {
    return _lastSyncTimes[_metaKey(provider, metric)];
  }

  @override
  Future<void> updateSyncMetadata(
    DataProvider provider,
    MetricType metric, {
    DateTime? lastSync,
    String? cursor,
  }) async {
    final key = _metaKey(provider, metric);
    if (lastSync != null) _lastSyncTimes[key] = lastSync;
    if (cursor != null) _cursors[key] = cursor;
  }

  /// Returns the sync cursor for a provider/metric pair.
  Future<String?> getSyncCursor(
    DataProvider provider,
    MetricType metric,
  ) async {
    return _cursors[_metaKey(provider, metric)];
  }
}
