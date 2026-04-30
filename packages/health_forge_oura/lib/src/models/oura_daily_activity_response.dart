/// Response DTO for the Oura API v2 `/usercollection/daily_activity` endpoint.
class OuraDailyActivityResponse {
  /// Creates a response with the given [data] and optional [nextToken].
  const OuraDailyActivityResponse({required this.data, this.nextToken});

  /// Deserializes from the Oura API JSON response.
  factory OuraDailyActivityResponse.fromJson(Map<String, dynamic> json) =>
      OuraDailyActivityResponse(
        data: (json['data'] as List<dynamic>)
            .map(
              (e) => OuraDailyActivityData.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        nextToken: json['next_token'] as String?,
      );

  /// The list of daily activity records.
  final List<OuraDailyActivityData> data;

  /// Pagination cursor for the next page, if more data exists.
  final String? nextToken;
}

/// A single daily activity summary from the Oura API.
class OuraDailyActivityData {
  /// Creates a daily activity data record.
  const OuraDailyActivityData({
    required this.id,
    required this.day,
    this.score,
    this.activeCalories,
    this.totalCalories,
    this.steps,
    this.equivalentWalkingDistance,
    this.highActivityTime,
    this.mediumActivityTime,
    this.lowActivityTime,
    this.sedentaryTime,
    this.restingTime,
    this.timestamp,
  });

  /// Deserializes from the Oura API JSON response.
  factory OuraDailyActivityData.fromJson(Map<String, dynamic> json) =>
      OuraDailyActivityData(
        id: json['id'] as String,
        day: json['day'] as String,
        score: json['score'] as int?,
        activeCalories: json['active_calories'] as int?,
        totalCalories: json['total_calories'] as int?,
        steps: json['steps'] as int?,
        equivalentWalkingDistance: json['equivalent_walking_distance'] as int?,
        highActivityTime: json['high_activity_time'] as int?,
        mediumActivityTime: json['medium_activity_time'] as int?,
        lowActivityTime: json['low_activity_time'] as int?,
        sedentaryTime: json['sedentary_time'] as int?,
        restingTime: json['resting_time'] as int?,
        timestamp: json['timestamp'] as String?,
      );

  /// Unique identifier for this record.
  final String id;

  /// The date in `YYYY-MM-DD` format.
  final String day;

  /// Overall activity score (0-100).
  final int? score;

  /// Active calories burned in kilocalories.
  final int? activeCalories;

  /// Total calories burned in kilocalories.
  final int? totalCalories;

  /// Total step count for the day.
  final int? steps;

  /// Equivalent walking distance in meters.
  final int? equivalentWalkingDistance;

  /// Duration of high-intensity activity in seconds.
  final int? highActivityTime;

  /// Duration of medium-intensity activity in seconds.
  final int? mediumActivityTime;

  /// Duration of low-intensity activity in seconds.
  final int? lowActivityTime;

  /// Duration of sedentary time in seconds.
  final int? sedentaryTime;

  /// Duration of resting time in seconds.
  final int? restingTime;

  /// ISO 8601 timestamp of the record.
  final String? timestamp;
}
