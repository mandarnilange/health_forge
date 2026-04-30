import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_example/mock/mock_data_generator.dart';

void main() {
  final range = TimeRange(
    start: DateTime.utc(2024, 6),
    end: DateTime.utc(2024, 6, 2, 23, 59),
  );

  group('MockDataGenerator', () {
    test('generate returns data for every supported dashboard metric', () {
      final gen = MockDataGenerator(DataProvider.apple);
      const supported = [
        MetricType.heartRate,
        MetricType.steps,
        MetricType.sleepSession,
        MetricType.readiness,
        MetricType.calories,
        MetricType.bloodOxygen,
        MetricType.stress,
        MetricType.sleepScore,
        MetricType.hrv,
        MetricType.restingHeartRate,
        MetricType.respiratoryRate,
        MetricType.weight,
        MetricType.distance,
        MetricType.elevation,
        MetricType.workout,
      ];

      for (final m in supported) {
        final records = gen.generate(metricType: m, timeRange: range);
        expect(records, isNotEmpty, reason: '$m should yield records');
        expect(records.every((r) => r.provider == DataProvider.apple), isTrue);
      }
    });

    test('generate returns empty for unsupported metrics', () {
      final gen = MockDataGenerator(DataProvider.oura);
      expect(
        gen.generate(metricType: MetricType.bloodPressure, timeRange: range),
        isEmpty,
      );
      expect(
        gen.generate(metricType: MetricType.bodyFat, timeRange: range),
        isEmpty,
      );
    });

    test('heart rate samples use plausible BPM', () {
      final gen = MockDataGenerator(DataProvider.strava);
      final records = gen.generate(
        metricType: MetricType.heartRate,
        timeRange: range,
      );
      expect(records, isNotEmpty);
      final first = records.first as HeartRateSample;
      expect(first.beatsPerMinute, inInclusiveRange(60, 100));
    });
  });
}
