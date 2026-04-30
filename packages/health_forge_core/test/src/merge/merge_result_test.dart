import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('MergeResult', () {
    final now = DateTime.utc(2026, 3, 17, 10);

    test('constructs with required fields', () {
      final record = HeartRateSample(
        id: '1',
        provider: DataProvider.apple,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        capturedAt: now,
        beatsPerMinute: 72,
      );

      final result = MergeResult(
        resolved: [record],
        conflicts: [],
        rawSources: [record],
      );

      expect(result.resolved, hasLength(1));
      expect(result.conflicts, isEmpty);
      expect(result.rawSources, hasLength(1));
    });

    test('empty result has no records or conflicts', () {
      const result = MergeResult(
        resolved: [],
        conflicts: [],
        rawSources: [],
      );

      expect(result.resolved, isEmpty);
      expect(result.conflicts, isEmpty);
      expect(result.rawSources, isEmpty);
    });
  });

  group('ConflictReport', () {
    final now = DateTime.utc(2026, 3, 17, 10);

    test('constructs with all fields', () {
      final record = HeartRateSample(
        id: '1',
        provider: DataProvider.apple,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        capturedAt: now,
        beatsPerMinute: 72,
      );

      final report = ConflictReport(
        metricType: MetricType.heartRate,
        strategy: ConflictStrategy.priorityBased,
        inputRecords: [record],
        resolvedRecord: record,
        reason: 'Higher priority provider',
      );

      expect(report.metricType, MetricType.heartRate);
      expect(report.strategy, ConflictStrategy.priorityBased);
      expect(report.inputRecords, hasLength(1));
      expect(report.resolvedRecord, isNotNull);
      expect(report.reason, 'Higher priority provider');
    });

    test('resolvedRecord can be null', () {
      const report = ConflictReport(
        metricType: MetricType.steps,
        strategy: ConflictStrategy.custom,
        inputRecords: [],
        resolvedRecord: null,
        reason: 'No resolution found',
      );

      expect(report.resolvedRecord, isNull);
    });
  });
}
