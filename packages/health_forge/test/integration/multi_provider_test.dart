import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/health_forge.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProvider extends Mock implements HealthProvider {}

class FakeTimeRange extends Fake implements TimeRange {}

void main() {
  late MockHealthProvider appleProvider;
  late MockHealthProvider ghcProvider;
  late HealthForgeClient client;
  final now = DateTime(2026, 3, 17, 12);
  final range = TimeRange(
    start: now.subtract(const Duration(hours: 1)),
    end: now,
  );

  setUpAll(() {
    registerFallbackValue(MetricType.heartRate);
    registerFallbackValue(FakeTimeRange());
  });

  setUp(() {
    appleProvider = MockHealthProvider();
    ghcProvider = MockHealthProvider();

    when(() => appleProvider.providerType).thenReturn(DataProvider.apple);
    when(() => appleProvider.displayName).thenReturn('Apple HealthKit');
    when(() => appleProvider.capabilities).thenReturn(
      const ProviderCapabilities(
        supportedMetrics: {
          MetricType.heartRate: AccessMode.read,
        },
        syncModel: SyncModel.fullWindow,
      ),
    );

    when(() => ghcProvider.providerType)
        .thenReturn(DataProvider.googleHealthConnect);
    when(() => ghcProvider.displayName).thenReturn('Google Health Connect');
    when(() => ghcProvider.capabilities).thenReturn(
      const ProviderCapabilities(
        supportedMetrics: {
          MetricType.heartRate: AccessMode.read,
        },
        syncModel: SyncModel.fullWindow,
      ),
    );

    client = HealthForgeClient();
  });

  group('Multi-provider error handling', () {
    test('single provider error does not break multi-provider query', () async {
      final ghcRecord = HeartRateSample(
        id: 'ghc-hr-1',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now.subtract(const Duration(minutes: 4)),
        capturedAt: now,
        beatsPerMinute: 70,
      );

      // Apple throws, GHC succeeds
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenThrow(Exception('HealthKit unavailable'));
      when(
        () => ghcProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ghcRecord]);

      client
        ..use(appleProvider)
        ..use(ghcProvider);

      final queryBuilder = client.query()
        ..forMetric(MetricType.heartRate)
        ..inRange(range);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: const MergeConfig()),
      );
      final result = await executor.execute(queryBuilder.build());

      // GHC records should still be returned
      expect(result.records, hasLength(1));
      expect(
        (result.records.first as HeartRateSample).beatsPerMinute,
        70,
      );

      // Apple error should be captured
      expect(result.errors, contains(DataProvider.apple));
      expect(
        result.errors[DataProvider.apple],
        contains('HealthKit unavailable'),
      );
    });
  });

  group('Cache round-trip', () {
    test('put records → get returns same records', () async {
      final records = [
        HeartRateSample(
          id: 'cache-hr-1',
          provider: DataProvider.apple,
          providerRecordType: 'heart_rate',
          startTime: now.subtract(const Duration(minutes: 30)),
          endTime: now.subtract(const Duration(minutes: 29)),
          capturedAt: now,
          beatsPerMinute: 65,
        ),
        HeartRateSample(
          id: 'cache-hr-2',
          provider: DataProvider.apple,
          providerRecordType: 'heart_rate',
          startTime: now.subtract(const Duration(minutes: 20)),
          endTime: now.subtract(const Duration(minutes: 19)),
          capturedAt: now,
          beatsPerMinute: 72,
        ),
      ];

      await client.cache.put(records);

      final cached = await client.cache.get(
        metric: MetricType.heartRate,
        range: range,
      );

      expect(cached, hasLength(2));

      final bpms =
          cached.cast<HeartRateSample>().map((r) => r.beatsPerMinute).toSet();
      expect(bpms, containsAll([65, 72]));
    });

    test('cache invalidation removes matching records', () async {
      final records = [
        HeartRateSample(
          id: 'inv-hr-1',
          provider: DataProvider.apple,
          providerRecordType: 'heart_rate',
          startTime: now.subtract(const Duration(minutes: 10)),
          endTime: now.subtract(const Duration(minutes: 9)),
          capturedAt: now,
          beatsPerMinute: 80,
        ),
      ];

      await client.cache.put(records);
      await client.cache.invalidate(provider: DataProvider.apple);

      final cached = await client.cache.get(
        metric: MetricType.heartRate,
        range: range,
        provider: DataProvider.apple,
      );

      expect(cached, isEmpty);
    });
  });

  group('Sync flow', () {
    test('sync fetches and caches records with correct counts', () async {
      // Use records far apart in time to avoid merge engine overlap detection
      // (default timeOverlapThresholdSeconds is 300s = 5 minutes)
      final records = [
        HeartRateSample(
          id: 'sync-hr-1',
          provider: DataProvider.apple,
          providerRecordType: 'heart_rate',
          startTime: now.subtract(const Duration(minutes: 50)),
          endTime: now.subtract(const Duration(minutes: 49)),
          capturedAt: now,
          beatsPerMinute: 68,
        ),
        HeartRateSample(
          id: 'sync-hr-2',
          provider: DataProvider.apple,
          providerRecordType: 'heart_rate',
          startTime: now.subtract(const Duration(minutes: 10)),
          endTime: now.subtract(const Duration(minutes: 9)),
          capturedAt: now,
          beatsPerMinute: 74,
        ),
      ];

      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => records);

      client.use(appleProvider);

      final syncResult = await client.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: range,
      );

      expect(syncResult.recordsFetched, 2);
      expect(syncResult.recordsCached, 2);
      expect(syncResult.error, isNull);
      expect(syncResult.duration, greaterThan(Duration.zero));

      // Verify sync metadata was updated
      final lastSync = await client.cache.lastSyncTime(
        DataProvider.apple,
        MetricType.heartRate,
      );
      expect(lastSync, isNotNull);
    });

    test('sync for unregistered provider returns error', () async {
      final syncResult = await client.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: range,
      );

      expect(syncResult.error, isNotNull);
      expect(syncResult.recordsFetched, 0);
    });
  });
}
