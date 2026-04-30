import 'package:health_forge_core/health_forge_core.dart';

import 'package:health_forge_example/mock/mock_data_generator.dart';

class MockOuraProvider implements HealthProvider {
  MockOuraProvider() : _generator = MockDataGenerator(DataProvider.oura);

  final MockDataGenerator _generator;
  bool _authorized = false;

  @override
  DataProvider get providerType => DataProvider.oura;

  @override
  String get displayName => 'Oura Ring (Mock)';

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
        supportedMetrics: {
          MetricType.sleepSession: AccessMode.read,
          MetricType.sleepScore: AccessMode.read,
          MetricType.heartRate: AccessMode.read,
          MetricType.readiness: AccessMode.read,
          MetricType.stress: AccessMode.read,
          MetricType.bloodOxygen: AccessMode.read,
          MetricType.steps: AccessMode.read,
          MetricType.calories: AccessMode.read,
        },
        syncModel: SyncModel.incrementalCursor,
      );

  @override
  Future<bool> isAuthorized() async => _authorized;

  @override
  Future<AuthResult> authorize() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _authorized = true;
    return AuthResult.success();
  }

  @override
  Future<void> deauthorize() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _authorized = false;
  }

  @override
  Future<List<HealthRecordMixin>> fetchRecords({
    required MetricType metricType,
    required TimeRange timeRange,
  }) async {
    if (!_authorized) return [];
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _generator.generate(metricType: metricType, timeRange: timeRange);
  }
}
