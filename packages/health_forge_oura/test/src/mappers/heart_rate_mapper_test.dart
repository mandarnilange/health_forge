import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/mappers/heart_rate_mapper.dart';
import 'package:health_forge_oura/src/models/oura_heart_rate_response.dart';

void main() {
  group('HeartRateMapper', () {
    late OuraHeartRateResponse response;

    setUp(() {
      response = const OuraHeartRateResponse(
        data: [
          OuraHeartRateData(
            bpm: 72,
            source: 'awake',
            timestamp: '2024-01-15T10:30:00+00:00',
          ),
          OuraHeartRateData(
            bpm: 58,
            source: 'rest',
            timestamp: '2024-01-15T03:15:00+00:00',
          ),
        ],
      );
    });

    test('maps all heart rate samples', () {
      final samples = HeartRateMapper.map(response);
      expect(samples, hasLength(2));
    });

    test('maps bpm to beatsPerMinute', () {
      final sample = HeartRateMapper.map(response).first;
      expect(sample.beatsPerMinute, 72);
      expect(sample.provider, DataProvider.oura);
      expect(sample.providerRecordType, 'heartrate');
    });

    test('maps source to context', () {
      final sample = HeartRateMapper.map(response).first;
      expect(sample.context, 'awake');
    });

    test('sets start and end time to same timestamp', () {
      final sample = HeartRateMapper.map(response).first;
      expect(sample.startTime, sample.endTime);
    });

    test('handles empty response', () {
      final samples = HeartRateMapper.map(
        const OuraHeartRateResponse(data: []),
      );
      expect(samples, isEmpty);
    });
  });
}
