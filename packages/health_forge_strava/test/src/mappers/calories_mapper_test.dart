import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/mappers/calories_mapper.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

void main() {
  group('CaloriesMapper', () {
    test('converts kilojoules to kcal', () {
      const response = StravaActivityListResponse(
        activities: [
          StravaActivitySummary(
            id: 1,
            name: 'Run',
            type: 'Run',
            sportType: 'Run',
            startDate: '2024-01-15T07:00:00Z',
            elapsedTime: 3600,
            movingTime: 3400,
            kilojoules: 4184,
          ),
        ],
      );

      final records = CaloriesMapper.map(response);

      expect(records, hasLength(1));
      expect(records.first.totalCalories, closeTo(1000.0, 0.1));
    });

    test('sets provider to strava', () {
      const response = StravaActivityListResponse(
        activities: [
          StravaActivitySummary(
            id: 1,
            name: 'Run',
            type: 'Run',
            sportType: 'Run',
            startDate: '2024-01-15T07:00:00Z',
            elapsedTime: 3600,
            movingTime: 3400,
            kilojoules: 2000,
          ),
        ],
      );

      final records = CaloriesMapper.map(response);
      expect(records.first.provider, DataProvider.strava);
    });

    test('filters out activities without kilojoules', () {
      const response = StravaActivityListResponse(
        activities: [
          StravaActivitySummary(
            id: 1,
            name: 'Walk',
            type: 'Walk',
            sportType: 'Walk',
            startDate: '2024-01-15T07:00:00Z',
            elapsedTime: 1800,
            movingTime: 1700,
          ),
        ],
      );

      final records = CaloriesMapper.map(response);
      expect(records, isEmpty);
    });

    test('maps time range from activity', () {
      const response = StravaActivityListResponse(
        activities: [
          StravaActivitySummary(
            id: 1,
            name: 'Run',
            type: 'Run',
            sportType: 'Run',
            startDate: '2024-01-15T07:00:00Z',
            elapsedTime: 3600,
            movingTime: 3400,
            kilojoules: 2000,
          ),
        ],
      );

      final records = CaloriesMapper.map(response);
      expect(records.first.startTime, DateTime.utc(2024, 1, 15, 7));
      expect(records.first.endTime, DateTime.utc(2024, 1, 15, 8));
    });
  });
}
