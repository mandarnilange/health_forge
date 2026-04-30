import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';

/// Maps Health Connect activity-related data points to core record types.
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
          provider: DataProvider.googleHealthConnect,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          count: record.value.round(),
          provenance: provenance,
        ),
      'TOTAL_CALORIES_BURNED' => CaloriesBurned(
          id: id,
          provider: DataProvider.googleHealthConnect,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          totalCalories: record.value,
          provenance: provenance,
        ),
      'DISTANCE_DELTA' => DistanceSample(
          id: id,
          provider: DataProvider.googleHealthConnect,
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
          provider: DataProvider.googleHealthConnect,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          activityType: MetricType.workout,
          provenance: provenance,
        ),
      _ => throw ArgumentError('Unsupported type: ${record.type}'),
    };
  }
}
