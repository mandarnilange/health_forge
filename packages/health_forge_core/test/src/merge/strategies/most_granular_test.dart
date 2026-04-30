import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('MostGranularStrategy', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final strategy = MostGranularStrategy();

    test('1-minute sample selected over 5-minute sample', () {
      final oneMin = HeartRateSample(
        id: '1',
        provider: DataProvider.apple,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        capturedAt: now,
        beatsPerMinute: 72,
      );
      final fiveMin = HeartRateSample(
        id: '2',
        provider: DataProvider.oura,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 5)),
        capturedAt: now,
        beatsPerMinute: 75,
      );

      final result = strategy.resolve(
        [fiveMin, oneMin],
        const MergeConfig(),
        MetricType.heartRate,
      );

      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('single record returned as-is', () {
      final record = HeartRateSample(
        id: '1',
        provider: DataProvider.apple,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        capturedAt: now,
        beatsPerMinute: 72,
      );

      final result = strategy.resolve(
        [record],
        const MergeConfig(),
        MetricType.heartRate,
      );

      expect(result, hasLength(1));
      expect(result.first, record);
    });
  });
}
