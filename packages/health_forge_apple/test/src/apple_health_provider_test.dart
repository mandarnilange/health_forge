import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:health_forge_apple/health_forge_apple.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockHealth extends Mock implements Health {}

void main() {
  late MockHealth mockHealth;
  late AppleHealthProvider provider;

  setUp(() {
    mockHealth = MockHealth();
    provider = AppleHealthProvider(healthPlugin: mockHealth);
  });

  group('AppleHealthProvider', () {
    test('providerType is apple', () {
      expect(provider.providerType, DataProvider.apple);
    });

    test('displayName is Apple HealthKit', () {
      expect(provider.displayName, 'Apple HealthKit');
    });

    test('capabilities returns AppleCapabilities', () {
      expect(provider.capabilities.supportedMetrics.length, 14);
      expect(
        provider.capabilities.syncModel,
        SyncModel.fullWindow,
      );
    });

    group('isAuthorized', () {
      test('returns true when permissions granted', () async {
        when(() => mockHealth.hasPermissions(any()))
            .thenAnswer((_) async => true);

        final result = await provider.isAuthorized();

        expect(result, isTrue);
      });

      test('returns false when permissions denied', () async {
        when(() => mockHealth.hasPermissions(any()))
            .thenAnswer((_) async => false);

        final result = await provider.isAuthorized();

        expect(result, isFalse);
      });

      test('returns false when permissions null', () async {
        when(() => mockHealth.hasPermissions(any()))
            .thenAnswer((_) async => null);

        final result = await provider.isAuthorized();

        expect(result, isFalse);
      });
    });

    group('authorize', () {
      test('returns success when authorization granted', () async {
        when(() => mockHealth.requestAuthorization(any()))
            .thenAnswer((_) async => true);

        final result = await provider.authorize();

        expect(result.isSuccess, isTrue);
      });

      test('returns denied when authorization not granted', () async {
        when(() => mockHealth.requestAuthorization(any()))
            .thenAnswer((_) async => false);

        final result = await provider.authorize();

        expect(result.isSuccess, isFalse);
      });

      test('returns error on exception', () async {
        when(() => mockHealth.requestAuthorization(any()))
            .thenThrow(Exception('HealthKit unavailable'));

        final result = await provider.authorize();

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('HealthKit unavailable'));
      });
    });

    group('deauthorize', () {
      test('completes without error', () async {
        await expectLater(provider.deauthorize(), completes);
      });
    });

    group('fetchRecords', () {
      test('returns empty list for unsupported metric', () async {
        final result = await provider.fetchRecords(
          metricType: MetricType.readiness,
          timeRange: TimeRange(
            start: DateTime(2024, 6),
            end: DateTime(2024, 6, 2),
          ),
        );

        expect(result, isEmpty);
      });

      test('fetches and maps heart rate data', () async {
        final start = DateTime(2024, 6, 15, 10);
        final end = DateTime(2024, 6, 15, 10, 5);

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer(
          (_) async => [
            HealthDataPoint(
              uuid: 'hr-1',
              value: NumericHealthValue(numericValue: 72),
              type: HealthDataType.HEART_RATE,
              unit: HealthDataUnit.BEATS_PER_MINUTE,
              dateFrom: start,
              dateTo: end,
              sourcePlatform: HealthPlatformType.appleHealth,
              sourceDeviceId: 'device-1',
              sourceId: 'com.apple.health',
              sourceName: 'Apple Watch',
            ),
          ],
        );

        final result = await provider.fetchRecords(
          metricType: MetricType.heartRate,
          timeRange: TimeRange(start: start, end: end),
        );

        expect(result, hasLength(1));
        expect(result.first, isA<HeartRateSample>());
        final hr = result.first as HeartRateSample;
        expect(hr.beatsPerMinute, 72);
        expect(hr.provider, DataProvider.apple);
      });

      test('fetches and maps step data', () async {
        final start = DateTime(2024, 6, 15);
        final end = DateTime(2024, 6, 16);

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer(
          (_) async => [
            HealthDataPoint(
              uuid: 'steps-1',
              value: NumericHealthValue(numericValue: 5000),
              type: HealthDataType.STEPS,
              unit: HealthDataUnit.COUNT,
              dateFrom: start,
              dateTo: end,
              sourcePlatform: HealthPlatformType.appleHealth,
              sourceDeviceId: 'device-1',
              sourceId: 'com.apple.health',
              sourceName: 'iPhone',
            ),
          ],
        );

        final result = await provider.fetchRecords(
          metricType: MetricType.steps,
          timeRange: TimeRange(start: start, end: end),
        );

        expect(result, hasLength(1));
        expect(result.first, isA<StepCount>());
        expect((result.first as StepCount).count, 5000);
      });

      test('fetches and pairs blood pressure data', () async {
        final start = DateTime(2024, 6, 15, 8);
        final end = DateTime(2024, 6, 15, 8, 1);

        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer(
          (_) async => [
            HealthDataPoint(
              uuid: 'bp-sys-1',
              value: NumericHealthValue(numericValue: 120),
              type: HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
              unit: HealthDataUnit.MILLIMETER_OF_MERCURY,
              dateFrom: start,
              dateTo: end,
              sourcePlatform: HealthPlatformType.appleHealth,
              sourceDeviceId: 'device-1',
              sourceId: 'com.omron',
              sourceName: 'Omron',
            ),
            HealthDataPoint(
              uuid: 'bp-dia-1',
              value: NumericHealthValue(numericValue: 80),
              type: HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
              unit: HealthDataUnit.MILLIMETER_OF_MERCURY,
              dateFrom: start,
              dateTo: end,
              sourcePlatform: HealthPlatformType.appleHealth,
              sourceDeviceId: 'device-1',
              sourceId: 'com.omron',
              sourceName: 'Omron',
            ),
          ],
        );

        final result = await provider.fetchRecords(
          metricType: MetricType.bloodPressure,
          timeRange: TimeRange(start: start, end: end),
        );

        expect(result, hasLength(1));
        expect(result.first, isA<BloodPressure>());
        final bp = result.first as BloodPressure;
        expect(bp.systolicMmHg, 120);
        expect(bp.diastolicMmHg, 80);
      });

      test('returns empty list when no data', () async {
        when(
          () => mockHealth.getHealthDataFromTypes(
            types: any(named: 'types'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer((_) async => []);

        final result = await provider.fetchRecords(
          metricType: MetricType.heartRate,
          timeRange: TimeRange(
            start: DateTime(2024, 6),
            end: DateTime(2024, 6, 2),
          ),
        );

        expect(result, isEmpty);
      });
    });
  });
}
