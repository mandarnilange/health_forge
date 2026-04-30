import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';
import 'package:mocktail/mocktail.dart';

class MockHealth extends Mock implements Health {}

void main() {
  late MockHealth mockHealth;
  late GhcHealthProvider provider;

  setUp(() {
    mockHealth = MockHealth();
    provider = GhcHealthProvider(healthPlugin: mockHealth);
  });

  group('GhcHealthProvider', () {
    test('providerType is googleHealthConnect', () {
      expect(provider.providerType, DataProvider.googleHealthConnect);
    });

    test('displayName is Google Health Connect', () {
      expect(provider.displayName, 'Google Health Connect');
    });

    test('capabilities returns GhcCapabilities', () {
      expect(provider.capabilities, GhcCapabilities.capabilities);
    });

    group('isAuthorized', () {
      test('returns true when health plugin has permissions', () async {
        when(
          () => mockHealth.hasPermissions(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => true);

        final result = await provider.isAuthorized();
        expect(result, isTrue);
      });

      test('returns false when health plugin lacks permissions', () async {
        when(
          () => mockHealth.hasPermissions(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => false);

        final result = await provider.isAuthorized();
        expect(result, isFalse);
      });

      test('returns false on exception', () async {
        when(
          () => mockHealth.hasPermissions(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenThrow(Exception('platform error'));

        final result = await provider.isAuthorized();
        expect(result, isFalse);
      });
    });

    group('authorize', () {
      test('returns success when permissions granted', () async {
        when(
          () => mockHealth.requestAuthorization(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => true);

        final result = await provider.authorize();
        expect(result.isSuccess, isTrue);
      });

      test('returns denied when permissions not granted', () async {
        when(
          () => mockHealth.requestAuthorization(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => false);

        final result = await provider.authorize();
        expect(result.isSuccess, isFalse);
      });

      test('returns error on exception', () async {
        when(
          () => mockHealth.requestAuthorization(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenThrow(Exception('auth error'));

        final result = await provider.authorize();
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('auth error'));
      });
    });

    group('deauthorize', () {
      test('calls revokePermissions on health plugin', () async {
        when(() => mockHealth.revokePermissions()).thenAnswer((_) async => {});

        await provider.deauthorize();

        verify(() => mockHealth.revokePermissions()).called(1);
      });
    });

    group('fetchRecords', () {
      test('returns empty list for unsupported metric', () async {
        final timeRange = TimeRange(
          start: DateTime.utc(2026, 3, 17),
          end: DateTime.utc(2026, 3, 18),
        );

        final result = await provider.fetchRecords(
          metricType: MetricType.readiness,
          timeRange: timeRange,
        );

        expect(result, isEmpty);
      });

      test('fetches and maps heart rate data', () async {
        final start = DateTime.utc(2026, 3, 17);
        final end = DateTime.utc(2026, 3, 18);
        final timeRange = TimeRange(start: start, end: end);

        final healthDataPoint = HealthDataPoint(
          uuid: 'test-uuid',
          value: NumericHealthValue(numericValue: 72),
          type: HealthDataType.HEART_RATE,
          unit: HealthDataUnit.BEATS_PER_MINUTE,
          dateFrom: start,
          dateTo: end,
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: 'device-1',
          sourceId: 'com.google.android.apps.fitness',
          sourceName: 'Google Fit',
          recordingMethod: RecordingMethod.automatic,
        );

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => [healthDataPoint]);

        final result = await provider.fetchRecords(
          metricType: MetricType.heartRate,
          timeRange: timeRange,
        );

        expect(result, hasLength(1));
        expect(result.first, isA<HeartRateSample>());
        final sample = result.first as HeartRateSample;
        expect(sample.beatsPerMinute, 72);
        expect(sample.provider, DataProvider.googleHealthConnect);
      });

      test('returns empty list when health plugin returns empty', () async {
        final timeRange = TimeRange(
          start: DateTime.utc(2026, 3, 17),
          end: DateTime.utc(2026, 3, 18),
        );

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => []);

        final result = await provider.fetchRecords(
          metricType: MetricType.heartRate,
          timeRange: timeRange,
        );

        expect(result, isEmpty);
      });

      test('returns empty list on exception', () async {
        final timeRange = TimeRange(
          start: DateTime.utc(2026, 3, 17),
          end: DateTime.utc(2026, 3, 18),
        );

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenThrow(Exception('fetch error'));

        final result = await provider.fetchRecords(
          metricType: MetricType.heartRate,
          timeRange: timeRange,
        );

        expect(result, isEmpty);
      });

      test('maps sleep session metrics through SleepMapper', () async {
        final start = DateTime.utc(2026, 3, 17, 22);
        final end = DateTime.utc(2026, 3, 18, 6);
        final timeRange = TimeRange(start: start, end: end);

        final light = HealthDataPoint(
          uuid: 'sleep-1',
          value: NumericHealthValue(numericValue: 0),
          type: HealthDataType.SLEEP_LIGHT,
          unit: HealthDataUnit.MINUTE,
          dateFrom: start,
          dateTo: start.add(const Duration(hours: 2)),
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: 'd1',
          sourceId: 'src',
          sourceName: 'Phone',
          recordingMethod: RecordingMethod.automatic,
        );
        final deep = HealthDataPoint(
          uuid: 'sleep-2',
          value: NumericHealthValue(numericValue: 0),
          type: HealthDataType.SLEEP_DEEP,
          unit: HealthDataUnit.MINUTE,
          dateFrom: start.add(const Duration(hours: 2)),
          dateTo: start.add(const Duration(hours: 4)),
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: 'd1',
          sourceId: 'src',
          sourceName: 'Phone',
          recordingMethod: RecordingMethod.automatic,
        );

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => [light, deep]);

        final result = await provider.fetchRecords(
          metricType: MetricType.sleepSession,
          timeRange: timeRange,
        );

        expect(result, isNotEmpty);
        expect(result.first, isA<SleepSession>());
      });

      test('maps non-numeric sleep point value to 0.0', () async {
        final start = DateTime.utc(2026, 3, 17, 22);
        final end = DateTime.utc(2026, 3, 18, 6);
        final timeRange = TimeRange(start: start, end: end);

        final point = HealthDataPoint(
          uuid: 'sleep-audio',
          value: AudiogramHealthValue(
            frequencies: const [1],
            leftEarSensitivities: const [1],
            rightEarSensitivities: const [1],
          ),
          type: HealthDataType.SLEEP_REM,
          unit: HealthDataUnit.MINUTE,
          dateFrom: start,
          dateTo: start.add(const Duration(hours: 1)),
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: 'd1',
          sourceId: 'src',
          sourceName: 'Phone',
          recordingMethod: RecordingMethod.automatic,
        );

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => [point]);

        final result = await provider.fetchRecords(
          metricType: MetricType.sleepSession,
          timeRange: timeRange,
        );

        expect(result, isNotEmpty);
      });

      test('maps steps through activity mapper', () async {
        final start = DateTime.utc(2026, 3, 17);
        final end = DateTime.utc(2026, 3, 18);
        final timeRange = TimeRange(start: start, end: end);

        final point = HealthDataPoint(
          uuid: 'steps-1',
          value: NumericHealthValue(numericValue: 5000),
          type: HealthDataType.STEPS,
          unit: HealthDataUnit.COUNT,
          dateFrom: start,
          dateTo: end,
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: 'd1',
          sourceId: 'src',
          sourceName: 'Phone',
          recordingMethod: RecordingMethod.automatic,
        );

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => [point]);

        final result = await provider.fetchRecords(
          metricType: MetricType.steps,
          timeRange: timeRange,
        );

        expect(result, hasLength(1));
        expect(result.first, isA<StepCount>());
      });

      test('maps weight through body mapper', () async {
        final start = DateTime.utc(2026, 3, 17);
        final end = DateTime.utc(2026, 3, 18);
        final timeRange = TimeRange(start: start, end: end);

        final point = HealthDataPoint(
          uuid: 'w-1',
          value: NumericHealthValue(numericValue: 70.5),
          type: HealthDataType.WEIGHT,
          unit: HealthDataUnit.KILOGRAM,
          dateFrom: start,
          dateTo: start,
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: 'd1',
          sourceId: 'src',
          sourceName: 'Phone',
          recordingMethod: RecordingMethod.automatic,
        );

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => [point]);

        final result = await provider.fetchRecords(
          metricType: MetricType.weight,
          timeRange: timeRange,
        );

        expect(result, hasLength(1));
        expect(result.first, isA<Weight>());
      });

      test('maps blood oxygen through respiratory mapper', () async {
        final start = DateTime.utc(2026, 3, 17);
        final end = DateTime.utc(2026, 3, 18);
        final timeRange = TimeRange(start: start, end: end);

        final point = HealthDataPoint(
          uuid: 'o2-1',
          value: NumericHealthValue(numericValue: 97),
          type: HealthDataType.BLOOD_OXYGEN,
          unit: HealthDataUnit.PERCENT,
          dateFrom: start,
          dateTo: start,
          sourcePlatform: HealthPlatformType.googleHealthConnect,
          sourceDeviceId: 'd1',
          sourceId: 'src',
          sourceName: 'Phone',
          recordingMethod: RecordingMethod.automatic,
        );

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => [point]);

        final result = await provider.fetchRecords(
          metricType: MetricType.bloodOxygen,
          timeRange: timeRange,
        );

        expect(result, hasLength(1));
        expect(result.first, isA<BloodOxygenSample>());
      });
    });
  });
}
