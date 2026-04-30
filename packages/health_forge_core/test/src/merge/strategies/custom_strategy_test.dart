import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('CustomStrategy', () {
    final now = DateTime.utc(2026, 3, 17, 10);

    test('custom function called with correct arguments', () {
      MetricType? capturedMetric;
      List<HealthRecordMixin>? capturedRecords;

      final strategy = CustomStrategy(
        resolver: (records, metricType) {
          capturedRecords = records;
          capturedMetric = metricType;
          return [records.first];
        },
      );

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
          beatsPerMinute: 80,
        ),
      ];

      strategy.resolve(records, const MergeConfig(), MetricType.heartRate);

      expect(capturedMetric, MetricType.heartRate);
      expect(capturedRecords, hasLength(2));
    });

    test('custom function result returned', () {
      final record = HeartRateSample(
        id: 'custom-pick',
        provider: DataProvider.garmin,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        capturedAt: now,
        beatsPerMinute: 99,
      );

      final strategy = CustomStrategy(
        resolver: (records, metricType) => [record],
      );

      final result = strategy.resolve(
        [
          HeartRateSample(
            id: '1',
            provider: DataProvider.apple,
            providerRecordType: 'heartRate',
            startTime: now,
            endTime: now.add(const Duration(minutes: 1)),
            capturedAt: now,
            beatsPerMinute: 70,
          ),
        ],
        const MergeConfig(),
        MetricType.heartRate,
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'custom-pick');
    });
  });
}
