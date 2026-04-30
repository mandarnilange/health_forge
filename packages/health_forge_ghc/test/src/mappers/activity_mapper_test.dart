import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';
import 'package:health_forge_ghc/src/mappers/activity_mapper.dart';

void main() {
  final now = DateTime.utc(2026, 3, 17, 10);
  final later = DateTime.utc(2026, 3, 17, 11);

  group('ActivityMapper', () {
    group('STEPS', () {
      test('maps to StepCount', () {
        final record = HealthDataRecord(
          type: 'STEPS',
          value: 5000,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
          uuid: 'steps-uuid-1',
          deviceModel: 'Pixel Watch 2',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<StepCount>());
        final steps = result as StepCount;
        expect(steps.count, 5000);
        expect(steps.provider, DataProvider.googleHealthConnect);
        expect(steps.providerRecordType, 'STEPS');
        expect(steps.startTime, now);
        expect(steps.endTime, later);
        expect(steps.id, 'steps-uuid-1');
        expect(steps.provenance, isNotNull);
        expect(steps.provenance!.dataOrigin, DataOrigin.native_);
        expect(steps.provenance!.sourceDevice?.model, 'Pixel Watch 2');
        expect(steps.provenance!.sourceDevice?.manufacturer, 'Pixel Watch');
        expect(steps.provenance!.sourceApp, 'com.google.android.apps.fitness');
      });

      test('uses uuid when provided', () {
        final record = HealthDataRecord(
          type: 'STEPS',
          value: 100,
          dateFrom: now,
          dateTo: later,
          sourceName: 'test',
          sourceId: 'test',
          uuid: 'step-uuid-123',
        );

        final result = ActivityMapper.map(record) as StepCount;
        expect(result.id, 'step-uuid-123');
      });

      test('rounds fractional steps', () {
        final record = HealthDataRecord(
          type: 'STEPS',
          value: 5000.7,
          dateFrom: now,
          dateTo: later,
          sourceName: 'test',
          sourceId: 'test',
        );

        final result = ActivityMapper.map(record) as StepCount;
        expect(result.count, 5001);
      });
    });

    group('TOTAL_CALORIES_BURNED', () {
      test('maps to CaloriesBurned', () {
        final record = HealthDataRecord(
          type: 'TOTAL_CALORIES_BURNED',
          value: 350.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<CaloriesBurned>());
        final cal = result as CaloriesBurned;
        expect(cal.totalCalories, 350.5);
        expect(cal.provider, DataProvider.googleHealthConnect);
        expect(cal.providerRecordType, 'TOTAL_CALORIES_BURNED');
      });
    });

    group('DISTANCE_DELTA', () {
      test('maps to DistanceSample', () {
        final record = HealthDataRecord(
          type: 'DISTANCE_DELTA',
          value: 1500.25,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<DistanceSample>());
        final dist = result as DistanceSample;
        expect(dist.distanceMeters, 1500.25);
        expect(dist.provider, DataProvider.googleHealthConnect);
        expect(dist.providerRecordType, 'DISTANCE_DELTA');
      });
    });

    group('WORKOUT', () {
      test('maps to ActivitySession', () {
        final record = HealthDataRecord(
          type: 'WORKOUT',
          value: 0,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<ActivitySession>());
        final session = result as ActivitySession;
        expect(session.activityType, MetricType.workout);
        expect(session.provider, DataProvider.googleHealthConnect);
        expect(session.providerRecordType, 'WORKOUT');
        expect(session.startTime, now);
        expect(session.endTime, later);
      });
    });

    test('throws for unsupported type', () {
      final record = HealthDataRecord(
        type: 'UNKNOWN_TYPE',
        value: 0,
        dateFrom: now,
        dateTo: later,
        sourceName: 'test',
        sourceId: 'test',
      );

      expect(
        () => ActivityMapper.map(record),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
