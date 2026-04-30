import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/models/oura_daily_spo2_response.dart';

/// Maps Oura API daily SpO2 data to [BloodOxygenSample] models.
class Spo2Mapper {
  const Spo2Mapper._();

  /// Converts daily SpO2 data to [BloodOxygenSample] records.
  static List<BloodOxygenSample> map(OuraDailySpo2Response response) {
    return response.data
        .where(
          (d) => d.spo2Percentage?.average != null,
        )
        .map(_mapOne)
        .toList();
  }

  static BloodOxygenSample _mapOne(OuraDailySpo2Data data) {
    final day = DateTime.parse('${data.day}T00:00:00Z');

    return BloodOxygenSample(
      id: IdGenerator.generate(),
      provider: DataProvider.oura,
      providerRecordType: 'daily_spo2',
      providerRecordId: data.id,
      startTime: day,
      endTime: day.add(const Duration(days: 1)),
      capturedAt: DateTime.now(),
      percentage: data.spo2Percentage!.average!,
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.ouraring.oura',
      ),
    );
  }
}
