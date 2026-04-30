import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_apple/health_forge_apple.dart';
import 'package:health_forge_core/health_forge_core.dart';

void main() {
  test('AppleCapabilities uses fullWindow sync', () {
    expect(
      AppleCapabilities.capabilities.syncModel,
      SyncModel.fullWindow,
    );
  });

  test('AppleCapabilities exposes expected metrics', () {
    final m = AppleCapabilities.capabilities.supportedMetrics;
    expect(m[MetricType.heartRate], AccessMode.read);
    expect(m[MetricType.sleepSession], AccessMode.read);
    expect(m[MetricType.workout], AccessMode.read);
    expect(m.length, 14);
  });
}
