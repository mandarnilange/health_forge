import 'package:health/health.dart';
import 'package:health_forge_apple/src/apple_capabilities.dart';
import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_apple/src/mappers/activity_mapper.dart';
import 'package:health_forge_apple/src/mappers/body_mapper.dart';
import 'package:health_forge_apple/src/mappers/heart_rate_mapper.dart';
import 'package:health_forge_apple/src/mappers/respiratory_mapper.dart';
import 'package:health_forge_apple/src/mappers/sleep_mapper.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Apple HealthKit adapter implementing [HealthProvider].
class AppleHealthProvider implements HealthProvider {
  /// Creates an Apple HealthKit provider.
  ///
  /// An optional [healthPlugin] can be injected for testing.
  AppleHealthProvider({Health? healthPlugin})
      : _health = healthPlugin ?? Health();

  final Health _health;

  static const _metricToHealthTypes = <MetricType, List<HealthDataType>>{
    MetricType.heartRate: [HealthDataType.HEART_RATE],
    MetricType.hrv: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
    MetricType.restingHeartRate: [HealthDataType.RESTING_HEART_RATE],
    MetricType.steps: [HealthDataType.STEPS],
    MetricType.calories: [HealthDataType.ACTIVE_ENERGY_BURNED],
    MetricType.distance: [HealthDataType.DISTANCE_WALKING_RUNNING],
    MetricType.workout: [HealthDataType.WORKOUT],
    MetricType.sleepSession: [
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
    ],
    MetricType.weight: [HealthDataType.WEIGHT],
    MetricType.bodyFat: [HealthDataType.BODY_FAT_PERCENTAGE],
    MetricType.bloodPressure: [
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    ],
    MetricType.bloodGlucose: [HealthDataType.BLOOD_GLUCOSE],
    MetricType.bloodOxygen: [HealthDataType.BLOOD_OXYGEN],
    MetricType.respiratoryRate: [HealthDataType.RESPIRATORY_RATE],
  };

  @override
  DataProvider get providerType => DataProvider.apple;

  @override
  String get displayName => 'Apple HealthKit';

  @override
  ProviderCapabilities get capabilities => AppleCapabilities.capabilities;

  @override
  Future<bool> isAuthorized() async {
    final types = _metricToHealthTypes.values.expand((t) => t).toList();
    final result = await _health.hasPermissions(types);
    return result ?? false;
  }

  @override
  Future<AuthResult> authorize() async {
    try {
      final types = _metricToHealthTypes.values.expand((t) => t).toList();
      final granted = await _health.requestAuthorization(types);
      return granted ? AuthResult.success() : AuthResult.denied();
    } on Exception catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  @override
  Future<void> deauthorize() async {
    // HealthKit does not support programmatic deauthorization.
  }

  @override
  Future<List<HealthRecordMixin>> fetchRecords({
    required MetricType metricType,
    required TimeRange timeRange,
  }) async {
    final types = _metricToHealthTypes[metricType];
    if (types == null) {
      return [];
    }

    final dataPoints = await _health.getHealthDataFromTypes(
      types: types,
      startTime: timeRange.start,
      endTime: timeRange.end,
    );

    if (metricType == MetricType.bloodPressure) {
      return _mapBloodPressurePoints(dataPoints);
    }

    if (metricType == MetricType.sleepSession) {
      return _mapSleepPoints(dataPoints);
    }

    return dataPoints
        .map(_toHealthDataRecord)
        .map((r) => _mapRecord(r, metricType))
        .toList();
  }

  static HealthDataRecord _toHealthDataRecord(HealthDataPoint point) {
    double value;
    String? workoutActivityType;

    final healthValue = point.value;
    if (healthValue is NumericHealthValue) {
      value = healthValue.numericValue.toDouble();
    } else if (healthValue is WorkoutHealthValue) {
      value = 0;
      workoutActivityType = healthValue.workoutActivityType.name;
    } else {
      value = 0;
    }

    return HealthDataRecord(
      type: point.type.name,
      value: value,
      dateFrom: point.dateFrom,
      dateTo: point.dateTo,
      sourceName: point.sourceName,
      sourceId: point.sourceId,
      uuid: point.uuid,
      workoutActivityType: workoutActivityType,
      sourceDeviceId: point.sourceDeviceId,
      deviceModel: point.deviceModel,
      recordingMethod: point.recordingMethod.name,
      metadata: point.metadata,
    );
  }

  static HealthRecordMixin _mapRecord(
    HealthDataRecord record,
    MetricType metricType,
  ) {
    return switch (metricType) {
      MetricType.heartRate ||
      MetricType.hrv ||
      MetricType.restingHeartRate =>
        HeartRateMapper.map(record),
      MetricType.steps ||
      MetricType.calories ||
      MetricType.distance ||
      MetricType.workout =>
        ActivityMapper.map(record),
      MetricType.sleepSession => SleepMapper.map(record),
      MetricType.weight ||
      MetricType.bodyFat ||
      MetricType.bloodGlucose =>
        BodyMapper.map(record),
      MetricType.bloodOxygen ||
      MetricType.respiratoryRate =>
        RespiratoryMapper.map(record),
      _ => throw ArgumentError('Unsupported metric: $metricType'),
    };
  }

  /// Aggregates sleep stage data points into sessions grouped by source.
  List<HealthRecordMixin> _mapSleepPoints(List<HealthDataPoint> dataPoints) {
    final records = dataPoints.map(_toHealthDataRecord).toList();
    return SleepMapper.mapAll(records);
  }

  /// Pairs systolic and diastolic readings by matching timestamps.
  List<HealthRecordMixin> _mapBloodPressurePoints(
    List<HealthDataPoint> dataPoints,
  ) {
    final systolicPoints = <DateTime, HealthDataPoint>{};
    final diastolicPoints = <DateTime, HealthDataPoint>{};

    for (final point in dataPoints) {
      if (point.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
        systolicPoints[point.dateFrom] = point;
      } else if (point.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
        diastolicPoints[point.dateFrom] = point;
      }
    }

    final results = <HealthRecordMixin>[];

    for (final entry in systolicPoints.entries) {
      final systolic = _toHealthDataRecord(entry.value);
      final diastolicPoint = diastolicPoints[entry.key];
      final diastolicValue = diastolicPoint != null
          ? (diastolicPoint.value as NumericHealthValue).numericValue.toDouble()
          : null;

      results.add(
        BodyMapper.map(
          HealthDataRecord(
            type: systolic.type,
            value: systolic.value,
            dateFrom: systolic.dateFrom,
            dateTo: systolic.dateTo,
            sourceName: systolic.sourceName,
            sourceId: systolic.sourceId,
            uuid: systolic.uuid,
            secondaryValue: diastolicValue,
            sourceDeviceId: systolic.sourceDeviceId,
            deviceModel: systolic.deviceModel,
            recordingMethod: systolic.recordingMethod,
            metadata: systolic.metadata,
          ),
        ),
      );
    }

    return results;
  }
}
