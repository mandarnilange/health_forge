import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_apple/src/mappers/sleep_mapper.dart';
import 'package:health_forge_core/health_forge_core.dart';

void main() {
  final bedtime = DateTime(2024, 6, 15, 22);
  final wakeup = DateTime(2024, 6, 16, 6);

  group('SleepMapper', () {
    group('map (single record)', () {
      test('maps SLEEP_IN_BED to SleepSession with unknown stage', () {
        final record = HealthDataRecord(
          type: 'SLEEP_IN_BED',
          value: 480,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'sleep-uuid-1',
          deviceModel: 'Apple Watch Series 9',
        );

        final result = SleepMapper.map(record);

        expect(result, isA<SleepSession>());
        final session = result as SleepSession;
        expect(session.provider, DataProvider.apple);
        expect(session.providerRecordType, 'SLEEP_IN_BED');
        expect(session.startTime, bedtime);
        expect(session.endTime, wakeup);
        expect(session.stages, hasLength(1));
        expect(session.stages.first.stage, SleepStage.unknown);
        expect(session.id, 'sleep-uuid-1');
        // totalSleepMinutes computed from time range
        expect(session.totalSleepMinutes, 480);
        expect(session.provenance, isNotNull);
        expect(session.provenance!.dataOrigin, DataOrigin.native_);
        expect(
          session.provenance!.sourceDevice?.model,
          'Apple Watch Series 9',
        );
        expect(session.provenance!.sourceDevice?.manufacturer, 'Apple Watch');
        expect(session.provenance!.sourceApp, 'com.apple.health');
      });

      test('maps SLEEP_DEEP to SleepSession with deep stage', () {
        final start = DateTime(2024, 6, 15, 23);
        final end = DateTime(2024, 6, 15, 23, 45);

        final record = HealthDataRecord(
          type: 'SLEEP_DEEP',
          value: 45,
          dateFrom: start,
          dateTo: end,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'sleep-deep-uuid',
        );

        final result = SleepMapper.map(record) as SleepSession;
        expect(result.stages.first.stage, SleepStage.deep);
      });

      test('maps SLEEP_REM to SleepSession with rem stage', () {
        final start = DateTime(2024, 6, 16, 2);
        final end = DateTime(2024, 6, 16, 2, 30);

        final record = HealthDataRecord(
          type: 'SLEEP_REM',
          value: 30,
          dateFrom: start,
          dateTo: end,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        final result = SleepMapper.map(record) as SleepSession;
        expect(result.stages.first.stage, SleepStage.rem);
      });

      test('maps SLEEP_LIGHT to SleepSession with light stage', () {
        final record = HealthDataRecord(
          type: 'SLEEP_LIGHT',
          value: 60,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        final result = SleepMapper.map(record) as SleepSession;
        expect(result.stages.first.stage, SleepStage.light);
      });

      test('maps SLEEP_AWAKE to SleepSession with awake stage', () {
        final record = HealthDataRecord(
          type: 'SLEEP_AWAKE',
          value: 10,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        final result = SleepMapper.map(record) as SleepSession;
        expect(result.stages.first.stage, SleepStage.awake);
      });

      test('maps SLEEP_ASLEEP to SleepSession with unknown stage', () {
        final record = HealthDataRecord(
          type: 'SLEEP_ASLEEP',
          value: 400,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        final result = SleepMapper.map(record) as SleepSession;
        expect(result.stages.first.stage, SleepStage.unknown);
      });

      test('computes totalSleepMinutes from time range', () {
        // 45 minutes between start and end
        final start = DateTime(2024, 6, 15, 23);
        final end = DateTime(2024, 6, 15, 23, 45);

        final record = HealthDataRecord(
          type: 'SLEEP_DEEP',
          value: 0, // value is irrelevant
          dateFrom: start,
          dateTo: end,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        final result = SleepMapper.map(record) as SleepSession;
        expect(result.totalSleepMinutes, 45);
      });

      test('throws ArgumentError for unsupported type', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 72,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        expect(() => SleepMapper.map(record), throwsArgumentError);
      });
    });

    group('mapAll (session aggregation)', () {
      test('groups stage records from same source into one session', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 22, 30),
            dateTo: DateTime(2024, 6, 15, 23),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'light-1',
            deviceModel: 'Apple Watch Series 9',
          ),
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-1',
            deviceModel: 'Apple Watch Series 9',
          ),
          HealthDataRecord(
            type: 'SLEEP_REM',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23, 45),
            dateTo: DateTime(2024, 6, 16, 0, 10),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'rem-1',
            deviceModel: 'Apple Watch Series 9',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        final session = sessions.first;
        expect(session.provider, DataProvider.apple);
        expect(session.startTime, DateTime(2024, 6, 15, 22, 30));
        expect(session.endTime, DateTime(2024, 6, 16, 0, 10));
        expect(session.stages, hasLength(3));

        // Stages should be sorted by startTime
        expect(session.stages[0].stage, SleepStage.light);
        expect(session.stages[1].stage, SleepStage.deep);
        expect(session.stages[2].stage, SleepStage.rem);
      });

      test('calculates duration minutes from time ranges', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23, 45),
            dateTo: DateTime(2024, 6, 16, 1, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'light-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_REM',
            value: 0,
            dateFrom: DateTime(2024, 6, 16, 1, 45),
            dateTo: DateTime(2024, 6, 16, 2, 15),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'rem-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_AWAKE',
            value: 0,
            dateFrom: DateTime(2024, 6, 16, 2, 15),
            dateTo: DateTime(2024, 6, 16, 2, 25),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'awake-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        final session = sessions.first;
        expect(session.deepMinutes, 45);
        expect(session.lightMinutes, 120);
        expect(session.remMinutes, 30);
        expect(session.awakeMinutes, 10);
        // totalSleepMinutes = deep + light + rem (excludes awake)
        expect(session.totalSleepMinutes, 195);
      });

      test('filters out IN_BED and ASLEEP from stage segments', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_IN_BED',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 22),
            dateTo: DateTime(2024, 6, 16, 6),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'inbed-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_ASLEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 22, 30),
            dateTo: DateTime(2024, 6, 16, 5, 30),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'asleep-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        final session = sessions.first;
        // Only SLEEP_DEEP should be in stages (IN_BED and ASLEEP are meta)
        expect(session.stages, hasLength(1));
        expect(session.stages.first.stage, SleepStage.deep);
        // Session time range should use IN_BED envelope
        expect(session.startTime, DateTime(2024, 6, 15, 22));
        expect(session.endTime, DateTime(2024, 6, 16, 6));
      });

      test('separates records from different sources into sessions', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-watch',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 16),
            sourceName: 'iPhone',
            sourceId: 'com.apple.health.iphone',
            uuid: 'light-phone',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(2));
      });

      test('deduplicates records with same type and time range', () {
        // Simulate duplicate records from synced devices within same source
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-1-dup',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23, 45),
            dateTo: DateTime(2024, 6, 16, 0, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'light-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        final session = sessions.first;
        // Deep should be counted only once (45 min, not 90)
        expect(session.deepMinutes, 45);
        expect(session.lightMinutes, 60);
        expect(session.totalSleepMinutes, 105);
        expect(session.stages, hasLength(2));
      });

      test('handles empty input', () {
        final sessions = SleepMapper.mapAll([]);
        expect(sessions, isEmpty);
      });

      test('handles single record', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        expect(sessions.first.stages, hasLength(1));
        expect(sessions.first.stages.first.stage, SleepStage.deep);
        expect(sessions.first.deepMinutes, 45);
      });

      test('sets provenance from first record in group', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-1',
            deviceModel: 'Apple Watch Series 9',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23, 45),
            dateTo: DateTime(2024, 6, 16, 0, 15),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'light-1',
            deviceModel: 'Apple Watch Series 9',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions.first.provenance, isNotNull);
        expect(sessions.first.provenance!.dataOrigin, DataOrigin.native_);
        expect(
          sessions.first.provenance!.sourceDevice?.model,
          'Apple Watch Series 9',
        );
        expect(sessions.first.provenance!.sourceApp, 'com.apple.health');
      });

      test('sets providerRecordType to SLEEP_SESSION for aggregated records',
          () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23),
            dateTo: DateTime(2024, 6, 15, 23, 45),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'deep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime(2024, 6, 15, 23, 45),
            dateTo: DateTime(2024, 6, 16, 0, 15),
            sourceName: 'Apple Watch',
            sourceId: 'com.apple.health',
            uuid: 'light-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions.first.providerRecordType, 'SLEEP_SESSION');
      });
    });
  });
}
