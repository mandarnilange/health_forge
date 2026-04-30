import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/mappers/sleep_score_mapper.dart';
import 'package:health_forge_oura/src/models/oura_daily_sleep_response.dart';

void main() {
  group('SleepScoreMapper', () {
    late OuraDailySleepResponse response;

    setUp(() {
      response = const OuraDailySleepResponse(
        data: [
          OuraDailySleepData(
            id: 'ds_001',
            day: '2024-01-15',
            score: 85,
            contributors: {
              'deep_sleep': 90,
              'efficiency': 88,
            },
            timestamp: '2024-01-15T00:00:00+00:00',
          ),
        ],
      );
    });

    test('maps basic fields', () {
      final scores = SleepScoreMapper.map(response);
      expect(scores, hasLength(1));

      final score = scores.first;
      expect(score.provider, DataProvider.oura);
      expect(score.providerRecordType, 'daily_sleep');
      expect(score.score, 85);
    });

    test('maps day to start and end times', () {
      final score = SleepScoreMapper.map(response).first;
      expect(score.startTime, DateTime.utc(2024, 1, 15));
      expect(score.endTime, DateTime.utc(2024, 1, 16));
    });

    test('handles empty response', () {
      final scores = SleepScoreMapper.map(
        const OuraDailySleepResponse(data: []),
      );
      expect(scores, isEmpty);
    });
  });
}
