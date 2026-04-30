import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';

void main() {
  test('GhcCapabilities uses fullWindow sync', () {
    expect(GhcCapabilities.capabilities.syncModel, SyncModel.fullWindow);
  });

  test('GhcCapabilities exposes expected metrics', () {
    final m = GhcCapabilities.capabilities.supportedMetrics;
    expect(m[MetricType.steps], AccessMode.read);
    expect(m[MetricType.bloodGlucose], AccessMode.read);
    expect(m.length, 14);
  });
}
