import 'package:health_forge_core/health_forge_core.dart';

/// Declares the metrics and sync model supported by the Strava API.
class StravaCapabilities {
  const StravaCapabilities._();

  /// The full set of Strava capabilities exposed by this adapter.
  static const capabilities = ProviderCapabilities(
    supportedMetrics: {
      MetricType.workout: AccessMode.read,
      MetricType.heartRate: AccessMode.read,
      MetricType.calories: AccessMode.read,
      MetricType.distance: AccessMode.read,
      MetricType.elevation: AccessMode.read,
    },
    syncModel: SyncModel.fullWindow,
  );
}
