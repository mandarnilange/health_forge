/// URL constants for the Strava REST API v3.
class StravaApiEndpoints {
  const StravaApiEndpoints._();

  /// Base URL for the Strava API.
  static const baseUrl = 'https://www.strava.com/api/v3';

  /// OAuth 2.0 authorization endpoint.
  static const authorizeUrl = 'https://www.strava.com/oauth/authorize';

  /// OAuth 2.0 token exchange endpoint.
  static const tokenUrl = 'https://www.strava.com/oauth/token';

  /// Athlete activities list endpoint.
  static const athleteActivities = '/athlete/activities';

  /// Returns the detail URL for a specific activity.
  static String activityDetail(int activityId) => '/activities/$activityId';

  /// Returns the streams URL for a specific activity.
  static String activityStreams(int activityId) =>
      '/activities/$activityId/streams';
}
