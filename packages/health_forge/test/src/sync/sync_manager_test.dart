import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/cache/cache_manager.dart';
import 'package:health_forge/src/registry/provider_registry.dart';
import 'package:health_forge/src/sync/sync_manager.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProvider extends Mock implements HealthProvider {}

class MockHealthRecord extends Mock implements HealthRecordMixin {}

MockHealthRecord _makeRecord({
  required DataProvider provider,
  required String recordType,
  required DateTime start,
  required DateTime end,
}) {
  final record = MockHealthRecord();
  when(() => record.provider).thenReturn(provider);
  when(() => record.providerRecordType).thenReturn(recordType);
  when(() => record.startTime).thenReturn(start);
  when(() => record.endTime).thenReturn(end);
  when(() => record.id).thenReturn(
    '${provider.name}_${start.millisecondsSinceEpoch}',
  );
  return record;
}

void main() {
  late SyncManager syncManager;
  late ProviderRegistry registry;
  late InMemoryCacheManager cache;
  late MergeEngine mergeEngine;
  late MockHealthProvider appleProvider;
  late MockHealthProvider ouraProvider;

  setUpAll(() {
    registerFallbackValue(MetricType.heartRate);
    registerFallbackValue(
      TimeRange(
        start: DateTime(2024),
        end: DateTime(2024, 1, 2),
      ),
    );
  });

  setUp(() {
    registry = ProviderRegistry();
    cache = InMemoryCacheManager();
    mergeEngine = MergeEngine(config: const MergeConfig());
    syncManager = SyncManager(
      registry: registry,
      cache: cache,
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

  group('SyncManager', () {
    test('sync fetches records and caches them', () async {
      registry.register(appleProvider);
      final record = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [record]);

      final range = TimeRange(
        start: DateTime(2024),
        end: DateTime(2024, 1, 2),
      );
      final result = await syncManager.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: range,
      );

      expect(result.recordsFetched, 1);
      expect(result.recordsCached, 1);
      expect(result.error, isNull);

      final cached = await cache.get(
        metric: MetricType.heartRate,
        range: range,
      );
      expect(cached, [record]);
    });

    test('sync updates sync metadata', () async {
      registry.register(appleProvider);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => []);

      await syncManager.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      final lastSync = await cache.lastSyncTime(
        DataProvider.apple,
        MetricType.heartRate,
      );
      expect(lastSync, isNotNull);
    });

    test('sync handles provider errors', () async {
      registry.register(appleProvider);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenThrow(Exception('Network error'));

      final result = await syncManager.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(result.error, isNotNull);
      expect(result.recordsFetched, 0);
    });

    test('sync returns error for unregistered provider', () async {
      final result = await syncManager.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(result.error, isNotNull);
      expect(result.error, contains('not registered'));
    });

    test('syncAll iterates over all registered providers', () async {
      registry
        ..register(appleProvider)
        ..register(ouraProvider);

      final appleRecord = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );
      final ouraRecord = _makeRecord(
        provider: DataProvider.oura,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );

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

      final results = await syncManager.syncAll(
        metrics: [MetricType.heartRate],
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(results, contains(DataProvider.apple));
      expect(results, contains(DataProvider.oura));
      expect(
        results[DataProvider.apple]!.recordsFetched,
        1,
      );
      expect(
        results[DataProvider.oura]!.recordsFetched,
        1,
      );
    });

    test(
      'syncAll aggregates metrics for the same provider into one SyncResult',
      () async {
        registry.register(appleProvider);

        final hr = HeartRateSample(
          id: 'hr-1',
          provider: DataProvider.apple,
          providerRecordType: 'heart_rate',
          startTime: DateTime(2024),
          endTime: DateTime(2024, 1, 1, 0, 5),
          capturedAt: DateTime(2024),
          beatsPerMinute: 70,
        );
        final steps = StepCount(
          id: 'st-1',
          provider: DataProvider.apple,
          providerRecordType: 'steps',
          startTime: DateTime(2024),
          endTime: DateTime(2024, 1, 1, 1),
          capturedAt: DateTime(2024),
          count: 1000,
        );

        when(
          () => appleProvider.fetchRecords(
            metricType: any(named: 'metricType'),
            timeRange: any(named: 'timeRange'),
          ),
        ).thenAnswer((invocation) async {
          final metric = invocation.namedArguments[#metricType]! as MetricType;
          if (metric == MetricType.heartRate) {
            return [hr];
          }
          if (metric == MetricType.steps) {
            return [steps];
          }
          return [];
        });

        final results = await syncManager.syncAll(
          metrics: [MetricType.heartRate, MetricType.steps],
          range: TimeRange(
            start: DateTime(2024),
            end: DateTime(2024, 1, 2),
          ),
        );

        final apple = results[DataProvider.apple]!;
        expect(apple.recordsFetched, 2);
        expect(apple.recordsCached, 2);
      },
    );

    test('syncAll only syncs providers supporting the metric', () async {
      registry
        ..register(appleProvider)
        ..register(ouraProvider);

      when(
        () => ouraProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => []);

      final results = await syncManager.syncAll(
        metrics: [MetricType.sleepSession],
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      // Only oura supports sleepSession
      expect(results, contains(DataProvider.oura));
      expect(
        results.containsKey(DataProvider.apple),
        isFalse,
      );
    });

    test('sync narrow range does not wipe records outside range', () async {
      registry.register(appleProvider);

      // Pre-populate cache with records in Jan 1-7
      final earlyRecord = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024, 1, 2),
        end: DateTime(2024, 1, 2, 0, 5),
      );
      await cache.put([earlyRecord]);

      // Sync only Jan 5-7 range
      final laterRecord = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024, 1, 5),
        end: DateTime(2024, 1, 5, 0, 5),
      );
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [laterRecord]);

      await syncManager.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024, 1, 5),
          end: DateTime(2024, 1, 7),
        ),
      );

      // Early record (Jan 2) should still be in cache
      final earlyResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 4),
        ),
      );
      expect(earlyResults, hasLength(1));
    });

    test('sync records duration', () async {
      registry.register(appleProvider);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => []);

      final result = await syncManager.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(result.duration, isA<Duration>());
    });
  });
}
