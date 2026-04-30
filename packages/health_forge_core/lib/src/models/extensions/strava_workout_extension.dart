import 'package:health_forge_core/health_forge_core.dart';

/// Strava workout-specific extension data.
final class StravaWorkoutExtension extends ProviderExtension {
  /// Creates a [StravaWorkoutExtension].
  StravaWorkoutExtension({
    this.sufferScore,
    this.segmentEfforts,
    this.routePolyline,
  });

  /// Deserializes from JSON.
  factory StravaWorkoutExtension.fromJson(Map<String, dynamic> json) =>
      StravaWorkoutExtension(
        sufferScore: json['sufferScore'] as int?,
        segmentEfforts: (json['segmentEfforts'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>(),
        routePolyline: json['routePolyline'] as String?,
      );

  /// Strava relative effort / suffer score.
  final int? sufferScore;

  /// Segment effort details from the activity.
  final List<Map<String, dynamic>>? segmentEfforts;

  /// Encoded polyline of the route.
  final String? routePolyline;

  /// Identifies this extension type for registry lookup.
  String get typeKey => 'strava_workout';

  @override
  Map<String, dynamic> toJson() => {
    'sufferScore': sufferScore,
    'segmentEfforts': segmentEfforts,
    'routePolyline': routePolyline,
  };
}
