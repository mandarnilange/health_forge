import 'package:health_forge_core/health_forge_core.dart';

/// Garmin Connect sleep-specific extension data.
final class GarminSleepExtension extends ProviderExtension {
  /// Creates a [GarminSleepExtension].
  GarminSleepExtension({
    this.bodyBatteryChange,
    this.stressQualifier,
  });

  /// Deserializes from JSON.
  factory GarminSleepExtension.fromJson(Map<String, dynamic> json) =>
      GarminSleepExtension(
        bodyBatteryChange: json['bodyBatteryChange'] as int?,
        stressQualifier: json['stressQualifier'] as String?,
      );

  /// Body Battery change during sleep (positive = recharged).
  final int? bodyBatteryChange;

  /// Qualitative stress level during sleep (e.g. 'low', 'medium', 'high').
  final String? stressQualifier;

  /// Identifies this extension type for registry lookup.
  String get typeKey => 'garmin_sleep';

  @override
  Map<String, dynamic> toJson() => {
        'bodyBatteryChange': bodyBatteryChange,
        'stressQualifier': stressQualifier,
      };
}
