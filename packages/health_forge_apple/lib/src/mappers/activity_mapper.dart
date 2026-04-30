import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Maps Apple HealthKit activity-related data points to core record types.
class ActivityMapper {
  const ActivityMapper._();

  /// Converts a [HealthDataRecord] to the appropriate activity record type.
  static HealthRecordMixin map(HealthDataRecord record) {
    final id = record.uuid.isEmpty ? IdGenerator.generate() : record.uuid;
    final capturedAt = DateTime.now();
    final provenance = Provenance(
      dataOrigin: DataOrigin.native_,
      sourceDevice: DeviceInfo(
        model: record.deviceModel,
        manufacturer: record.sourceName,
      ),
      sourceApp: record.sourceId,
    );

    return switch (record.type) {
      'STEPS' => StepCount(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          count: record.value.toInt(),
          provenance: provenance,
        ),
      'ACTIVE_ENERGY_BURNED' => CaloriesBurned(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          totalCalories: record.value,
          provenance: provenance,
        ),
      'DISTANCE_WALKING_RUNNING' => DistanceSample(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          distanceMeters: record.value,
          provenance: provenance,
        ),
      'WORKOUT' => ActivitySession(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          activityType: MetricType.workout,
          activityName: record.workoutActivityType,
          provenance: provenance,
        ),
      _ => throw ArgumentError('Unsupported type: ${record.type}'),
    };
  }
}
