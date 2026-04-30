import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/api/oura_api_client.dart';
import 'package:health_forge_oura/src/auth/oura_auth_manager.dart';
import 'package:health_forge_oura/src/mappers/activity_mapper.dart';
import 'package:health_forge_oura/src/mappers/heart_rate_mapper.dart';
import 'package:health_forge_oura/src/mappers/readiness_mapper.dart';
import 'package:health_forge_oura/src/mappers/sleep_mapper.dart';
import 'package:health_forge_oura/src/mappers/sleep_score_mapper.dart';
import 'package:health_forge_oura/src/mappers/spo2_mapper.dart';
import 'package:health_forge_oura/src/mappers/stress_mapper.dart';
import 'package:health_forge_oura/src/oura_capabilities.dart';

/// Health provider implementation for the Oura Ring API.
class OuraHealthProvider implements HealthProvider {
  /// Creates an Oura Ring provider with the given
  /// [authManager] and [apiClient].
  OuraHealthProvider({
    required OuraAuthManager authManager,
    required OuraApiClient apiClient,
  })  : _authManager = authManager,
        _apiClient = apiClient;

  final OuraAuthManager _authManager;
  final OuraApiClient _apiClient;

  @override
  DataProvider get providerType => DataProvider.oura;

  @override
  String get displayName => 'Oura Ring';

  @override
  ProviderCapabilities get capabilities => OuraCapabilities.capabilities;

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
    final startDate = _formatDate(timeRange.start);
    final endDate = _formatDate(timeRange.end);

    return switch (metricType) {
      MetricType.sleepSession => SleepMapper.map(
          await _apiClient.fetchSleep(
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      MetricType.sleepScore => SleepScoreMapper.map(
          await _apiClient.fetchDailySleep(
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      MetricType.heartRate => HeartRateMapper.map(
          await _apiClient.fetchHeartRate(
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      MetricType.steps => ActivityMapper.mapSteps(
          await _apiClient.fetchDailyActivity(
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      MetricType.calories => ActivityMapper.mapCalories(
          await _apiClient.fetchDailyActivity(
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      MetricType.readiness => ReadinessMapper.map(
          await _apiClient.fetchDailyReadiness(
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      MetricType.stress => StressMapper.map(
          await _apiClient.fetchDailyStress(
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      MetricType.bloodOxygen => Spo2Mapper.map(
          await _apiClient.fetchDailySpo2(
            startDate: startDate,
            endDate: endDate,
          ),
        ),
      _ => const [],
    };
  }

  static String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }
}
