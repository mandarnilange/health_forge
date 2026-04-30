import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';

/// Maps Health Connect heart-rate-related data points to core record types.
class HeartRateMapper {
  const HeartRateMapper._();

  /// Converts a [HealthDataRecord] to the appropriate heart rate record type.
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
      'HEART_RATE' => HeartRateSample(
          id: id,
          provider: DataProvider.googleHealthConnect,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          beatsPerMinute: record.value.round(),
          provenance: provenance,
        ),
      'HEART_RATE_VARIABILITY_SDNN' => HeartRateVariability(
          id: id,
          provider: DataProvider.googleHealthConnect,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          sdnnMilliseconds: record.value,
          provenance: provenance,
        ),
      'RESTING_HEART_RATE' => RestingHeartRate(
          id: id,
          provider: DataProvider.googleHealthConnect,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          beatsPerMinute: record.value.round(),
          provenance: provenance,
        ),
      _ => throw ArgumentError('Unsupported type: ${record.type}'),
    };
  }
}
