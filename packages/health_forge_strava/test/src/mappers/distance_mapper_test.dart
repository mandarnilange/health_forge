import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/mappers/distance_mapper.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

void main() {
  group('DistanceMapper', () {
    test('maps distance from activity', () {
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
            distance: 10000,
          ),
        ],
      );

      final records = DistanceMapper.map(response);

      expect(records, hasLength(1));
      expect(records.first.distanceMeters, 10000.0);
      expect(records.first.provider, DataProvider.strava);
    });

    test('filters out activities without distance', () {
      const response = StravaActivityListResponse(
        activities: [
          StravaActivitySummary(
            id: 1,
            name: 'Yoga',
            type: 'Yoga',
            sportType: 'Yoga',
            startDate: '2024-01-15T07:00:00Z',
            elapsedTime: 3600,
            movingTime: 3400,
          ),
        ],
      );

      final records = DistanceMapper.map(response);
      expect(records, isEmpty);
    });

    test('maps multiple activities', () {
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
            distance: 10000,
          ),
          StravaActivitySummary(
            id: 2,
            name: 'Ride',
            type: 'Ride',
            sportType: 'Ride',
            startDate: '2024-01-15T14:00:00Z',
            elapsedTime: 5400,
            movingTime: 5200,
            distance: 30000,
          ),
        ],
      );

      final records = DistanceMapper.map(response);
      expect(records, hasLength(2));
      expect(records[0].distanceMeters, 10000.0);
      expect(records[1].distanceMeters, 30000.0);
    });
  });
}
