import 'package:health_forge_core/src/enums/access_mode.dart';
import 'package:health_forge_core/src/enums/data_origin.dart';
import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/enums/sync_model.dart';

/// Describes the capabilities of a health data provider.
class ProviderCapabilities {
  /// Creates provider capabilities.
  const ProviderCapabilities({
    required this.supportedMetrics,
    required this.syncModel,
  });

  /// Map of supported metric types to their access modes.
  final Map<MetricType, AccessMode> supportedMetrics;

  /// How this provider syncs data.
  final SyncModel syncModel;

  /// Whether the provider supports the given [metric].
  bool supports(MetricType metric) => supportedMetrics.containsKey(metric);

  /// Returns the access mode for [metric], or null if unsupported.
  AccessMode? accessMode(MetricType metric) => supportedMetrics[metric];

  /// Returns the data origin for [metric]. Defaults to [DataOrigin.native_].
  DataOrigin dataOriginFor(MetricType metric) => DataOrigin.native_;
}
