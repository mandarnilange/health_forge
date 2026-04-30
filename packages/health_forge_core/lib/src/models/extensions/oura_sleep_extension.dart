import 'package:health_forge_core/health_forge_core.dart';

/// Oura Ring sleep-specific extension data.
final class OuraSleepExtension extends ProviderExtension {
  /// Creates an [OuraSleepExtension].
  OuraSleepExtension({
    this.readinessScore,
    this.temperatureDeviation,
    this.readinessContributorSleep,
  });

  /// Deserializes from JSON.
  factory OuraSleepExtension.fromJson(Map<String, dynamic> json) =>
      OuraSleepExtension(
        readinessScore: json['readinessScore'] as int?,
        temperatureDeviation:
            (json['temperatureDeviation'] as num?)?.toDouble(),
        readinessContributorSleep: json['readinessContributorSleep'] as int?,
      );

  /// Overall readiness score (0–100).
  final int? readinessScore;

  /// Skin temperature deviation from baseline in °C.
  final double? temperatureDeviation;

  /// Readiness contributor: sleep sub-score.
  final int? readinessContributorSleep;

  /// Identifies this extension type for registry lookup.
  String get typeKey => 'oura_sleep';

  @override
  Map<String, dynamic> toJson() => {
        'readinessScore': readinessScore,
        'temperatureDeviation': temperatureDeviation,
        'readinessContributorSleep': readinessContributorSleep,
      };
}
