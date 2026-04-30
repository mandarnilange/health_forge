import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Maps Apple HealthKit heart-rate-related data points to core record types.
class HeartRateMapper {
  const HeartRateMapper._();

  /// Converts a [HealthDataRecord] to the appropriate heart rate record type.
  static HealthRecordMixin map(HealthDataRecord record) {
    final id = record.uuid.isEmpty ? IdGenerator.generate() : record.uuid;
    final providerRecordId = record.uuid.isNotEmpty ? record.uuid : null;
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
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: providerRecordId,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          beatsPerMinute: record.value.toInt(),
          provenance: provenance,
        ),
      'HEART_RATE_VARIABILITY_SDNN' => HeartRateVariability(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: providerRecordId,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          sdnnMilliseconds: record.value,
          provenance: provenance,
        ),
      'RESTING_HEART_RATE' => RestingHeartRate(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: providerRecordId,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          beatsPerMinute: record.value.toInt(),
          provenance: provenance,
        ),
      _ => throw ArgumentError('Unsupported type: ${record.type}'),
    };
  }
}
