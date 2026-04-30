import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/mappers/sleep_mapper.dart';
import 'package:health_forge_oura/src/models/oura_sleep_response.dart';

void main() {
  group('SleepMapper', () {
    late OuraSleepResponse response;

    setUp(() {
      response = const OuraSleepResponse(
        data: [
          OuraSleepData(
            id: 'sleep_001',
            bedtimeStart: '2024-01-15T22:30:00+00:00',
            bedtimeEnd: '2024-01-16T06:45:00+00:00',
            totalSleepDuration: 27000,
            remSleepDuration: 7200,
            deepSleepDuration: 5400,
            lightSleepDuration: 14400,
            efficiency: 92,
            sleepPhase5Min: '42131',
          ),
        ],
      );
    });

    test('maps basic sleep session fields', () {
      final sessions = SleepMapper.map(response);
      expect(sessions, hasLength(1));

      final session = sessions.first;
      expect(session.provider, DataProvider.oura);
      expect(session.providerRecordType, 'sleep');
      expect(session.startTime, DateTime.parse('2024-01-15T22:30:00+00:00'));
      expect(session.endTime, DateTime.parse('2024-01-16T06:45:00+00:00'));
    });

    test('maps sleep durations to minutes', () {
      final session = SleepMapper.map(response).first;
      expect(session.totalSleepMinutes, 450); // 27000 / 60
      expect(session.remMinutes, 120); // 7200 / 60
      expect(session.deepMinutes, 90); // 5400 / 60
      expect(session.lightMinutes, 240); // 14400 / 60
    });

    test('maps efficiency', () {
      final session = SleepMapper.map(response).first;
      expect(session.efficiency, 92);
    });

    test('parses hypnogram into sleep stages', () {
      final session = SleepMapper.map(response).first;
      // '42131' = [awake, light, deep, rem, deep]
      expect(session.stages, hasLength(5));
      expect(session.stages[0].stage, SleepStage.awake);
      expect(session.stages[1].stage, SleepStage.light);
      expect(session.stages[2].stage, SleepStage.deep);
      expect(session.stages[3].stage, SleepStage.rem);
      expect(session.stages[4].stage, SleepStage.deep);
    });

    test('each stage spans 5 minutes', () {
      final session = SleepMapper.map(response).first;
      final first = session.stages.first;
      expect(
        first.endTime.difference(first.startTime),
        const Duration(minutes: 5),
      );
    });

    test('handles empty response', () {
      final sessions = SleepMapper.map(
        const OuraSleepResponse(data: []),
      );
      expect(sessions, isEmpty);
    });

    test('handles null hypnogram', () {
      response = const OuraSleepResponse(
        data: [
          OuraSleepData(
            id: 'sleep_002',
            bedtimeStart: '2024-01-15T22:30:00+00:00',
            bedtimeEnd: '2024-01-16T06:45:00+00:00',
          ),
        ],
      );
      final session = SleepMapper.map(response).first;
      expect(session.stages, isEmpty);
    });

    test('generates unique IDs', () {
      response = const OuraSleepResponse(
        data: [
          OuraSleepData(
            id: 's1',
            bedtimeStart: '2024-01-15T22:30:00+00:00',
            bedtimeEnd: '2024-01-16T06:45:00+00:00',
          ),
          OuraSleepData(
            id: 's2',
            bedtimeStart: '2024-01-16T22:30:00+00:00',
            bedtimeEnd: '2024-01-17T06:45:00+00:00',
          ),
        ],
      );
      final sessions = SleepMapper.map(response);
      expect(sessions[0].id, isNot(sessions[1].id));
    });
  });
}
