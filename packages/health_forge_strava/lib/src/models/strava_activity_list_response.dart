/// Response DTO for the Strava API `/athlete/activities` endpoint.
///
/// Unlike most APIs, Strava returns a bare JSON array rather than a wrapped
/// object like `{"data": [...]}`.
class StravaActivityListResponse {
  /// Creates a list response with the given [activities].
  const StravaActivityListResponse({required this.activities});

  /// Deserializes from the Strava API JSON array response.
  factory StravaActivityListResponse.fromJson(List<dynamic> json) =>
      StravaActivityListResponse(
        activities: json
            .map(
              (e) => StravaActivitySummary.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  /// The list of activity summaries.
  final List<StravaActivitySummary> activities;
}

/// A single activity summary from the Strava API list endpoint.
class StravaActivitySummary {
  /// Creates an activity summary.
  const StravaActivitySummary({
    required this.id,
    required this.name,
    required this.type,
    required this.sportType,
    required this.startDate,
    required this.elapsedTime,
    required this.movingTime,
    this.distance,
    this.totalElevationGain,
    this.kilojoules,
    this.averageHeartrate,
    this.maxHeartrate,
    this.sufferScore,
    this.hasHeartrate,
    this.mapSummaryPolyline,
    this.timezone,
  });

  /// Deserializes from the Strava API JSON response.
  factory StravaActivitySummary.fromJson(Map<String, dynamic> json) =>
      StravaActivitySummary(
        id: json['id'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        sportType: json['sport_type'] as String,
        startDate: json['start_date'] as String,
        elapsedTime: json['elapsed_time'] as int,
        movingTime: json['moving_time'] as int,
        distance: (json['distance'] as num?)?.toDouble(),
        totalElevationGain: (json['total_elevation_gain'] as num?)?.toDouble(),
        kilojoules: (json['kilojoules'] as num?)?.toDouble(),
        averageHeartrate: (json['average_heartrate'] as num?)?.toDouble(),
        maxHeartrate: json['max_heartrate'] as int?,
        sufferScore: json['suffer_score'] as int?,
        hasHeartrate: json['has_heartrate'] as bool?,
        mapSummaryPolyline: (json['map']
            as Map<String, dynamic>?)?['summary_polyline'] as String?,
        timezone: json['timezone'] as String?,
      );

  /// Unique Strava activity identifier.
  final int id;

  /// User-given name of the activity.
  final String name;

  /// Activity type (e.g. `Run`, `Ride`).
  final String type;

  /// Sport type (e.g. `TrailRun`, `GravelRide`).
  final String sportType;

  /// ISO 8601 start date of the activity.
  final String startDate;

  /// Total elapsed time in seconds.
  final int elapsedTime;

  /// Active moving time in seconds.
  final int movingTime;

  /// Total distance in meters.
  final double? distance;

  /// Total elevation gain in meters.
  final double? totalElevationGain;

  /// Energy output in kilojoules (power-meter activities).
  final double? kilojoules;

  /// Average heart rate in BPM.
  final double? averageHeartrate;

  /// Maximum heart rate in BPM.
  final int? maxHeartrate;

  /// Strava suffer score (relative effort).
  final int? sufferScore;

  /// Whether the activity has heart rate data.
  final bool? hasHeartrate;

  /// Simplified polyline of the activity route.
  final String? mapSummaryPolyline;

  /// IANA timezone of the activity start location.
  final String? timezone;
}
