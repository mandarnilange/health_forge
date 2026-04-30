/// Response DTO for the Strava API `/activities/{id}` endpoint.
class StravaActivityDetailResponse {
  /// Creates a detailed activity response.
  const StravaActivityDetailResponse({
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
    this.calories,
    this.averageHeartrate,
    this.maxHeartrate,
    this.sufferScore,
    this.hasHeartrate,
    this.segmentEfforts,
    this.mapPolyline,
    this.mapSummaryPolyline,
    this.timezone,
  });

  /// Deserializes from the Strava API JSON response.
  factory StravaActivityDetailResponse.fromJson(Map<String, dynamic> json) =>
      StravaActivityDetailResponse(
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
        calories: (json['calories'] as num?)?.toDouble(),
        averageHeartrate: (json['average_heartrate'] as num?)?.toDouble(),
        maxHeartrate: json['max_heartrate'] as int?,
        sufferScore: json['suffer_score'] as int?,
        hasHeartrate: json['has_heartrate'] as bool?,
        segmentEfforts: (json['segment_efforts'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>(),
        mapPolyline:
            (json['map'] as Map<String, dynamic>?)?['polyline'] as String?,
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

  /// Estimated calories burned.
  final double? calories;

  /// Average heart rate in BPM.
  final double? averageHeartrate;

  /// Maximum heart rate in BPM.
  final int? maxHeartrate;

  /// Strava suffer score (relative effort).
  final int? sufferScore;

  /// Whether the activity has heart rate data.
  final bool? hasHeartrate;

  /// Segment effort details.
  final List<Map<String, dynamic>>? segmentEfforts;

  /// Full-resolution polyline of the activity route.
  final String? mapPolyline;

  /// Simplified polyline of the activity route.
  final String? mapSummaryPolyline;

  /// IANA timezone of the activity start location.
  final String? timezone;
}
