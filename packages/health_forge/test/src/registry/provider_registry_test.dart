import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/registry/provider_registry.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProvider extends Mock implements HealthProvider {}

void main() {
  late ProviderRegistry registry;
  late MockHealthProvider appleProvider;
  late MockHealthProvider ouraProvider;

  setUp(() {
    registry = ProviderRegistry();

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
          MetricType.hrv: AccessMode.read,
        },
        syncModel: SyncModel.incrementalCursor,
      ),
    );
  });

  group('ProviderRegistry', () {
    test('register makes provider retrievable', () {
      registry.register(appleProvider);

      expect(
        registry.provider(DataProvider.apple),
        equals(appleProvider),
      );
      expect(registry.isRegistered(DataProvider.apple), isTrue);
    });

    test('provider returns null for unregistered provider', () {
      expect(registry.provider(DataProvider.apple), isNull);
      expect(
        registry.isRegistered(DataProvider.apple),
        isFalse,
      );
    });

    test('unregister removes provider', () {
      registry
        ..register(appleProvider)
        ..unregister(DataProvider.apple);

      expect(registry.provider(DataProvider.apple), isNull);
      expect(
        registry.isRegistered(DataProvider.apple),
        isFalse,
      );
    });

    test('all returns all registered providers', () {
      registry
        ..register(appleProvider)
        ..register(ouraProvider);

      expect(
        registry.all,
        containsAll([appleProvider, ouraProvider]),
      );
      expect(registry.all, hasLength(2));
    });

    test('all returns empty list when no providers registered', () {
      expect(registry.all, isEmpty);
    });

    test('supporting filters by metric type', () {
      registry
        ..register(appleProvider)
        ..register(ouraProvider);

      final heartRateProviders = registry.supporting(MetricType.heartRate);
      expect(heartRateProviders, [appleProvider]);

      final sleepProviders = registry.supporting(MetricType.sleepSession);
      expect(sleepProviders, [ouraProvider]);
    });

    test(
      'supporting returns empty when no provider supports metric',
      () {
        registry.register(appleProvider);

        expect(
          registry.supporting(MetricType.readiness),
          isEmpty,
        );
      },
    );

    test('duplicate registration throws StateError', () {
      registry.register(appleProvider);

      expect(
        () => registry.register(appleProvider),
        throwsA(isA<StateError>()),
      );
    });
  });
}
