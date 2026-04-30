import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/query/query_builder.dart';
import 'package:health_forge_core/health_forge_core.dart';

void main() {
  group('QueryBuilder', () {
    late TimeRange range;

    setUp(() {
      range = TimeRange(
        start: DateTime(2024),
        end: DateTime(2024, 1, 2),
      );
    });

    test('builds query for single metric', () {
      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..inRange(range);

      final built = query.build();

      expect(built.metrics, [MetricType.heartRate]);
      expect(built.timeRange, range);
      expect(built.providers, isNull);
      expect(built.mergeConfig, isNull);
    });

    test('builds query for multiple metrics', () {
      final query = QueryBuilder()
        ..forMetrics([MetricType.heartRate, MetricType.steps])
        ..inRange(range);

      expect(query.build().metrics, [
        MetricType.heartRate,
        MetricType.steps,
      ]);
    });

    test('builds query from specific provider', () {
      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..from(DataProvider.apple)
        ..inRange(range);

      expect(query.build().providers, [DataProvider.apple]);
    });

    test('builds query from multiple specific providers', () {
      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..fromProviders([DataProvider.apple, DataProvider.oura])
        ..inRange(range);

      expect(query.build().providers, [
        DataProvider.apple,
        DataProvider.oura,
      ]);
    });

    test('builds query from all providers', () {
      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..fromAll()
        ..inRange(range);

      expect(query.build().providers, isNull);
    });

    test('builds query with merge config', () {
      const config = MergeConfig();
      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..inRange(range)
        ..withMerge(config);

      expect(query.build().mergeConfig, config);
    });

    test('build throws when no metrics set', () {
      final query = QueryBuilder()..inRange(range);

      expect(query.build, throwsA(isA<StateError>()));
    });

    test('build throws when no time range set', () {
      final query = QueryBuilder()..forMetric(MetricType.heartRate);

      expect(query.build, throwsA(isA<StateError>()));
    });
  });
}
