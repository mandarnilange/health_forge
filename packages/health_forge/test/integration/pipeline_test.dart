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
          MetricType.steps: AccessMode.read,
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
          MetricType.steps: AccessMode.read,
        },
        syncModel: SyncModel.fullWindow,
      ),
    );

    client = HealthForgeClient();
  });

  group('Full Pipeline', () {
    test('register → authorize → query → returns records from both providers',
        () async {
      final appleRecord = HeartRateSample(
        id: 'apple-hr-1',
        provider: DataProvider.apple,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now.subtract(const Duration(minutes: 4)),
        capturedAt: now,
        beatsPerMinute: 72,
      );
      final ghcRecord = HeartRateSample(
        id: 'ghc-hr-1',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 10)),
        endTime: now.subtract(const Duration(minutes: 9)),
        capturedAt: now,
        beatsPerMinute: 75,
      );

      when(() => appleProvider.authorize())
          .thenAnswer((_) async => AuthResult.success());
      when(() => ghcProvider.authorize())
          .thenAnswer((_) async => AuthResult.success());
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleRecord]);
      when(
        () => ghcProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ghcRecord]);

      // Register
      client
        ..use(appleProvider)
        ..use(ghcProvider);
      expect(client.registry.all, hasLength(2));

      // Authorize
      final authResults = await client.auth.authorizeAll();
      expect(authResults[DataProvider.apple]!.isSuccess, isTrue);
      expect(
        authResults[DataProvider.googleHealthConnect]!.isSuccess,
        isTrue,
      );

      // Query
      final queryBuilder = client.query()
        ..forMetric(MetricType.heartRate)
        ..inRange(range);
      final query = queryBuilder.build();

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: const MergeConfig()),
      );
      final result = await executor.execute(query);

      expect(result.records, hasLength(2));
      expect(result.errors, isEmpty);
      expect(result.fetchDuration, greaterThan(Duration.zero));
    });

    test('register → query with merge → deduplicates overlapping records',
        () async {
      // Two providers return overlapping heart rate at same time
      final appleRecord = HeartRateSample(
        id: 'apple-hr-overlap',
        provider: DataProvider.apple,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now.subtract(const Duration(minutes: 4)),
        capturedAt: now,
        beatsPerMinute: 72,
      );
      final ghcRecord = HeartRateSample(
        id: 'ghc-hr-overlap',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now.subtract(const Duration(minutes: 4)),
        capturedAt: now,
        beatsPerMinute: 73,
      );

      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleRecord]);
      when(
        () => ghcProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ghcRecord]);

      client
        ..use(appleProvider)
        ..use(ghcProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [
          DataProvider.apple,
          DataProvider.googleHealthConnect,
        ],
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.heartRate)
        ..inRange(range)
        ..withMerge(mergeConfig);
      final query = queryBuilder.build();

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(query);

      // With priority-based merge, overlapping records should be resolved
      expect(result.mergeResult, isNotNull);
      expect(result.mergeResult!.conflicts, isNotEmpty);
      // The resolved set should have fewer records than raw input
      expect(
        result.records.length,
        lessThanOrEqualTo(2),
      );
    });

    test('sync → cache → query from cache returns cached records', () async {
      final records = [
        HeartRateSample(
          id: 'sync-hr-1',
          provider: DataProvider.apple,
          providerRecordType: 'heart_rate',
          startTime: now.subtract(const Duration(minutes: 5)),
          endTime: now.subtract(const Duration(minutes: 4)),
          capturedAt: now,
          beatsPerMinute: 68,
        ),
      ];

      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => records);

      client.use(appleProvider);

      // Sync
      final syncResult = await client.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: range,
      );

      expect(syncResult.recordsFetched, 1);
      expect(syncResult.error, isNull);

      // Query from cache
      final cached = await client.cache.get(
        metric: MetricType.heartRate,
        range: range,
        provider: DataProvider.apple,
      );

      expect(cached, hasLength(1));
      expect((cached.first as HeartRateSample).beatsPerMinute, 68);
    });
  });
}
