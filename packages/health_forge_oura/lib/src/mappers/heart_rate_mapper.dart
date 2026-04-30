import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/models/oura_heart_rate_response.dart';

/// Maps Oura API heart rate data to [HeartRateSample] models.
class HeartRateMapper {
  const HeartRateMapper._();

  /// Converts heart rate response data to [HeartRateSample] records.
  static List<HeartRateSample> map(OuraHeartRateResponse response) {
    return response.data.map(_mapOne).toList();
  }

  static HeartRateSample _mapOne(OuraHeartRateData data) {
    final timestamp = DateTime.parse(data.timestamp);

    return HeartRateSample(
      id: IdGenerator.generate(),
      provider: DataProvider.oura,
      providerRecordType: 'heartrate',
      providerRecordId: data.timestamp,
      startTime: timestamp,
      endTime: timestamp,
      capturedAt: DateTime.now(),
      beatsPerMinute: data.bpm,
      context: data.source,
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.ouraring.oura',
      ),
    );
  }
}
