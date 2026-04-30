import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/models/oura_daily_stress_response.dart';

/// Maps Oura API daily stress data to [StressScore] models.
class StressMapper {
  const StressMapper._();

  /// Converts daily stress data to [StressScore] records.
  static List<StressScore> map(OuraDailyStressResponse response) {
    return response.data.map(_mapOne).toList();
  }

  static StressScore _mapOne(OuraDailyStressData data) {
    final day = DateTime.parse('${data.day}T00:00:00Z');

    return StressScore(
      id: IdGenerator.generate(),
      provider: DataProvider.oura,
      providerRecordType: 'daily_stress',
      providerRecordId: data.id,
      startTime: day,
      endTime: day.add(const Duration(days: 1)),
      capturedAt: DateTime.now(),
      score: data.stressHigh ?? 0,
      level: data.daySummary,
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.ouraring.oura',
      ),
    );
  }
}
