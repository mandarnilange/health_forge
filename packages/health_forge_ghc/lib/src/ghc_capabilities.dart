import 'package:health_forge_core/health_forge_core.dart';

/// Declares the metrics and sync model supported by Google Health Connect.
class GhcCapabilities {
  const GhcCapabilities._();

  /// The full set of Health Connect capabilities exposed by this adapter.
  static const capabilities = ProviderCapabilities(
    supportedMetrics: {
      MetricType.heartRate: AccessMode.read,
      MetricType.hrv: AccessMode.read,
      MetricType.restingHeartRate: AccessMode.read,
      MetricType.steps: AccessMode.read,
      MetricType.calories: AccessMode.read,
      MetricType.distance: AccessMode.read,
      MetricType.workout: AccessMode.read,
      MetricType.sleepSession: AccessMode.read,
      MetricType.weight: AccessMode.read,
      MetricType.bodyFat: AccessMode.read,
      MetricType.bloodPressure: AccessMode.read,
      MetricType.bloodGlucose: AccessMode.read,
      MetricType.bloodOxygen: AccessMode.read,
      MetricType.respiratoryRate: AccessMode.read,
    },
    syncModel: SyncModel.fullWindow,
  );
}
