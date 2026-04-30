import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';
import 'package:health_forge_ghc/src/mappers/sleep_mapper.dart';

void main() {
  final bedtime = DateTime.utc(2026, 3, 16, 23);
  final wakeup = DateTime.utc(2026, 3, 17, 7);

  group('SleepMapper', () {
    group('map (single record)', () {
      test('maps SLEEP_ASLEEP to SleepSession', () {
        final record = HealthDataRecord(
          type: 'SLEEP_ASLEEP',
          value: 0,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
          uuid: 'sleep-uuid-1',
          deviceModel: 'Pixel Watch 2',
        );

        final result = SleepMapper.map(record);

        expect(result, isA<SleepSession>());
        final session = result as SleepSession;
        expect(session.provider, DataProvider.googleHealthConnect);
        expect(session.providerRecordType, 'SLEEP_ASLEEP');
        expect(session.startTime, bedtime);
        expect(session.endTime, wakeup);
        expect(session.id, 'sleep-uuid-1');
        expect(session.provenance, isNotNull);
        expect(session.provenance!.dataOrigin, DataOrigin.native_);
        expect(session.provenance!.sourceDevice?.model, 'Pixel Watch 2');
        expect(
          session.provenance!.sourceApp,
          'com.google.android.apps.fitness',
        );
      });

      test('uses uuid when provided', () {
        final record = HealthDataRecord(
          type: 'SLEEP_ASLEEP',
          value: 0,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'test',
          sourceId: 'test',
          uuid: 'sleep-uuid-1',
        );

        final result = SleepMapper.map(record) as SleepSession;
        expect(result.id, 'sleep-uuid-1');
      });

      test('maps SLEEP_AWAKE to SleepSession', () {
        final record = HealthDataRecord(
          type: 'SLEEP_AWAKE',
          value: 0,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'test',
          sourceId: 'test',
        );

        final result = SleepMapper.map(record);
        expect(result, isA<SleepSession>());
        expect(
          (result as SleepSession).providerRecordType,
          'SLEEP_AWAKE',
        );
      });

      test('maps SLEEP_DEEP to SleepSession', () {
        final record = HealthDataRecord(
          type: 'SLEEP_DEEP',
          value: 0,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'test',
          sourceId: 'test',
        );

        final result = SleepMapper.map(record);
        expect(result, isA<SleepSession>());
        expect(
          (result as SleepSession).providerRecordType,
          'SLEEP_DEEP',
        );
      });

      test('maps SLEEP_LIGHT to SleepSession', () {
        final record = HealthDataRecord(
          type: 'SLEEP_LIGHT',
          value: 0,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'test',
          sourceId: 'test',
        );

        final result = SleepMapper.map(record);
        expect(result, isA<SleepSession>());
        expect(
          (result as SleepSession).providerRecordType,
          'SLEEP_LIGHT',
        );
      });

      test('maps SLEEP_REM to SleepSession', () {
        final record = HealthDataRecord(
          type: 'SLEEP_REM',
          value: 0,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'test',
          sourceId: 'test',
        );

        final result = SleepMapper.map(record);
        expect(result, isA<SleepSession>());
        expect(
          (result as SleepSession).providerRecordType,
          'SLEEP_REM',
        );
      });

      test('throws for unsupported type', () {
        final record = HealthDataRecord(
          type: 'UNKNOWN_SLEEP',
          value: 0,
          dateFrom: bedtime,
          dateTo: wakeup,
          sourceName: 'test',
          sourceId: 'test',
        );

        expect(
          () => SleepMapper.map(record),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('mapAll (session aggregation)', () {
      test('groups stage records from same source into one session', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 16, 23, 30),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'light-1',
            deviceModel: 'Pixel Watch 2',
          ),
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23, 30),
            dateTo: DateTime.utc(2026, 3, 17, 0, 15),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'deep-1',
            deviceModel: 'Pixel Watch 2',
          ),
          HealthDataRecord(
            type: 'SLEEP_REM',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 17, 0, 15),
            dateTo: DateTime.utc(2026, 3, 17, 0, 40),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'rem-1',
            deviceModel: 'Pixel Watch 2',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        final session = sessions.first;
        expect(session.provider, DataProvider.googleHealthConnect);
        expect(session.startTime, DateTime.utc(2026, 3, 16, 23));
        expect(session.endTime, DateTime.utc(2026, 3, 17, 0, 40));
        expect(session.stages, hasLength(3));

        // Stages sorted by startTime
        expect(session.stages[0].stage, SleepStage.light);
        expect(session.stages[1].stage, SleepStage.deep);
        expect(session.stages[2].stage, SleepStage.rem);
      });

      test('calculates duration minutes from time ranges', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 16, 23, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'deep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23, 45),
            dateTo: DateTime.utc(2026, 3, 17, 0, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'light-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_REM',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 17, 0, 45),
            dateTo: DateTime.utc(2026, 3, 17, 1, 15),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'rem-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_AWAKE',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 17, 1, 15),
            dateTo: DateTime.utc(2026, 3, 17, 1, 25),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'awake-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        final session = sessions.first;
        expect(session.deepMinutes, 45);
        expect(session.lightMinutes, 60);
        expect(session.remMinutes, 30);
        expect(session.awakeMinutes, 10);
        expect(session.totalSleepMinutes, 135);
      });

      test('filters out ASLEEP from stage segments', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_ASLEEP',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 22, 30),
            dateTo: DateTime.utc(2026, 3, 17, 5, 30),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'asleep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 16, 23, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'deep-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        final session = sessions.first;
        // Only SLEEP_DEEP should appear as a stage
        expect(session.stages, hasLength(1));
        expect(session.stages.first.stage, SleepStage.deep);
        // Session envelope from ASLEEP
        expect(session.startTime, DateTime.utc(2026, 3, 16, 22, 30));
        expect(session.endTime, DateTime.utc(2026, 3, 17, 5, 30));
      });

      test('separates records from different sources', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 16, 23, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'deep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 17),
            sourceName: 'Samsung Health',
            sourceId: 'com.samsung.health',
            uuid: 'light-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(2));
      });

      test('deduplicates records with same type and time range', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 16, 23, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'deep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 16, 23, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'deep-1-dup',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23, 45),
            dateTo: DateTime.utc(2026, 3, 17, 0, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'light-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        final session = sessions.first;
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
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 16, 23, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'deep-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions, hasLength(1));
        expect(sessions.first.stages, hasLength(1));
        expect(sessions.first.stages.first.stage, SleepStage.deep);
        expect(sessions.first.deepMinutes, 45);
      });

      test('sets providerRecordType to SLEEP_SESSION', () {
        final records = [
          HealthDataRecord(
            type: 'SLEEP_DEEP',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23),
            dateTo: DateTime.utc(2026, 3, 16, 23, 45),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'deep-1',
          ),
          HealthDataRecord(
            type: 'SLEEP_LIGHT',
            value: 0,
            dateFrom: DateTime.utc(2026, 3, 16, 23, 45),
            dateTo: DateTime.utc(2026, 3, 17, 0, 15),
            sourceName: 'Pixel Watch',
            sourceId: 'com.google.android.apps.fitness',
            uuid: 'light-1',
          ),
        ];

        final sessions = SleepMapper.mapAll(records);

        expect(sessions.first.providerRecordType, 'SLEEP_SESSION');
      });
    });
  });
}
