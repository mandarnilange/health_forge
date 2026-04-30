// Benchmarks use print to report timing results to stdout.
// ignore_for_file: avoid_print

import 'package:health_forge_core/health_forge_core.dart';

/// Benchmarks for MergeEngine and DuplicateDetector performance.
void main() {
  _benchmarkMergeEngine();
  _benchmarkDuplicateDetector();
}

void _benchmarkMergeEngine() {
  print('=== MergeEngine Benchmarks ===\n');

  final engine = MergeEngine(config: const MergeConfig());

  // Generate test data at various scales
  for (final count in [100, 1000, 5000, 10000]) {
    final records = _generateHeartRateRecords(
      count: count,
      providers: [DataProvider.apple, DataProvider.oura],
    );

    final sw = Stopwatch()..start();
    final result = engine.merge(records);
    sw.stop();

    print(
      '$count records (2 providers): '
      '${sw.elapsedMilliseconds}ms → '
      '${result.resolved.length} resolved, '
      '${result.conflicts.length} conflicts',
    );
  }

  print('');

  // Multi-provider scale test
  for (final providerCount in [2, 3, 4]) {
    final providers = DataProvider.values.take(providerCount).toList();
    final records = _generateHeartRateRecords(
      count: 1000,
      providers: providers,
    );

    final sw = Stopwatch()..start();
    final result = engine.merge(records);
    sw.stop();

    print(
      '1000 records ($providerCount providers): '
      '${sw.elapsedMilliseconds}ms → '
      '${result.resolved.length} resolved, '
      '${result.conflicts.length} conflicts',
    );
  }

  print('');

  // Strategy comparison
  for (final strategy in ConflictStrategy.values) {
    if (strategy == ConflictStrategy.custom) continue;

    final config = MergeConfig(defaultStrategy: strategy);
    final strategyEngine = MergeEngine(config: config);
    final records = _generateHeartRateRecords(
      count: 1000,
      providers: [DataProvider.apple, DataProvider.oura],
    );

    final sw = Stopwatch()..start();
    strategyEngine.merge(records);
    sw.stop();

    print('1000 records, ${strategy.name}: ${sw.elapsedMilliseconds}ms');
  }
}

void _benchmarkDuplicateDetector() {
  print('\n=== DuplicateDetector Benchmarks ===\n');

  const detector = DuplicateDetector(config: MergeConfig());

  for (final count in [100, 500, 1000, 5000]) {
    final records = _generateHeartRateRecords(
      count: count,
      providers: [DataProvider.apple],
    );

    final sw = Stopwatch()..start();
    final groups = detector.detectOverlaps(records);
    sw.stop();

    print(
      '$count records: ${sw.elapsedMilliseconds}ms → '
      '${groups.length} groups',
    );
  }
}

List<HealthRecordMixin> _generateHeartRateRecords({
  required int count,
  required List<DataProvider> providers,
}) {
  final records = <HealthRecordMixin>[];
  final baseTime = DateTime(2026);
  final perProvider = count ~/ providers.length;

  for (final provider in providers) {
    for (var i = 0; i < perProvider; i++) {
      // Space records 30 seconds apart; overlap between providers
      final time = baseTime.add(Duration(seconds: i * 30));
      records.add(
        HeartRateSample(
          id: IdGenerator.generate(),
          provider: provider,
          providerRecordType: 'heart_rate',
          startTime: time,
          endTime: time.add(const Duration(seconds: 5)),
          capturedAt: DateTime.now(),
          beatsPerMinute: 60 + (i % 40),
        ),
      );
    }
  }
  return records;
}
