import 'package:health_forge_core/src/enums/access_mode.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/enums/sync_model.dart';
import 'package:health_forge_core/src/interfaces/auth_result.dart';
import 'package:health_forge_core/src/interfaces/auth_status.dart';
import 'package:health_forge_core/src/interfaces/health_provider.dart';
import 'package:health_forge_core/src/interfaces/provider_capability.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/time_range.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHealthProvider extends Mock implements HealthProvider {}

class FakeTimeRange extends Fake implements TimeRange {}

void main() {
  late MockHealthProvider provider;

  setUpAll(() {
    registerFallbackValue(MetricType.heartRate);
    registerFallbackValue(FakeTimeRange());
  });

  setUp(() {
    provider = MockHealthProvider();
  });

  group('HealthProvider', () {
    test('providerType returns expected value', () {
      when(() => provider.providerType).thenReturn(DataProvider.apple);
      expect(provider.providerType, DataProvider.apple);
    });

    test('displayName returns expected value', () {
      when(() => provider.displayName).thenReturn('Apple HealthKit');
      expect(provider.displayName, 'Apple HealthKit');
    });

    test('capabilities returns expected value', () {
      const caps = ProviderCapabilities(
        supportedMetrics: {MetricType.heartRate: AccessMode.read},
        syncModel: SyncModel.fullWindow,
      );
      when(() => provider.capabilities).thenReturn(caps);
      expect(provider.capabilities.supports(MetricType.heartRate), isTrue);
    });

    test('isAuthorized returns true when authorized', () async {
      when(() => provider.isAuthorized()).thenAnswer((_) async => true);
      expect(await provider.isAuthorized(), isTrue);
    });

    test('isAuthorized returns false when not authorized', () async {
      when(() => provider.isAuthorized()).thenAnswer((_) async => false);
      expect(await provider.isAuthorized(), isFalse);
    });

    test('authorize returns success result', () async {
      when(
        () => provider.authorize(),
      ).thenAnswer((_) async => AuthResult.success());
      final result = await provider.authorize();
      expect(result.status, AuthStatus.connected);
      expect(result.isSuccess, isTrue);
    });

    test('authorize returns denied result', () async {
      when(
        () => provider.authorize(),
      ).thenAnswer((_) async => AuthResult.denied());
      final result = await provider.authorize();
      expect(result.isSuccess, isFalse);
    });

    test('deauthorize completes', () async {
      when(() => provider.deauthorize()).thenAnswer((_) async {});
      await expectLater(provider.deauthorize(), completes);
    });

    test('fetchRecords returns list of records', () async {
      when(
        () => provider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => <HealthRecordMixin>[]);

      final records = await provider.fetchRecords(
        metricType: MetricType.heartRate,
        timeRange: FakeTimeRange(),
      );
      expect(records, isEmpty);
    });
  });
}
