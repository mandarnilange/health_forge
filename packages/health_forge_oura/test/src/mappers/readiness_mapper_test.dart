import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/mappers/readiness_mapper.dart';
import 'package:health_forge_oura/src/models/oura_daily_readiness_response.dart';

void main() {
  group('ReadinessMapper', () {
    late OuraDailyReadinessResponse response;

    setUp(() {
      response = const OuraDailyReadinessResponse(
        data: [
          OuraDailyReadinessData(
            id: 'r_001',
            day: '2024-01-15',
            score: 82,
            contributors: {
              'activity_balance': 85,
              'resting_heart_rate': 92,
            },
          ),
        ],
      );
    });

    test('maps readiness score', () {
      final scores = ReadinessMapper.map(response);
      expect(scores, hasLength(1));

      final score = scores.first;
      expect(score.provider, DataProvider.oura);
      expect(score.providerRecordType, 'daily_readiness');
      expect(score.score, 82);
    });

    test('maps contributors', () {
      final score = ReadinessMapper.map(response).first;
      expect(score.contributors, isNotNull);
      expect(score.contributors!['activity_balance'], 85);
    });

    test('handles empty response', () {
      final scores = ReadinessMapper.map(
        const OuraDailyReadinessResponse(data: []),
      );
      expect(scores, isEmpty);
    });

    test('skips entries with null score', () {
      response = const OuraDailyReadinessResponse(
        data: [
          OuraDailyReadinessData(
            id: 'r_002',
            day: '2024-01-15',
          ),
        ],
      );
      final scores = ReadinessMapper.map(response);
      expect(scores, isEmpty);
    });
  });
}
