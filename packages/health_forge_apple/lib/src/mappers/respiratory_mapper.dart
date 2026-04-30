import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Maps Apple HealthKit respiratory data points to core record types.
class RespiratoryMapper {
  const RespiratoryMapper._();

  /// Converts a [HealthDataRecord] to the appropriate respiratory record type.
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
      'BLOOD_OXYGEN' => BloodOxygenSample(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          percentage: record.value,
          provenance: provenance,
        ),
      'RESPIRATORY_RATE' => RespiratoryRate(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          breathsPerMinute: record.value,
          provenance: provenance,
        ),
      _ => throw ArgumentError('Unsupported type: ${record.type}'),
    };
  }
}
