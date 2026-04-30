import 'package:health_forge_core/health_forge_core.dart';

import 'package:health_forge_example/mock/mock_data_generator.dart';

class MockStravaProvider implements HealthProvider {
  MockStravaProvider() : _generator = MockDataGenerator(DataProvider.strava);

  final MockDataGenerator _generator;
  bool _authorized = false;

  @override
  DataProvider get providerType => DataProvider.strava;

  @override
  String get displayName => 'Strava (Mock)';

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
        supportedMetrics: {
          MetricType.workout: AccessMode.read,
          MetricType.heartRate: AccessMode.read,
          MetricType.calories: AccessMode.read,
          MetricType.distance: AccessMode.read,
          MetricType.elevation: AccessMode.read,
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
