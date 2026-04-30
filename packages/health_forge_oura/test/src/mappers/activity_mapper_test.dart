import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/mappers/activity_mapper.dart';
import 'package:health_forge_oura/src/models/oura_daily_activity_response.dart';

void main() {
  group('ActivityMapper', () {
    late OuraDailyActivityResponse response;

    setUp(() {
      response = const OuraDailyActivityResponse(
        data: [
          OuraDailyActivityData(
            id: 'act_001',
            day: '2024-01-15',
            steps: 8523,
            activeCalories: 450,
            totalCalories: 2150,
          ),
        ],
      );
    });

    group('mapSteps', () {
      test('maps step count', () {
        final steps = ActivityMapper.mapSteps(response);
        expect(steps, hasLength(1));

        final step = steps.first;
        expect(step.provider, DataProvider.oura);
        expect(step.providerRecordType, 'daily_activity');
        expect(step.count, 8523);
      });

      test('maps day to start and end times', () {
        final step = ActivityMapper.mapSteps(response).first;
        expect(step.startTime, DateTime.utc(2024, 1, 15));
        expect(step.endTime, DateTime.utc(2024, 1, 16));
      });

      test('skips entries with null steps', () {
        response = const OuraDailyActivityResponse(
          data: [
            OuraDailyActivityData(
              id: 'act_002',
              day: '2024-01-15',
            ),
          ],
        );
        final steps = ActivityMapper.mapSteps(response);
        expect(steps, isEmpty);
      });
    });

    group('mapCalories', () {
      test('maps calories burned', () {
        final calories = ActivityMapper.mapCalories(response);
        expect(calories, hasLength(1));

        final cal = calories.first;
        expect(cal.provider, DataProvider.oura);
        expect(cal.totalCalories, 2150);
        expect(cal.activeCalories, 450);
      });

      test('skips entries with null totalCalories', () {
        response = const OuraDailyActivityResponse(
          data: [
            OuraDailyActivityData(
              id: 'act_003',
              day: '2024-01-15',
            ),
          ],
        );
        final calories = ActivityMapper.mapCalories(response);
        expect(calories, isEmpty);
      });
    });
  });
}
