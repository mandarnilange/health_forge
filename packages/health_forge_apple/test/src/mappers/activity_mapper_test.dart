import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_apple/src/mappers/activity_mapper.dart';
import 'package:health_forge_core/health_forge_core.dart';

void main() {
  final now = DateTime(2024, 6, 15, 10);
  final later = DateTime(2024, 6, 15, 10, 30);

  group('ActivityMapper', () {
    group('STEPS', () {
      test('maps to StepCount with correct count', () {
        final record = HealthDataRecord(
          type: 'STEPS',
          value: 1500,
          dateFrom: now,
          dateTo: later,
          sourceName: 'iPhone',
          sourceId: 'com.apple.health',
          uuid: 'steps-uuid',
          deviceModel: 'iPhone 15 Pro',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<StepCount>());
        final steps = result as StepCount;
        expect(steps.count, 1500);
        expect(steps.provider, DataProvider.apple);
        expect(steps.providerRecordType, 'STEPS');
        expect(steps.startTime, now);
        expect(steps.endTime, later);
        expect(steps.id, 'steps-uuid');
        expect(steps.provenance, isNotNull);
        expect(steps.provenance!.dataOrigin, DataOrigin.native_);
        expect(steps.provenance!.sourceDevice?.model, 'iPhone 15 Pro');
        expect(steps.provenance!.sourceDevice?.manufacturer, 'iPhone');
        expect(steps.provenance!.sourceApp, 'com.apple.health');
      });
    });

    group('ACTIVE_ENERGY_BURNED', () {
      test('maps to CaloriesBurned with totalCalories', () {
        final record = HealthDataRecord(
          type: 'ACTIVE_ENERGY_BURNED',
          value: 350.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'cal-uuid',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<CaloriesBurned>());
        final cals = result as CaloriesBurned;
        expect(cals.totalCalories, 350.5);
        expect(cals.provider, DataProvider.apple);
        expect(cals.providerRecordType, 'ACTIVE_ENERGY_BURNED');
      });
    });

    group('DISTANCE_WALKING_RUNNING', () {
      test('maps to DistanceSample with distanceMeters', () {
        final record = HealthDataRecord(
          type: 'DISTANCE_WALKING_RUNNING',
          value: 2500,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'dist-uuid',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<DistanceSample>());
        final dist = result as DistanceSample;
        expect(dist.distanceMeters, 2500);
        expect(dist.provider, DataProvider.apple);
        expect(dist.providerRecordType, 'DISTANCE_WALKING_RUNNING');
      });
    });

    group('WORKOUT', () {
      test('maps to ActivitySession with workout type', () {
        final record = HealthDataRecord(
          type: 'WORKOUT',
          value: 0,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'workout-uuid',
          workoutActivityType: 'RUNNING',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<ActivitySession>());
        final session = result as ActivitySession;
        expect(session.activityType, MetricType.workout);
        expect(session.activityName, 'RUNNING');
        expect(session.provider, DataProvider.apple);
        expect(session.providerRecordType, 'WORKOUT');
      });

      test('maps workout without activity type', () {
        final record = HealthDataRecord(
          type: 'WORKOUT',
          value: 0,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        final result = ActivityMapper.map(record);

        expect(result, isA<ActivitySession>());
        final session = result as ActivitySession;
        expect(session.activityName, isNull);
      });
    });

    test('throws ArgumentError for unsupported type', () {
      final record = HealthDataRecord(
        type: 'UNKNOWN_TYPE',
        value: 0,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(() => ActivityMapper.map(record), throwsArgumentError);
    });
  });
}
