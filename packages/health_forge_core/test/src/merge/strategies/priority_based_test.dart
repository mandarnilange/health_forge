import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('PriorityBasedStrategy', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final strategy = PriorityBasedStrategy();

    HeartRateSample makeHR({
      required String id,
      required DataProvider provider,
      int bpm = 72,
    }) =>
        HeartRateSample(
          id: id,
          provider: provider,
          providerRecordType: 'heartRate',
          startTime: now,
          endTime: now.add(const Duration(minutes: 1)),
          capturedAt: now,
          beatsPerMinute: bpm,
        );

    test('Oura prioritized over Apple selects Oura record', () {
      final apple = makeHR(id: '1', provider: DataProvider.apple, bpm: 70);
      final oura = makeHR(id: '2', provider: DataProvider.oura, bpm: 75);

      const config = MergeConfig(
        providerPriority: [DataProvider.oura, DataProvider.apple],
      );

      final result = strategy.resolve(
        [apple, oura],
        config,
        MetricType.heartRate,
      );

      expect(result, hasLength(1));
      expect(result.first.provider, DataProvider.oura);
    });

    test('no priority configured keeps first record', () {
      final apple = makeHR(id: '1', provider: DataProvider.apple);
      final oura = makeHR(id: '2', provider: DataProvider.oura);

      const config = MergeConfig();

      final result = strategy.resolve(
        [apple, oura],
        config,
        MetricType.heartRate,
      );

      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('single record returned as-is', () {
      final record = makeHR(id: '1', provider: DataProvider.apple);

      const config = MergeConfig();

      final result = strategy.resolve(
        [record],
        config,
        MetricType.heartRate,
      );

      expect(result, hasLength(1));
      expect(result.first, record);
    });

    test('per-metric priority overrides default', () {
      final apple = makeHR(id: '1', provider: DataProvider.apple, bpm: 70);
      final oura = makeHR(id: '2', provider: DataProvider.oura, bpm: 75);

      const config = MergeConfig(
        providerPriority: [DataProvider.apple, DataProvider.oura],
        perMetricPriority: {
          MetricType.heartRate: [DataProvider.oura, DataProvider.apple],
        },
      );

      final result = strategy.resolve(
        [apple, oura],
        config,
        MetricType.heartRate,
      );

      expect(result.first.provider, DataProvider.oura);
    });
  });
}
