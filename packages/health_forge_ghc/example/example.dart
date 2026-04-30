// Examples print to stdout for demonstration purposes only.
// ignore_for_file: avoid_print

import 'package:health_forge_ghc/health_forge_ghc.dart';

/// Constructs a Google Health Connect provider and lists its supported metrics.
///
/// Add the required Health Connect read permissions to
/// `android/app/src/main/AndroidManifest.xml` before authorizing in your
/// app code.
void main() {
  final provider = GhcHealthProvider();
  final metrics = provider.capabilities.supportedMetrics;

  print('${provider.displayName} supports ${metrics.length} metric type(s):');
  for (final metric in metrics.keys) {
    print('  - ${metric.name}');
  }
}
