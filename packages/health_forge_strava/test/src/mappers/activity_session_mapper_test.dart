import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/mappers/activity_session_mapper.dart';
import 'package:health_forge_strava/src/models/strava_activity_detail_response.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

void main() {
  group('ActivitySessionMapper', () {
    group('mapFromList', () {
      test('maps activities to ActivitySession list', () {
        const response = StravaActivityListResponse(
          activities: [
            StravaActivitySummary(
              id: 1,
              name: 'Morning Run',
              type: 'Run',
              sportType: 'Run',
              startDate: '2024-01-15T07:00:00Z',
              elapsedTime: 3600,
              movingTime: 3400,
              distance: 10000,
              totalElevationGain: 150,
              kilojoules: 2510,
              averageHeartrate: 145,
              maxHeartrate: 172,
              sufferScore: 78,
            ),
          ],
        );

        final sessions = ActivitySessionMapper.mapFromList(response);

        expect(sessions, hasLength(1));
        expect(sessions.first.provider, DataProvider.strava);
        expect(sessions.first.activityName, 'Morning Run');
        expect(sessions.first.distanceMeters, 10000.0);
        expect(sessions.first.averageHeartRate, 145);
        expect(sessions.first.maxHeartRate, 172);
      });

      test('converts kilojoules to kcal', () {
        const response = StravaActivityListResponse(
          activities: [
            StravaActivitySummary(
              id: 1,
              name: 'Ride',
              type: 'Ride',
              sportType: 'Ride',
              startDate: '2024-01-15T07:00:00Z',
              elapsedTime: 3600,
              movingTime: 3400,
              kilojoules: 4184,
            ),
          ],
        );

        final sessions = ActivitySessionMapper.mapFromList(response);

        // 4184 kJ / 4.184 = 1000 kcal
        expect(sessions.first.totalCalories, closeTo(1000.0, 0.1));
      });

      test('includes StravaWorkoutExtension in extensions', () {
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
              sufferScore: 78,
              mapSummaryPolyline: 'abc123',
            ),
          ],
        );

        final sessions = ActivitySessionMapper.mapFromList(response);
        final ext = StravaWorkoutExtension.fromJson(sessions.first.extensions);

        expect(ext.sufferScore, 78);
        expect(ext.routePolyline, 'abc123');
      });

      test('calculates endTime from startTime + elapsedTime', () {
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
            ),
          ],
        );

        final sessions = ActivitySessionMapper.mapFromList(response);

        expect(
          sessions.first.startTime,
          DateTime.utc(2024, 1, 15, 7),
        );
        expect(
          sessions.first.endTime,
          DateTime.utc(2024, 1, 15, 8),
        );
      });

      test('handles null kilojoules', () {
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

        final sessions = ActivitySessionMapper.mapFromList(response);
        expect(sessions.first.totalCalories, isNull);
      });

      test('maps empty list', () {
        const response = StravaActivityListResponse(activities: []);
        final sessions = ActivitySessionMapper.mapFromList(response);
        expect(sessions, isEmpty);
      });
    });

    group('mapFromDetail', () {
      test('maps detail response with full data', () {
        const detail = StravaActivityDetailResponse(
          id: 1,
          name: 'Morning Run',
          type: 'Run',
          sportType: 'Run',
          startDate: '2024-01-15T07:00:00Z',
          elapsedTime: 3600,
          movingTime: 3400,
          distance: 10000,
          totalElevationGain: 150,
          calories: 600,
          kilojoules: 2510,
          averageHeartrate: 145,
          maxHeartrate: 172,
          sufferScore: 78,
          segmentEfforts: [
            {'name': 'Park Loop', 'elapsed_time': 420},
          ],
          mapPolyline: 'full_polyline',
        );

        final session = ActivitySessionMapper.mapFromDetail(detail);

        expect(session.provider, DataProvider.strava);
        expect(session.activityName, 'Morning Run');
        // Should prefer calories over kilojoules conversion
        expect(session.totalCalories, 600.0);

        final ext = StravaWorkoutExtension.fromJson(session.extensions);
        expect(ext.sufferScore, 78);
        expect(ext.segmentEfforts, hasLength(1));
        expect(ext.routePolyline, 'full_polyline');
      });

      test('falls back to kJ conversion when calories is null', () {
        const detail = StravaActivityDetailResponse(
          id: 1,
          name: 'Ride',
          type: 'Ride',
          sportType: 'Ride',
          startDate: '2024-01-15T07:00:00Z',
          elapsedTime: 3600,
          movingTime: 3400,
          kilojoules: 4184,
        );

        final session = ActivitySessionMapper.mapFromDetail(detail);
        expect(session.totalCalories, closeTo(1000.0, 0.1));
      });
    });
  });
}
