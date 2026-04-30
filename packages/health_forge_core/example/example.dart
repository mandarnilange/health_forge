// Examples print to stdout for demonstration purposes only.
// ignore_for_file: avoid_print

import 'package:health_forge_core/health_forge_core.dart';

/// Resolves overlapping heart-rate samples from two providers using the
/// priority-based conflict strategy.
void main() {
  final start = DateTime.utc(2026, 4, 30, 9);
  final end = DateTime.utc(2026, 4, 30, 9, 0, 1);

  final apple = HeartRateSample(
    id: 'apple-1',
    provider: DataProvider.apple,
    providerRecordType: 'HKQuantityTypeIdentifierHeartRate',
    startTime: start,
    endTime: end,
    capturedAt: end,
    beatsPerMinute: 62,
  );
  final oura = HeartRateSample(
    id: 'oura-1',
    provider: DataProvider.oura,
    providerRecordType: 'heart_rate',
    startTime: start,
    endTime: end,
    capturedAt: end,
    beatsPerMinute: 60,
  );

  final engine = MergeEngine(
    config: const MergeConfig(
      providerPriority: [DataProvider.apple, DataProvider.oura],
    ),
  );
  final result = engine.merge([apple, oura]);

  print('Resolved: ${result.resolved.length} record(s)');
  print('Conflicts: ${result.conflicts.length} group(s)');
  for (final conflict in result.conflicts) {
    print('  - ${conflict.metricType.name}: ${conflict.reason}');
  }
}
