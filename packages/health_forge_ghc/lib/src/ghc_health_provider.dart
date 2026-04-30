import 'package:health/health.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/ghc_capabilities.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';
import 'package:health_forge_ghc/src/mappers/activity_mapper.dart';
import 'package:health_forge_ghc/src/mappers/body_mapper.dart';
import 'package:health_forge_ghc/src/mappers/heart_rate_mapper.dart';
import 'package:health_forge_ghc/src/mappers/respiratory_mapper.dart';
import 'package:health_forge_ghc/src/mappers/sleep_mapper.dart';

/// Google Health Connect adapter implementing [HealthProvider].
class GhcHealthProvider implements HealthProvider {
  /// Creates a Google Health Connect provider.
  ///
  /// An optional [healthPlugin] can be injected for testing.
  GhcHealthProvider({Health? healthPlugin})
      : _health = healthPlugin ?? Health();

  final Health _health;

  static const _metricToHealthTypes = <MetricType, List<HealthDataType>>{
    MetricType.heartRate: [HealthDataType.HEART_RATE],
    MetricType.hrv: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
    MetricType.restingHeartRate: [HealthDataType.RESTING_HEART_RATE],
    MetricType.steps: [HealthDataType.STEPS],
    MetricType.calories: [HealthDataType.TOTAL_CALORIES_BURNED],
    MetricType.distance: [HealthDataType.DISTANCE_DELTA],
    MetricType.workout: [HealthDataType.WORKOUT],
    MetricType.sleepSession: [
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
    ],
    MetricType.weight: [HealthDataType.WEIGHT],
    MetricType.bodyFat: [HealthDataType.BODY_FAT_PERCENTAGE],
    MetricType.bloodPressure: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
    MetricType.bloodGlucose: [HealthDataType.BLOOD_GLUCOSE],
    MetricType.bloodOxygen: [HealthDataType.BLOOD_OXYGEN],
    MetricType.respiratoryRate: [HealthDataType.RESPIRATORY_RATE],
  };

  @override
  DataProvider get providerType => DataProvider.googleHealthConnect;

  @override
  String get displayName => 'Google Health Connect';

  @override
  ProviderCapabilities get capabilities => GhcCapabilities.capabilities;

  @override
  Future<bool> isAuthorized() async {
    try {
      final types = _allHealthTypes();
      final permissions = types.map((_) => HealthDataAccess.READ).toList();
      final result = await _health.hasPermissions(
        types,
        permissions: permissions,
      );
      return result ?? false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<AuthResult> authorize() async {
    try {
      final types = _allHealthTypes();
      final permissions = types.map((_) => HealthDataAccess.READ).toList();
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      return granted ? AuthResult.success() : AuthResult.denied();
    } on Exception catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  @override
  Future<void> deauthorize() async {
    await _health.revokePermissions();
  }

  @override
  Future<List<HealthRecordMixin>> fetchRecords({
    required MetricType metricType,
    required TimeRange timeRange,
  }) async {
    final healthTypes = _metricToHealthTypes[metricType];
    if (healthTypes == null) return [];

    try {
      final dataPoints = await _health.getHealthDataFromTypes(
        types: healthTypes,
        startTime: timeRange.start,
        endTime: timeRange.end,
      );

      if (metricType == MetricType.sleepSession) {
        return _mapSleepPoints(dataPoints);
      }

      return dataPoints.map(_mapDataPoint).toList();
    } on Exception {
      return [];
    }
  }

  /// Aggregates sleep stage data points into sessions grouped by source.
  static List<HealthRecordMixin> _mapSleepPoints(
    List<HealthDataPoint> dataPoints,
  ) {
    final records = dataPoints.map((point) {
      final numericValue = point.value;
      final value = numericValue is NumericHealthValue
          ? numericValue.numericValue.toDouble()
          : 0.0;

      return HealthDataRecord(
        type: point.type.name,
        value: value,
        dateFrom: point.dateFrom,
        dateTo: point.dateTo,
        sourceName: point.sourceName,
        sourceId: point.sourceId,
        uuid: point.uuid,
        sourceDeviceId: point.sourceDeviceId,
        deviceModel: point.deviceModel,
        recordingMethod: point.recordingMethod.name,
        metadata: point.metadata,
      );
    }).toList();
    return SleepMapper.mapAll(records);
  }

  List<HealthDataType> _allHealthTypes() {
    return _metricToHealthTypes.values.expand((t) => t).toList();
  }

  static HealthRecordMixin _mapDataPoint(HealthDataPoint point) {
    final numericValue = point.value;
    final value = numericValue is NumericHealthValue
        ? numericValue.numericValue.toDouble()
        : 0.0;

    final record = HealthDataRecord(
      type: point.type.name,
      value: value,
      dateFrom: point.dateFrom,
      dateTo: point.dateTo,
      sourceName: point.sourceName,
      sourceId: point.sourceId,
      uuid: point.uuid,
      sourceDeviceId: point.sourceDeviceId,
      deviceModel: point.deviceModel,
      recordingMethod: point.recordingMethod.name,
      metadata: point.metadata,
    );

    final typeName = point.type.name;

    if (_heartRateTypes.contains(typeName)) {
      return HeartRateMapper.map(record);
    }
    if (_activityTypes.contains(typeName)) {
      return ActivityMapper.map(record);
    }
    if (_sleepTypes.contains(typeName)) {
      return SleepMapper.map(record);
    }
    if (_bodyTypes.contains(typeName)) {
      return BodyMapper.map(record);
    }
    if (_respiratoryTypes.contains(typeName)) {
      return RespiratoryMapper.map(record);
    }

    throw ArgumentError('Unsupported health data type: $typeName');
  }

  static const _heartRateTypes = {
    'HEART_RATE',
    'HEART_RATE_VARIABILITY_SDNN',
    'RESTING_HEART_RATE',
  };

  static const _activityTypes = {
    'STEPS',
    'TOTAL_CALORIES_BURNED',
    'DISTANCE_DELTA',
    'WORKOUT',
  };

  static const _sleepTypes = {
    'SLEEP_ASLEEP',
    'SLEEP_AWAKE',
    'SLEEP_DEEP',
    'SLEEP_LIGHT',
    'SLEEP_REM',
  };

  static const _bodyTypes = {
    'WEIGHT',
    'BODY_FAT_PERCENTAGE',
    'BLOOD_PRESSURE_SYSTOLIC',
    'BLOOD_GLUCOSE',
  };

  static const _respiratoryTypes = {
    'BLOOD_OXYGEN',
    'RESPIRATORY_RATE',
  };
}
