import 'package:dio/dio.dart';
import 'package:health_forge_oura/src/api/oura_api_endpoints.dart';
import 'package:health_forge_oura/src/api/rate_limiter.dart';
import 'package:health_forge_oura/src/auth/oura_auth_manager.dart';
import 'package:health_forge_oura/src/models/oura_daily_activity_response.dart';
import 'package:health_forge_oura/src/models/oura_daily_readiness_response.dart';
import 'package:health_forge_oura/src/models/oura_daily_sleep_response.dart';
import 'package:health_forge_oura/src/models/oura_daily_spo2_response.dart';
import 'package:health_forge_oura/src/models/oura_daily_stress_response.dart';
import 'package:health_forge_oura/src/models/oura_heart_rate_response.dart';
import 'package:health_forge_oura/src/models/oura_sleep_response.dart';

/// Dio-based client for the Oura Ring REST API v2.
///
/// Handles authentication, rate limiting, and pagination automatically.
class OuraApiClient {
  /// Creates an API client with the given [authManager].
  ///
  /// An optional [dio] instance can be injected for testing.
  OuraApiClient({
    required OuraAuthManager authManager,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: OuraApiEndpoints.baseUrl)) {
    if (dio == null) {
      _dio.interceptors.addAll([
        _AuthInterceptor(authManager),
        RateLimiter(),
      ]);
    }
  }

  final Dio _dio;

  /// Fetches detailed sleep data for the given date range.
  Future<OuraSleepResponse> fetchSleep({
    required String startDate,
    required String endDate,
  }) async {
    return _fetchPaginated(
      endpoint: OuraApiEndpoints.sleep,
      startDate: startDate,
      endDate: endDate,
      parse: OuraSleepResponse.fromJson,
      mergeData: (pages) => OuraSleepResponse(
        data: pages.expand((p) => p.data).toList(),
      ),
      getNextToken: (r) => r.nextToken,
    );
  }

  /// Fetches daily sleep score data for the given date range.
  Future<OuraDailySleepResponse> fetchDailySleep({
    required String startDate,
    required String endDate,
  }) async {
    return _fetchPaginated(
      endpoint: OuraApiEndpoints.dailySleep,
      startDate: startDate,
      endDate: endDate,
      parse: OuraDailySleepResponse.fromJson,
      mergeData: (pages) => OuraDailySleepResponse(
        data: pages.expand((p) => p.data).toList(),
      ),
      getNextToken: (r) => r.nextToken,
    );
  }

  /// Fetches daily activity data for the given date range.
  Future<OuraDailyActivityResponse> fetchDailyActivity({
    required String startDate,
    required String endDate,
  }) async {
    return _fetchPaginated(
      endpoint: OuraApiEndpoints.dailyActivity,
      startDate: startDate,
      endDate: endDate,
      parse: OuraDailyActivityResponse.fromJson,
      mergeData: (pages) => OuraDailyActivityResponse(
        data: pages.expand((p) => p.data).toList(),
      ),
      getNextToken: (r) => r.nextToken,
    );
  }

  /// Fetches heart rate samples for the given date range.
  Future<OuraHeartRateResponse> fetchHeartRate({
    required String startDate,
    required String endDate,
  }) async {
    return _fetchPaginated(
      endpoint: OuraApiEndpoints.heartRate,
      startDate: startDate,
      endDate: endDate,
      parse: OuraHeartRateResponse.fromJson,
      mergeData: (pages) => OuraHeartRateResponse(
        data: pages.expand((p) => p.data).toList(),
      ),
      getNextToken: (r) => r.nextToken,
    );
  }

  /// Fetches daily readiness data for the given date range.
  Future<OuraDailyReadinessResponse> fetchDailyReadiness({
    required String startDate,
    required String endDate,
  }) async {
    return _fetchPaginated(
      endpoint: OuraApiEndpoints.dailyReadiness,
      startDate: startDate,
      endDate: endDate,
      parse: OuraDailyReadinessResponse.fromJson,
      mergeData: (pages) => OuraDailyReadinessResponse(
        data: pages.expand((p) => p.data).toList(),
      ),
      getNextToken: (r) => r.nextToken,
    );
  }

  /// Fetches daily stress data for the given date range.
  Future<OuraDailyStressResponse> fetchDailyStress({
    required String startDate,
    required String endDate,
  }) async {
    return _fetchPaginated(
      endpoint: OuraApiEndpoints.dailyStress,
      startDate: startDate,
      endDate: endDate,
      parse: OuraDailyStressResponse.fromJson,
      mergeData: (pages) => OuraDailyStressResponse(
        data: pages.expand((p) => p.data).toList(),
      ),
      getNextToken: (r) => r.nextToken,
    );
  }

  /// Fetches daily SpO2 data for the given date range.
  Future<OuraDailySpo2Response> fetchDailySpo2({
    required String startDate,
    required String endDate,
  }) async {
    return _fetchPaginated(
      endpoint: OuraApiEndpoints.dailySpo2,
      startDate: startDate,
      endDate: endDate,
      parse: OuraDailySpo2Response.fromJson,
      mergeData: (pages) => OuraDailySpo2Response(
        data: pages.expand((p) => p.data).toList(),
      ),
      getNextToken: (r) => r.nextToken,
    );
  }

  Future<T> _fetchPaginated<T>({
    required String endpoint,
    required String startDate,
    required String endDate,
    required T Function(Map<String, dynamic>) parse,
    required T Function(List<T>) mergeData,
    required String? Function(T) getNextToken,
  }) async {
    final pages = <T>[];
    String? nextToken;

    do {
      final queryParams = <String, dynamic>{
        'start_date': startDate,
        'end_date': endDate,
      };

      if (nextToken != null) {
        queryParams['next_token'] = nextToken;
      }

      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParams,
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final page = parse(data);
      pages.add(page);
      nextToken = getNextToken(page);
    } while (nextToken != null);

    if (pages.length == 1) return pages.first;
    return mergeData(pages);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._authManager);

  final OuraAuthManager _authManager;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authManager.currentToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer ${token.accessToken}';
    }
    handler.next(options);
  }
}
