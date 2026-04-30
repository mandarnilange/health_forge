import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('KeepAllWithAttributionStrategy', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final strategy = KeepAllWithAttributionStrategy();

    test('multiple records all returned', () {
      final records = [
        HeartRateSample(
          id: '1',
          provider: DataProvider.apple,
          providerRecordType: 'heartRate',
          startTime: now,
          endTime: now.add(const Duration(minutes: 1)),
          capturedAt: now,
          beatsPerMinute: 70,
        ),
        HeartRateSample(
          id: '2',
          provider: DataProvider.oura,
          providerRecordType: 'heartRate',
          startTime: now,
          endTime: now.add(const Duration(minutes: 1)),
          capturedAt: now,
          beatsPerMinute: 75,
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

      expect(result, hasLength(3));
      expect(result, equals(records));
    });
  });
}
