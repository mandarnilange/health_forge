import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/models/oura_daily_sleep_response.dart';

/// Maps Oura API daily sleep data to [SleepScore] models.
class SleepScoreMapper {
  const SleepScoreMapper._();

  /// Converts daily sleep data to [SleepScore] records.
  static List<SleepScore> map(OuraDailySleepResponse response) {
    return response.data.where((d) => d.score != null).map(_mapOne).toList();
  }

  static SleepScore _mapOne(OuraDailySleepData data) {
    final day = DateTime.parse('${data.day}T00:00:00Z');

    return SleepScore(
      id: IdGenerator.generate(),
      provider: DataProvider.oura,
      providerRecordType: 'daily_sleep',
      providerRecordId: data.id,
      startTime: day,
      endTime: day.add(const Duration(days: 1)),
      capturedAt: DateTime.now(),
      score: data.score!,
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.ouraring.oura',
      ),
    );
  }
}
