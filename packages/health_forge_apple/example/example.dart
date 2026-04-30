// Examples print to stdout for demonstration purposes only.
// ignore_for_file: avoid_print

import 'package:health_forge_apple/health_forge_apple.dart';

/// Constructs an Apple HealthKit provider and lists its supported metrics.
///
/// Add the HealthKit entitlement and `NSHealthShareUsageDescription` to
/// `ios/Runner/Info.plist` before authorizing in your app code.
void main() {
  final provider = AppleHealthProvider();
  final metrics = provider.capabilities.supportedMetrics;

  print('${provider.displayName} supports ${metrics.length} metric type(s):');
  for (final metric in metrics.keys) {
    print('  - ${metric.name}');
  }
}
