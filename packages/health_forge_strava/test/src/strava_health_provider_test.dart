import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/api/strava_api_client.dart';
import 'package:health_forge_strava/src/auth/strava_auth_manager.dart';
import 'package:health_forge_strava/src/auth/strava_token.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';
import 'package:health_forge_strava/src/models/strava_streams_response.dart';
import 'package:health_forge_strava/src/strava_health_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockStravaAuthManager extends Mock implements StravaAuthManager {}

class MockStravaApiClient extends Mock implements StravaApiClient {}

void main() {
  late StravaHealthProvider provider;
  late MockStravaAuthManager mockAuthManager;
  late MockStravaApiClient mockApiClient;

  setUp(() {
    mockAuthManager = MockStravaAuthManager();
    mockApiClient = MockStravaApiClient();
    provider = StravaHealthProvider(
      authManager: mockAuthManager,
      apiClient: mockApiClient,
    );
  });

  group('StravaHealthProvider', () {
    test('providerType is strava', () {
      expect(provider.providerType, DataProvider.strava);
    });

    test('displayName is Strava', () {
      expect(provider.displayName, 'Strava');
    });

    test('capabilities matches StravaCapabilities', () {
      expect(provider.capabilities.supportedMetrics, hasLength(5));
    });

    group('isAuthorized', () {
      test('returns false when no token', () async {
        when(() => mockAuthManager.currentToken).thenReturn(null);
        expect(await provider.isAuthorized(), isFalse);
      });

      test('returns true when token exists and not expired', () async {
        when(() => mockAuthManager.currentToken).thenReturn(
          StravaToken(
            accessToken: 'at',
            refreshToken: 'rt',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
        expect(await provider.isAuthorized(), isTrue);
      });

      test('returns false when token is expired', () async {
        when(() => mockAuthManager.currentToken).thenReturn(
          StravaToken(
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
          (_) async => StravaToken(
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

      test('fetches workouts', () async {
        when(
          () => mockApiClient.fetchActivities(
            after: any(named: 'after'),
            before: any(named: 'before'),
          ),
        ).thenAnswer(
          (_) async => const StravaActivityListResponse(
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
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.workout,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<ActivitySession>());
      });

      test('fetches heart rate via two-step flow', () async {
        when(
          () => mockApiClient.fetchActivities(
            after: any(named: 'after'),
            before: any(named: 'before'),
          ),
        ).thenAnswer(
          (_) async => const StravaActivityListResponse(
            activities: [
              StravaActivitySummary(
                id: 1,
                name: 'Run',
                type: 'Run',
                sportType: 'Run',
                startDate: '2024-01-15T07:00:00Z',
                elapsedTime: 3600,
                movingTime: 3400,
                hasHeartrate: true,
              ),
            ],
          ),
        );

        when(
          () => mockApiClient.fetchActivityStreams(
            activityId: any(named: 'activityId'),
          ),
        ).thenAnswer(
          (_) async => const StravaStreamsResponse(
            streams: [
              StravaStream(type: 'time', data: [0, 60]),
              StravaStream(type: 'heartrate', data: [120, 130]),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.heartRate,
          timeRange: timeRange,
        );

        expect(records, hasLength(2));
        expect(records.first, isA<HeartRateSample>());
      });

      test('skips HR fetch for activities without heartrate', () async {
        when(
          () => mockApiClient.fetchActivities(
            after: any(named: 'after'),
            before: any(named: 'before'),
          ),
        ).thenAnswer(
          (_) async => const StravaActivityListResponse(
            activities: [
              StravaActivitySummary(
                id: 1,
                name: 'Walk',
                type: 'Walk',
                sportType: 'Walk',
                startDate: '2024-01-15T07:00:00Z',
                elapsedTime: 1800,
                movingTime: 1700,
                hasHeartrate: false,
              ),
            ],
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.heartRate,
          timeRange: timeRange,
        );

        expect(records, isEmpty);
        verifyNever(
          () => mockApiClient.fetchActivityStreams(
            activityId: any(named: 'activityId'),
          ),
        );
      });

      test('fetches calories', () async {
        when(
          () => mockApiClient.fetchActivities(
            after: any(named: 'after'),
            before: any(named: 'before'),
          ),
        ).thenAnswer(
          (_) async => const StravaActivityListResponse(
            activities: [
              StravaActivitySummary(
                id: 1,
                name: 'Run',
                type: 'Run',
                sportType: 'Run',
                startDate: '2024-01-15T07:00:00Z',
                elapsedTime: 3600,
                movingTime: 3400,
                kilojoules: 2510,
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

      test('fetches distance', () async {
        when(
          () => mockApiClient.fetchActivities(
            after: any(named: 'after'),
            before: any(named: 'before'),
          ),
        ).thenAnswer(
          (_) async => const StravaActivityListResponse(
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
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.distance,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<DistanceSample>());
      });

      test('fetches elevation', () async {
        when(
          () => mockApiClient.fetchActivities(
            after: any(named: 'after'),
            before: any(named: 'before'),
          ),
        ).thenAnswer(
          (_) async => const StravaActivityListResponse(
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
          ),
        );

        final records = await provider.fetchRecords(
          metricType: MetricType.elevation,
          timeRange: timeRange,
        );

        expect(records, hasLength(1));
        expect(records.first, isA<ElevationGain>());
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
