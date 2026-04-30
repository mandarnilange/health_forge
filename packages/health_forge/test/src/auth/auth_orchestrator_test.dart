import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/auth/auth_orchestrator.dart';
import 'package:health_forge/src/registry/provider_registry.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProvider extends Mock implements HealthProvider {}

void main() {
  late AuthOrchestrator orchestrator;
  late ProviderRegistry registry;
  late MockHealthProvider appleProvider;
  late MockHealthProvider ouraProvider;

  setUp(() {
    registry = ProviderRegistry();
    orchestrator = AuthOrchestrator(registry: registry);

    appleProvider = MockHealthProvider();
    when(() => appleProvider.providerType).thenReturn(DataProvider.apple);
    when(() => appleProvider.capabilities).thenReturn(
      const ProviderCapabilities(
        supportedMetrics: {
          MetricType.heartRate: AccessMode.read,
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
        },
        syncModel: SyncModel.incrementalCursor,
      ),
    );
  });

  group('AuthOrchestrator', () {
    test('authorize delegates to provider', () async {
      registry.register(appleProvider);
      when(() => appleProvider.authorize())
          .thenAnswer((_) async => AuthResult.success());

      final result = await orchestrator.authorize(DataProvider.apple);

      expect(result.isSuccess, isTrue);
      verify(() => appleProvider.authorize()).called(1);
    });

    test('authorize returns error for unregistered provider', () async {
      final result = await orchestrator.authorize(DataProvider.apple);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('not registered'));
    });

    test('deauthorize delegates to provider', () async {
      registry.register(appleProvider);
      when(() => appleProvider.deauthorize()).thenAnswer((_) async {});

      await orchestrator.deauthorize(DataProvider.apple);

      verify(() => appleProvider.deauthorize()).called(1);
    });

    test('authorizeAll authorizes all registered providers', () async {
      registry
        ..register(appleProvider)
        ..register(ouraProvider);
      when(() => appleProvider.authorize())
          .thenAnswer((_) async => AuthResult.success());
      when(() => ouraProvider.authorize())
          .thenAnswer((_) async => AuthResult.denied());

      final results = await orchestrator.authorizeAll();

      expect(
        results[DataProvider.apple]!.isSuccess,
        isTrue,
      );
      expect(
        results[DataProvider.oura]!.isSuccess,
        isFalse,
      );
    });

    test('checkAll checks authorization for all providers', () async {
      registry
        ..register(appleProvider)
        ..register(ouraProvider);
      when(() => appleProvider.isAuthorized()).thenAnswer((_) async => true);
      when(() => ouraProvider.isAuthorized()).thenAnswer((_) async => false);

      final results = await orchestrator.checkAll();

      expect(results[DataProvider.apple], isTrue);
      expect(results[DataProvider.oura], isFalse);
    });

    test('isAuthorized delegates to provider', () async {
      registry.register(appleProvider);
      when(() => appleProvider.isAuthorized()).thenAnswer((_) async => true);

      final result = await orchestrator.isAuthorized(DataProvider.apple);

      expect(result, isTrue);
    });

    test('isAuthorized returns false for unregistered provider', () async {
      final result = await orchestrator.isAuthorized(DataProvider.apple);

      expect(result, isFalse);
    });
  });
}
