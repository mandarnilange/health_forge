import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/query/query_builder.dart';
import 'package:health_forge/src/query/query_executor.dart';
import 'package:health_forge/src/registry/provider_registry.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProvider extends Mock implements HealthProvider {}

class MockHealthRecord extends Mock implements HealthRecordMixin {}

final _range = TimeRange(
  start: DateTime(2024),
  end: DateTime(2024, 1, 2),
);

void main() {
  late QueryExecutor executor;
  late ProviderRegistry registry;
  late MergeEngine mergeEngine;
  late MockHealthProvider appleProvider;
  late MockHealthProvider ouraProvider;

  setUpAll(() {
    registerFallbackValue(MetricType.heartRate);
    registerFallbackValue(_range);
  });

  setUp(() {
    registry = ProviderRegistry();
    mergeEngine = MergeEngine(config: const MergeConfig());
    executor = QueryExecutor(
      registry: registry,
      mergeEngine: mergeEngine,
    );

    appleProvider = MockHealthProvider();
    when(() => appleProvider.providerType).thenReturn(DataProvider.apple);
    when(() => appleProvider.capabilities).thenReturn(
      const ProviderCapabilities(
        supportedMetrics: {
          MetricType.heartRate: AccessMode.read,
          MetricType.steps: AccessMode.read,
        },
        syncModel: SyncModel.fullWindow,
      ),
    );

    ouraProvider = MockHealthProvider();
    when(() => ouraProvider.providerType).thenReturn(DataProvider.oura);
    when(() => ouraProvider.capabilities).thenReturn(
      const ProviderCapabilities(
        supportedMetrics: {
          MetricType.sleepSession: AccessMode.read,
          MetricType.heartRate: AccessMode.read,
        },
        syncModel: SyncModel.incrementalCursor,
      ),
    );
  });

  group('QueryExecutor', () {
    test('fetches from specific provider', () async {
      registry.register(appleProvider);
      final record = MockHealthRecord();
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [record]);

      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..from(DataProvider.apple)
        ..inRange(_range);

      final result = await executor.execute(query.build());

      expect(result.records, [record]);
      expect(result.errors, isEmpty);
    });

    test(
      'fetches from all supporting providers '
      'when no provider specified',
      () async {
        registry
          ..register(appleProvider)
          ..register(ouraProvider);

        final appleRecord = MockHealthRecord();
        final ouraRecord = MockHealthRecord();

        when(
          () => appleProvider.fetchRecords(
            metricType: any(named: 'metricType'),
            timeRange: any(named: 'timeRange'),
          ),
        ).thenAnswer((_) async => [appleRecord]);
        when(
          () => ouraProvider.fetchRecords(
            metricType: any(named: 'metricType'),
            timeRange: any(named: 'timeRange'),
          ),
        ).thenAnswer((_) async => [ouraRecord]);

        final query = QueryBuilder()
          ..forMetric(MetricType.heartRate)
          ..fromAll()
          ..inRange(_range);

        final result = await executor.execute(query.build());

        expect(result.records, hasLength(2));
        expect(result.errors, isEmpty);
      },
    );

    test('captures errors without failing', () async {
      registry.register(appleProvider);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenThrow(Exception('Network error'));

      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..from(DataProvider.apple)
        ..inRange(_range);

      final result = await executor.execute(query.build());

      expect(result.records, isEmpty);
      expect(
        result.errors,
        contains(DataProvider.apple),
      );
    });

    test('captures Error subclasses without failing', () async {
      registry.register(appleProvider);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenThrow(ArgumentError('bad input'));

      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..from(DataProvider.apple)
        ..inRange(_range);

      final result = await executor.execute(query.build());

      expect(result.records, isEmpty);
      expect(result.errors[DataProvider.apple], contains('bad input'));
    });

    test('applies merge when config provided', () async {
      registry
        ..register(appleProvider)
        ..register(ouraProvider);

      final appleRecord = MockHealthRecord();
      when(() => appleRecord.provider).thenReturn(DataProvider.apple);
      when(() => appleRecord.providerRecordType).thenReturn('heart_rate');
      when(() => appleRecord.startTime).thenReturn(DateTime(2024));
      when(() => appleRecord.endTime).thenReturn(DateTime(2024, 1, 1, 0, 1));
      when(() => appleRecord.id).thenReturn('1');

      final ouraRecord = MockHealthRecord();
      when(() => ouraRecord.provider).thenReturn(DataProvider.oura);
      when(() => ouraRecord.providerRecordType).thenReturn('heart_rate');
      when(() => ouraRecord.startTime).thenReturn(DateTime(2024));
      when(() => ouraRecord.endTime).thenReturn(DateTime(2024, 1, 1, 0, 1));
      when(() => ouraRecord.id).thenReturn('2');

      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleRecord]);
      when(
        () => ouraProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ouraRecord]);

      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..fromAll()
        ..inRange(_range)
        ..withMerge(const MergeConfig());

      final result = await executor.execute(query.build());

      expect(result.mergeResult, isNotNull);
    });

    test('returns result with fetch duration', () async {
      registry.register(appleProvider);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => []);

      final query = QueryBuilder()
        ..forMetric(MetricType.heartRate)
        ..from(DataProvider.apple)
        ..inRange(_range);

      final result = await executor.execute(query.build());

      expect(result.fetchDuration, isA<Duration>());
    });
  });
}
