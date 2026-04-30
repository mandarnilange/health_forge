import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/api/strava_api_client.dart';
import 'package:health_forge_strava/src/auth/strava_auth_manager.dart';
import 'package:health_forge_strava/src/mappers/activity_session_mapper.dart';
import 'package:health_forge_strava/src/mappers/calories_mapper.dart';
import 'package:health_forge_strava/src/mappers/distance_mapper.dart';
import 'package:health_forge_strava/src/mappers/elevation_mapper.dart';
import 'package:health_forge_strava/src/mappers/heart_rate_mapper.dart';
import 'package:health_forge_strava/src/strava_capabilities.dart';

/// Health provider implementation for the Strava API.
class StravaHealthProvider implements HealthProvider {
  /// Creates a Strava provider with the given [authManager] and [apiClient].
  StravaHealthProvider({
    required StravaAuthManager authManager,
    required StravaApiClient apiClient,
  })  : _authManager = authManager,
        _apiClient = apiClient;

  final StravaAuthManager _authManager;
  final StravaApiClient _apiClient;

  @override
  DataProvider get providerType => DataProvider.strava;

  @override
  String get displayName => 'Strava';

  @override
  ProviderCapabilities get capabilities => StravaCapabilities.capabilities;

  @override
  Future<bool> isAuthorized() async {
    final token = _authManager.currentToken;
    return token != null && !token.isExpired;
  }

  @override
  Future<AuthResult> authorize() async {
    final token = await _authManager.authorize();
    if (token == null) return AuthResult.denied();
    return AuthResult.success();
  }

  @override
  Future<void> deauthorize() async {
    _authManager.clearToken();
  }

  @override
  Future<List<HealthRecordMixin>> fetchRecords({
    required MetricType metricType,
    required TimeRange timeRange,
  }) async {
    return switch (metricType) {
      MetricType.workout => _fetchWorkouts(timeRange),
      MetricType.heartRate => _fetchHeartRate(timeRange),
      MetricType.calories => CaloriesMapper.map(
          await _apiClient.fetchActivities(
            after: timeRange.start,
            before: timeRange.end,
          ),
        ),
      MetricType.distance => DistanceMapper.map(
          await _apiClient.fetchActivities(
            after: timeRange.start,
            before: timeRange.end,
          ),
        ),
      MetricType.elevation => ElevationMapper.map(
          await _apiClient.fetchActivities(
            after: timeRange.start,
            before: timeRange.end,
          ),
        ),
      _ => const [],
    };
  }

  Future<List<HealthRecordMixin>> _fetchWorkouts(TimeRange timeRange) async {
    final activitiesResponse = await _apiClient.fetchActivities(
      after: timeRange.start,
      before: timeRange.end,
    );
    return ActivitySessionMapper.mapFromList(activitiesResponse);
  }

  Future<List<HealthRecordMixin>> _fetchHeartRate(TimeRange timeRange) async {
    final activitiesResponse = await _apiClient.fetchActivities(
      after: timeRange.start,
      before: timeRange.end,
    );

    final allSamples = <HeartRateSample>[];
    for (final activity in activitiesResponse.activities) {
      if (activity.hasHeartrate != true) continue;

      final streams = await _apiClient.fetchActivityStreams(
        activityId: activity.id,
      );

      allSamples.addAll(
        HeartRateMapper.map(
          activityStartTime: DateTime.parse(activity.startDate),
          streams: streams,
          activityId: activity.id,
        ),
      );
    }
    return allSamples;
  }
}
