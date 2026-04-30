import 'package:health_forge_core/health_forge_core.dart';

/// Declares the metrics and sync model supported by the Oura Ring API.
class OuraCapabilities {
  const OuraCapabilities._();

  /// The full set of Oura Ring capabilities exposed by this adapter.
  static const capabilities = ProviderCapabilities(
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
}
