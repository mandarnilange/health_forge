import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/mappers/elevation_mapper.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

void main() {
  group('ElevationMapper', () {
    test('maps elevation gain from activity', () {
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
            totalElevationGain: 150.5,
          ),
        ],
      );

      final records = ElevationMapper.map(response);

      expect(records, hasLength(1));
      expect(records.first.elevationMeters, 150.5);
      expect(records.first.provider, DataProvider.strava);
    });

    test('filters out activities without elevation', () {
      const response = StravaActivityListResponse(
        activities: [
          StravaActivitySummary(
            id: 1,
            name: 'Swim',
            type: 'Swim',
            sportType: 'Swim',
            startDate: '2024-01-15T07:00:00Z',
            elapsedTime: 3600,
            movingTime: 3400,
          ),
        ],
      );

      final records = ElevationMapper.map(response);
      expect(records, isEmpty);
    });

    test('maps time range from activity', () {
      const response = StravaActivityListResponse(
        activities: [
          StravaActivitySummary(
            id: 1,
            name: 'Hike',
            type: 'Hike',
            sportType: 'Hike',
            startDate: '2024-01-15T07:00:00Z',
            elapsedTime: 7200,
            movingTime: 6800,
            totalElevationGain: 500,
          ),
        ],
      );

      final records = ElevationMapper.map(response);
      expect(records.first.startTime, DateTime.utc(2024, 1, 15, 7));
      expect(records.first.endTime, DateTime.utc(2024, 1, 15, 9));
    });
  });
}
