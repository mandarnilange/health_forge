import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/models/oura_daily_readiness_response.dart';

/// Maps Oura API daily readiness data to [ReadinessScore] models.
class ReadinessMapper {
  const ReadinessMapper._();

  /// Converts daily readiness data to [ReadinessScore] records.
  static List<ReadinessScore> map(OuraDailyReadinessResponse response) {
    return response.data.where((d) => d.score != null).map(_mapOne).toList();
  }

  static ReadinessScore _mapOne(OuraDailyReadinessData data) {
    final day = DateTime.parse('${data.day}T00:00:00Z');

    return ReadinessScore(
      id: IdGenerator.generate(),
      provider: DataProvider.oura,
      providerRecordType: 'daily_readiness',
      providerRecordId: data.id,
      startTime: day,
      endTime: day.add(const Duration(days: 1)),
      capturedAt: DateTime.now(),
      score: data.score!,
      contributors: data.contributors,
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.ouraring.oura',
      ),
    );
  }
}
