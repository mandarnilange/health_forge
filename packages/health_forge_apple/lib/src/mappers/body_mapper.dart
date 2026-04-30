import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Maps Apple HealthKit body-measurement data points to core record types.
class BodyMapper {
  const BodyMapper._();

  /// Converts a [HealthDataRecord] to the appropriate body measurement type.
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
      'WEIGHT' => Weight(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          kilograms: record.value,
          provenance: provenance,
        ),
      'BODY_FAT_PERCENTAGE' => BodyFat(
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
      'BLOOD_PRESSURE_SYSTOLIC' => BloodPressure(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          systolicMmHg: record.value.toInt(),
          diastolicMmHg: record.secondaryValue?.toInt() ?? 0,
          provenance: provenance,
        ),
      'BLOOD_GLUCOSE' => BloodGlucose(
          id: id,
          provider: DataProvider.apple,
          providerRecordType: record.type,
          providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
          startTime: record.dateFrom,
          endTime: record.dateTo,
          capturedAt: capturedAt,
          milligramsPerDeciliter: record.value,
          provenance: provenance,
        ),
      _ => throw ArgumentError('Unsupported type: ${record.type}'),
    };
  }
}
