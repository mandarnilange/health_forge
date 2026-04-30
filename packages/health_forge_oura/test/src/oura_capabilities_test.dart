import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/health_forge_oura.dart';

void main() {
  test('OuraCapabilities uses incremental cursor sync', () {
    expect(
      OuraCapabilities.capabilities.syncModel,
      SyncModel.incrementalCursor,
    );
  });

  test('OuraCapabilities exposes expected metrics', () {
    final m = OuraCapabilities.capabilities.supportedMetrics;
    expect(m[MetricType.sleepSession], AccessMode.read);
    expect(m[MetricType.readiness], AccessMode.read);
    expect(m.length, 8);
  });
}
