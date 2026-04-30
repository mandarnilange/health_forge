import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/health_forge_strava.dart';

void main() {
  test('StravaCapabilities uses fullWindow sync', () {
    expect(StravaCapabilities.capabilities.syncModel, SyncModel.fullWindow);
  });

  test('StravaCapabilities exposes five metrics', () {
    final m = StravaCapabilities.capabilities.supportedMetrics;
    expect(m.length, 5);
    expect(m[MetricType.workout], AccessMode.read);
    expect(m[MetricType.elevation], AccessMode.read);
  });
}
