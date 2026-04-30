import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/api/strava_api_endpoints.dart';

void main() {
  group('StravaApiEndpoints', () {
    test('baseUrl points to Strava API v3', () {
      expect(
        StravaApiEndpoints.baseUrl,
        'https://www.strava.com/api/v3',
      );
    });

    test('authorizeUrl points to Strava OAuth', () {
      expect(
        StravaApiEndpoints.authorizeUrl,
        'https://www.strava.com/oauth/authorize',
      );
    });

    test('tokenUrl points to Strava OAuth token endpoint', () {
      expect(
        StravaApiEndpoints.tokenUrl,
        'https://www.strava.com/oauth/token',
      );
    });

    test('athleteActivities is correct path', () {
      expect(
        StravaApiEndpoints.athleteActivities,
        '/athlete/activities',
      );
    });

    test('activityDetail returns correct path', () {
      expect(
        StravaApiEndpoints.activityDetail(12345),
        '/activities/12345',
      );
    });

    test('activityStreams returns correct path', () {
      expect(
        StravaApiEndpoints.activityStreams(12345),
        '/activities/12345/streams',
      );
    });
  });
}
