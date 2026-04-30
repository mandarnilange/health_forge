import 'package:dio/dio.dart';
import 'package:health_forge_strava/src/api/rate_limiter.dart';
import 'package:health_forge_strava/src/api/strava_api_endpoints.dart';
import 'package:health_forge_strava/src/auth/strava_auth_manager.dart';
import 'package:health_forge_strava/src/models/strava_activity_detail_response.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';
import 'package:health_forge_strava/src/models/strava_streams_response.dart';

/// Dio-based client for the Strava REST API v3.
///
/// Handles authentication, rate limiting, and page-based pagination.
class StravaApiClient {
  /// Creates an API client with the given [authManager].
  ///
  /// An optional [dio] instance and [perPage] size can be provided.
  StravaApiClient({
    required StravaAuthManager authManager,
    Dio? dio,
    int perPage = 50,
  })  : _dio = dio ?? Dio(BaseOptions(baseUrl: StravaApiEndpoints.baseUrl)),
        _perPage = perPage {
    if (dio == null) {
      _dio.interceptors.addAll([
        _AuthInterceptor(authManager),
        RateLimiter(),
      ]);
    }
  }

  final Dio _dio;
  final int _perPage;

  /// Fetches athlete activities within the given time range.
  ///
  /// Uses page-based pagination, stopping when results < perPage.
  Future<StravaActivityListResponse> fetchActivities({
    required DateTime after,
    required DateTime before,
  }) async {
    final allActivities = <StravaActivitySummary>[];
    var page = 1;

    while (true) {
      final response = await _dio.get<dynamic>(
        StravaApiEndpoints.athleteActivities,
        queryParameters: {
          'after': after.millisecondsSinceEpoch ~/ 1000,
          'before': before.millisecondsSinceEpoch ~/ 1000,
          'page': page,
          'per_page': _perPage,
        },
      );

      final data = response.data as List<dynamic>;
      final pageResponse = StravaActivityListResponse.fromJson(data);
      allActivities.addAll(pageResponse.activities);

      if (pageResponse.activities.length < _perPage) break;
      page++;
    }

    return StravaActivityListResponse(activities: allActivities);
  }

  /// Fetches detailed activity data for a specific activity.
  Future<StravaActivityDetailResponse> fetchActivityDetail({
    required int activityId,
  }) async {
    final response = await _dio.get<dynamic>(
      StravaApiEndpoints.activityDetail(activityId),
    );

    return StravaActivityDetailResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Fetches heart rate stream data for a specific activity.
  Future<StravaStreamsResponse> fetchActivityStreams({
    required int activityId,
  }) async {
    final response = await _dio.get<dynamic>(
      StravaApiEndpoints.activityStreams(activityId),
      queryParameters: {
        'keys': 'heartrate,time',
        'key_type': 'value',
      },
    );

    return StravaStreamsResponse.fromJson(response.data as List<dynamic>);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._authManager);

  final StravaAuthManager _authManager;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authManager.currentToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer ${token.accessToken}';
    }
    handler.next(options);
  }
}
