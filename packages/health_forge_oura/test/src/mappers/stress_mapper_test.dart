import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/mappers/stress_mapper.dart';
import 'package:health_forge_oura/src/models/oura_daily_stress_response.dart';

void main() {
  group('StressMapper', () {
    late OuraDailyStressResponse response;

    setUp(() {
      response = const OuraDailyStressResponse(
        data: [
          OuraDailyStressData(
            id: 'st_001',
            day: '2024-01-15',
            stressHigh: 3600,
            recoveryHigh: 7200,
            daySummary: 'restored',
          ),
        ],
      );
    });

    test('maps stress score from stress_high seconds', () {
      final scores = StressMapper.map(response);
      expect(scores, hasLength(1));

      final score = scores.first;
      expect(score.provider, DataProvider.oura);
      expect(score.providerRecordType, 'daily_stress');
      expect(score.score, 3600);
      expect(score.level, 'restored');
    });

    test('handles empty response', () {
      final scores = StressMapper.map(
        const OuraDailyStressResponse(data: []),
      );
      expect(scores, isEmpty);
    });
  });
}
