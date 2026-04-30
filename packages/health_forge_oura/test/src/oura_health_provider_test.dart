import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/api/oura_api_client.dart';
import 'package:health_forge_oura/src/auth/oura_auth_manager.dart';
import 'package:health_forge_oura/src/auth/oura_token.dart';
import 'package:health_forge_oura/src/models/oura_daily_activity_response.dart';
import 'package:health_forge_oura/src/models/oura_daily_readiness_response.dart';
import 'package:health_forge_oura/src/models/oura_daily_sleep_response.dart';
import 'package:health_forge_oura/src/models/oura_daily_spo2_response.dart';
import 'package:health_forge_oura/src/models/oura_daily_stress_response.dart';
import 'package:health_forge_oura/src/models/oura_heart_rate_response.dart';
import 'package:health_forge_oura/src/models/oura_sleep_response.dart';
import 'package:health_forge_oura/src/oura_health_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockOuraAuthManager extends Mock implements OuraAuthManager {}

class MockOuraApiClient extends Mock implements OuraApiClient {}

void main() {
  late OuraHealthProvider provider;
  late MockOuraAuthManager mockAuthManager;
  late MockOuraApiClient mockApiClient;

  setUp(() {
    mockAuthManager = MockOuraAuthManager();
    mockApiClient = MockOuraApiClient();
    provider = OuraHealthProvider(
      authManager: mockAuthManager,
      apiClient: mockApiClient,
    );
  });

  group('OuraHealthProvider', () {
    test('providerType is oura', () {
      expect(provider.providerType, DataProvider.oura);
    });

    test('displayName is Oura Ring', () {
      expect(provider.displayName, 'Oura Ring');
    });

    test('capabilities matches OuraCapabilities', () {
      expect(
        provider.capabilities.supportedMetrics,
        hasLength(8),
      );
    });

    group('isAuthorized', () {
      test('returns false when no token', () async {
        when(() => mockAuthManager.currentToken).thenReturn(null);
        expect(await provider.isAuthorized(), isFalse);
      });

      test('returns true when token exists and not expired', () async {
        when(() => mockAuthManager.currentToken).thenReturn(
          OuraToken(
            accessToken: 'at',
            refreshToken: 'rt',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
        expect(await provider.isAuthorized(), isTrue);
      });

      test('returns false when token is expired', () async {
        when(() => mockAuthManager.currentToken).thenReturn(
          OuraToken(
            accessToken: 'at',
            refreshToken: 'rt',
            expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        );
        expect(await provider.isAuthorized(), isFalse);
      });
    });

    group('authorize', () {
      test('returns success when auth manager returns token', () async {
        when(() => mockAuthManager.authorize()).thenAnswer(
          (_) async => OuraToken(
            accessToken: 'at',
            refreshToken: 'rt',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        final result = await provider.authorize();
        expect(result.isSuccess, isTrue);
      });

      test('returns denied when auth manager returns null', () async {
        when(() => mockAuthManager.authorize()).thenAnswer(
          (_) async => null,
        );

        final result = await provider.authorize();
        expect(result.isSuccess, isFalse);
      });
    });

    group('deauthorize', () {
      test('calls clearToken on auth manager', () async {
        when(() => mockAuthManager.clearToken()).thenReturn(null);

        await provider.deauthorize();

        verify(() => mockAuthManager.clearToken()).called(1);
      });
    });

    group('fetchRecords', () {
      final timeRange = TimeRange(
        start: DateTime.utc(2024, 1, 15),
        end: DateTime.utc(2024, 1, 16),
      );

      test('fetches sleep sessions', () async {
        when(
          () => mockApiClient.fetchSleep(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => const OuraSleepResponse(
            data: [
              OuraSleepData(
                id: 's1',
                bedtimeStart: '2024-01-15T22:00:00Z',
                bedtimeEnd: '2024-01-16T06:00:00Z',
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.sleepSession,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<SleepSession>());
      });

      test('fetches heart rate samples', () async {
        when(
          () => mockApiClient.fetchHeartRate(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => const OuraHeartRateResponse(
            data: [
              OuraHeartRateData(
                bpm: 72,
                source: 'awake',
                timestamp: '2024-01-15T10:00:00Z',
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.heartRate,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<HeartRateSample>());
      });

      test('fetches steps from daily activity', () async {
        when(
          () => mockApiClient.fetchDailyActivity(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => const OuraDailyActivityResponse(
            data: [
              OuraDailyActivityData(
                id: 'a1',
                day: '2024-01-15',
                steps: 8000,
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.steps,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<StepCount>());
      });

      test('fetches calories from daily activity', () async {
        when(
          () => mockApiClient.fetchDailyActivity(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => const OuraDailyActivityResponse(
            data: [
              OuraDailyActivityData(
                id: 'a1',
                day: '2024-01-15',
                totalCalories: 2100,
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.calories,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<CaloriesBurned>());
      });

      test('fetches sleep score', () async {
        when(
          () => mockApiClient.fetchDailySleep(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => const OuraDailySleepResponse(
            data: [
              OuraDailySleepData(
                id: 'ds1',
                day: '2024-01-15',
                score: 85,
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.sleepScore,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<SleepScore>());
      });

      test('fetches readiness', () async {
        when(
          () => mockApiClient.fetchDailyReadiness(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => const OuraDailyReadinessResponse(
            data: [
              OuraDailyReadinessData(
                id: 'r1',
                day: '2024-01-15',
                score: 82,
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.readiness,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<ReadinessScore>());
      });

      test('fetches stress', () async {
        when(
          () => mockApiClient.fetchDailyStress(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => const OuraDailyStressResponse(
            data: [
              OuraDailyStressData(
                id: 'st1',
                day: '2024-01-15',
                stressHigh: 3600,
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.stress,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<StressScore>());
      });

      test('fetches blood oxygen', () async {
        when(
          () => mockApiClient.fetchDailySpo2(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => const OuraDailySpo2Response(
            data: [
              OuraDailySpo2Data(
                id: 'spo2_1',
                day: '2024-01-15',
                spo2Percentage: OuraSpo2Percentage(average: 97.5),
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.bloodOxygen,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<BloodOxygenSample>());
      });

      test('returns empty list for unsupported metric', () async {
        final records = await provider.fetchRecords(
          metricType: MetricType.weight,
          timeRange: timeRange,
        );

        expect(records, isEmpty);
      });
    });
  });
}
