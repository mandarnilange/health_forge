import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/cache/cache_manager.dart';
import 'package:health_forge/src/health_forge_client.dart';
import 'package:health_forge/src/query/query_builder.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProvider extends Mock implements HealthProvider {}

class MockHealthRecord extends Mock implements HealthRecordMixin {}

void main() {
  late HealthForgeClient client;
  late MockHealthProvider appleProvider;

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
    client = HealthForgeClient();

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
  });

  group('HealthForgeClient', () {
    test('use registers provider', () {
      client.use(appleProvider);

      expect(
        client.registry.isRegistered(DataProvider.apple),
        isTrue,
      );
    });

    test('query returns a QueryBuilder', () {
      final builder = client.query();

      expect(builder, isA<QueryBuilder>());
    });

    test('auth returns AuthOrchestrator', () {
      expect(client.auth, isNotNull);
    });

    test('cache returns CacheManager', () {
      expect(client.cache, isA<CacheManager>());
    });

    test('accepts custom merge config', () {
      const config = MergeConfig(
        defaultStrategy: ConflictStrategy.keepAll,
      );
      final customClient = HealthForgeClient(mergeConfig: config);

      expect(customClient, isNotNull);
      customClient.dispose();
    });

    test('accepts custom cache manager', () {
      final customCache = InMemoryCacheManager();
      final customClient = HealthForgeClient(cache: customCache);

      expect(customClient.cache, same(customCache));
      customClient.dispose();
    });

    test('sync delegates to SyncManager', () async {
      client.use(appleProvider);

      final record = MockHealthRecord();
      when(() => record.provider).thenReturn(DataProvider.apple);
      when(() => record.providerRecordType).thenReturn('heart_rate');
      when(() => record.startTime).thenReturn(DateTime(2024));
      when(() => record.endTime).thenReturn(DateTime(2024, 1, 1, 0, 5));
      when(() => record.id).thenReturn('1');

      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [record]);

      final result = await client.sync(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(result.recordsFetched, 1);
    });

    test('dispose completes without error', () {
      client.use(appleProvider);

      expect(client.dispose, returnsNormally);
    });
  });
}
