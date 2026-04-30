import 'package:health_forge_core/health_forge_core.dart';

import 'package:health_forge_example/mock/mock_data_generator.dart';

class MockAppleProvider implements HealthProvider {
  MockAppleProvider() : _generator = MockDataGenerator(DataProvider.apple);

  final MockDataGenerator _generator;
  bool _authorized = false;

  @override
  DataProvider get providerType => DataProvider.apple;

  @override
  String get displayName => 'Apple Health (Mock)';

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
        supportedMetrics: {
          MetricType.heartRate: AccessMode.readWrite,
          MetricType.steps: AccessMode.readWrite,
          MetricType.sleepSession: AccessMode.readWrite,
          MetricType.hrv: AccessMode.read,
          MetricType.restingHeartRate: AccessMode.read,
          MetricType.bloodOxygen: AccessMode.read,
          MetricType.respiratoryRate: AccessMode.read,
          MetricType.weight: AccessMode.readWrite,
          MetricType.bodyFat: AccessMode.readWrite,
          MetricType.bloodPressure: AccessMode.readWrite,
          MetricType.bloodGlucose: AccessMode.readWrite,
          MetricType.calories: AccessMode.read,
          MetricType.distance: AccessMode.read,
          MetricType.workout: AccessMode.read,
        },
        syncModel: SyncModel.fullWindow,
      );

  @override
  Future<bool> isAuthorized() async => _authorized;

  @override
  Future<AuthResult> authorize() async {
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
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _generator.generate(metricType: metricType, timeRange: timeRange);
  }
}
