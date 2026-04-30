import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('AverageStrategy', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final strategy = AverageStrategy();

    test('two HeartRateSamples averaged', () {
      final a = HeartRateSample(
        id: '1',
        provider: DataProvider.apple,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        capturedAt: now,
        beatsPerMinute: 70,
      );
      final b = HeartRateSample(
        id: '2',
        provider: DataProvider.oura,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        capturedAt: now,
        beatsPerMinute: 80,
      );

      final result = strategy.resolve(
        [a, b],
        const MergeConfig(),
        MetricType.heartRate,
      );

      expect(result, hasLength(1));
      final hr = result.first as HeartRateSample;
      expect(hr.beatsPerMinute, 75);
    });

    test('three HeartRateSamples averaged', () {
      final records = [
        HeartRateSample(
          id: '1',
          provider: DataProvider.apple,
          providerRecordType: 'heartRate',
          startTime: now,
          endTime: now.add(const Duration(minutes: 1)),
          capturedAt: now,
          beatsPerMinute: 60,
        ),
        HeartRateSample(
          id: '2',
          provider: DataProvider.oura,
          providerRecordType: 'heartRate',
          startTime: now,
          endTime: now.add(const Duration(minutes: 1)),
          capturedAt: now,
          beatsPerMinute: 70,
        ),
        HeartRateSample(
          id: '3',
          provider: DataProvider.garmin,
          providerRecordType: 'heartRate',
          startTime: now,
          endTime: now.add(const Duration(minutes: 1)),
          capturedAt: now,
          beatsPerMinute: 80,
        ),
      ];

      final result = strategy.resolve(
        records,
        const MergeConfig(),
        MetricType.heartRate,
      );

      expect(result, hasLength(1));
      final hr = result.first as HeartRateSample;
      expect(hr.beatsPerMinute, 70);
    });

    test('non-numeric record falls back to first', () {
      final records = [
        SleepSession(
          id: '1',
          provider: DataProvider.apple,
          providerRecordType: 'sleep',
          startTime: now,
          endTime: now.add(const Duration(hours: 8)),
          capturedAt: now,
        ),
        SleepSession(
          id: '2',
          provider: DataProvider.oura,
          providerRecordType: 'sleep',
          startTime: now,
          endTime: now.add(const Duration(hours: 8)),
          capturedAt: now,
        ),
      ];

      final result = strategy.resolve(
        records,
        const MergeConfig(),
        MetricType.sleepSession,
      );

      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });
  });
}
