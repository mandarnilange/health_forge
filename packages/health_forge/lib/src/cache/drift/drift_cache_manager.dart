import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:health_forge/src/cache/cache_manager.dart';
import 'package:health_forge/src/cache/drift/health_cache_database.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// A function that deserializes a JSON map into a [HealthRecordMixin].
typedef RecordDeserializer = HealthRecordMixin Function(
  Map<String, dynamic> json,
);

/// Persistent [CacheManager] implementation backed by a Drift database.
///
/// Records are stored as JSON blobs with indexed metadata columns for
/// efficient querying by provider, metric type, and time range.
///
/// ```dart
/// import 'package:drift/native.dart';
///
/// final db = HealthCacheDatabase(NativeDatabase.createInBackground(file));
/// final cache = DriftCacheManager(database: db);
/// final forge = HealthForgeClient(cache: cache);
/// ```
class DriftCacheManager implements CacheManager {
  /// Creates a [DriftCacheManager] with the given [database].
  DriftCacheManager({required HealthCacheDatabase database}) : _db = database;

  final HealthCacheDatabase _db;

  // Maps core record class names → MetricType for put().
  // Keyed on class name (via _typeName) rather than provider-specific strings
  // to avoid misclassification when providers use non-standard type names.
  static final _recordToMetric = <String, MetricType>{
    'HeartRateSample': MetricType.heartRate,
    'RestingHeartRate': MetricType.restingHeartRate,
    'HeartRateVariability': MetricType.hrv,
    'StepCount': MetricType.steps,
    'CaloriesBurned': MetricType.calories,
    'DistanceSample': MetricType.distance,
    'ElevationGain': MetricType.elevation,
    'ActivitySession': MetricType.workout,
    'WorkoutRoute': MetricType.workout,
    'SleepSession': MetricType.sleepSession,
    'SleepStageSegment': MetricType.sleepSession,
    'SleepScore': MetricType.sleepScore,
    'ReadinessScore': MetricType.readiness,
    'StressScore': MetricType.stress,
    'RecoveryMetric': MetricType.recovery,
    'BloodOxygenSample': MetricType.bloodOxygen,
    'RespiratoryRate': MetricType.respiratoryRate,
    'Weight': MetricType.weight,
    'BodyFat': MetricType.bodyFat,
    'BloodPressure': MetricType.bloodPressure,
    'BloodGlucose': MetricType.bloodGlucose,
  };

  // Built-in fromJson factories for all 19 core record types.
  static final _defaultDeserializers = <String, RecordDeserializer>{
    'HeartRateSample': HeartRateSample.fromJson,
    'RestingHeartRate': RestingHeartRate.fromJson,
    'HeartRateVariability': HeartRateVariability.fromJson,
    'StepCount': StepCount.fromJson,
    'CaloriesBurned': CaloriesBurned.fromJson,
    'DistanceSample': DistanceSample.fromJson,
    'ElevationGain': ElevationGain.fromJson,
    'ActivitySession': ActivitySession.fromJson,
    'WorkoutRoute': WorkoutRoute.fromJson,
    'SleepSession': SleepSession.fromJson,
    'SleepScore': SleepScore.fromJson,
    'ReadinessScore': ReadinessScore.fromJson,
    'StressScore': StressScore.fromJson,
    'RecoveryMetric': RecoveryMetric.fromJson,
    'BloodOxygenSample': BloodOxygenSample.fromJson,
    'RespiratoryRate': RespiratoryRate.fromJson,
    'Weight': Weight.fromJson,
    'BodyFat': BodyFat.fromJson,
    'BloodPressure': BloodPressure.fromJson,
    'BloodGlucose': BloodGlucose.fromJson,
  };

  /// Resolves the public class name for a freezed record.
  ///
  /// Freezed generates implementation classes like `_$HeartRateSampleImpl`.
  /// This extracts the base name (e.g. "HeartRateSample").
  static String _typeName(HealthRecordMixin record) {
    final name = record.runtimeType.toString();
    // Freezed _$XImpl → X
    if (name.startsWith(r'_$')) {
      return name.substring(2).replaceAll('Impl', '');
    }
    // Freezed _X → X
    if (name.startsWith('_')) {
      return name.substring(1);
    }
    return name;
  }

  /// Extracts the source device identifier from a record's provenance.
  ///
  /// Returns the device model string if available, otherwise an empty string.
  /// This is used as part of the natural dedup key.
  static String _deviceId(HealthRecordMixin record) {
    final device = record.provenance?.sourceDevice;
    if (device == null) return '';
    // Combine manufacturer + model for a meaningful device key.
    final parts = [
      if (device.manufacturer != null) device.manufacturer!,
      if (device.model != null) device.model!,
    ];
    return parts.isEmpty ? '' : parts.join(':');
  }

  @override
  Future<void> put(List<HealthRecordMixin> records) async {
    await _db.batch((batch) {
      for (final record in records) {
        final typeName = _typeName(record);
        final metricType = _recordToMetric[typeName];
        if (metricType == null) continue;

        final json = (record as dynamic).toJson() as Map<String, dynamic>;
        json['_recordTypeName'] = typeName;

        final deviceId = _deviceId(record);

        batch.insert(
          _db.cachedRecords,
          CachedRecordsCompanion.insert(
            recordId: record.id,
            providerRecordId: Value(record.providerRecordId),
            provider: record.provider.name,
            metricType: metricType.name,
            recordType: typeName,
            startTime: record.startTime,
            endTime: record.endTime,
            sourceDeviceId: Value(deviceId),
            cachedAt: record.capturedAt,
            jsonPayload: jsonEncode(json),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<List<HealthRecordMixin>> get({
    required MetricType metric,
    required TimeRange range,
    DataProvider? provider,
  }) async {
    final query = _db.select(_db.cachedRecords)
      ..where(
        (r) =>
            r.metricType.equals(metric.name) &
            r.startTime.isSmallerOrEqualValue(range.end) &
            r.endTime.isBiggerOrEqualValue(range.start),
      );

    if (provider != null) {
      query.where((r) => r.provider.equals(provider.name));
    }

    final rows = await query.get();
    final records = <HealthRecordMixin>[];

    for (final row in rows) {
      final json = jsonDecode(row.jsonPayload) as Map<String, dynamic>;
      final typeName = json.remove('_recordTypeName') as String?;
      if (typeName == null) continue;

      final deserializer = _defaultDeserializers[typeName];
      if (deserializer == null) continue;

      try {
        records.add(deserializer(json));
      } on Object catch (e, st) {
        developer.log(
          'Failed to deserialize cached $typeName record',
          name: 'DriftCacheManager',
          error: e,
          stackTrace: st,
        );
      }
    }

    return records;
  }

  @override
  Future<void> invalidate({
    DataProvider? provider,
    MetricType? metric,
    TimeRange? range,
  }) async {
    if (provider == null && metric == null && range == null) {
      await _db.delete(_db.cachedRecords).go();
      return;
    }

    final stmt = _db.delete(_db.cachedRecords);

    if (provider != null) {
      stmt.where((r) => r.provider.equals(provider.name));
    }

    if (metric != null) {
      stmt.where((r) => r.metricType.equals(metric.name));
    }

    if (range != null) {
      stmt.where(
        (r) =>
            r.startTime.isSmallerOrEqualValue(range.end) &
            r.endTime.isBiggerOrEqualValue(range.start),
      );
    }

    await stmt.go();
  }

  @override
  Future<void> clear() async {
    await _db.delete(_db.cachedRecords).go();
    await _db.delete(_db.syncMetadata).go();
  }

  @override
  Future<DateTime?> lastSyncTime(
    DataProvider provider,
    MetricType metric,
  ) async {
    final query = _db.select(_db.syncMetadata)
      ..where(
        (s) =>
            s.provider.equals(provider.name) & s.metricType.equals(metric.name),
      );
    final row = await query.getSingleOrNull();
    return row?.lastSyncTime;
  }

  @override
  Future<void> updateSyncMetadata(
    DataProvider provider,
    MetricType metric, {
    DateTime? lastSync,
    String? cursor,
  }) async {
    await _db.into(_db.syncMetadata).insertOnConflictUpdate(
          SyncMetadataCompanion.insert(
            provider: provider.name,
            metricType: metric.name,
            lastSyncTime: Value(lastSync),
            cursor: Value(cursor),
          ),
        );
  }

  /// Retrieves the sync cursor for a provider/metric pair.
  Future<String?> getSyncCursor(
    DataProvider provider,
    MetricType metric,
  ) async {
    final query = _db.select(_db.syncMetadata)
      ..where(
        (s) =>
            s.provider.equals(provider.name) & s.metricType.equals(metric.name),
      );
    final row = await query.getSingleOrNull();
    return row?.cursor;
  }

  /// Closes the underlying database connection.
  Future<void> close() => _db.close();
}
