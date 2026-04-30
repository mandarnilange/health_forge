/// Response DTO for the Oura API v2 `/usercollection/daily_readiness` endpoint.
class OuraDailyReadinessResponse {
  /// Creates a response with the given [data] and optional [nextToken].
  const OuraDailyReadinessResponse({required this.data, this.nextToken});

  /// Deserializes from the Oura API JSON response.
  factory OuraDailyReadinessResponse.fromJson(Map<String, dynamic> json) =>
      OuraDailyReadinessResponse(
        data: (json['data'] as List<dynamic>)
            .map(
              (e) => OuraDailyReadinessData.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
        nextToken: json['next_token'] as String?,
      );

  /// The list of daily readiness records.
  final List<OuraDailyReadinessData> data;

  /// Pagination cursor for the next page, if more data exists.
  final String? nextToken;
}

/// A single daily readiness record from the Oura API.
class OuraDailyReadinessData {
  /// Creates a daily readiness data record.
  const OuraDailyReadinessData({
    required this.id,
    required this.day,
    this.score,
    this.contributors,
    this.temperatureDeviation,
    this.temperatureTrendDeviation,
    this.timestamp,
  });

  /// Deserializes from the Oura API JSON response.
  factory OuraDailyReadinessData.fromJson(Map<String, dynamic> json) =>
      OuraDailyReadinessData(
        id: json['id'] as String,
        day: json['day'] as String,
        score: json['score'] as int?,
        contributors: (json['contributors'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
        temperatureDeviation:
            (json['temperature_deviation'] as num?)?.toDouble(),
        temperatureTrendDeviation:
            (json['temperature_trend_deviation'] as num?)?.toDouble(),
        timestamp: json['timestamp'] as String?,
      );

  /// Unique identifier for this record.
  final String id;

  /// The date in `YYYY-MM-DD` format.
  final String day;

  /// Overall readiness score (0-100).
  final int? score;

  /// Contributor scores keyed by category name.
  final Map<String, int>? contributors;

  /// Body temperature deviation from baseline in degrees Celsius.
  final double? temperatureDeviation;

  /// Body temperature trend deviation in degrees Celsius.
  final double? temperatureTrendDeviation;

  /// ISO 8601 timestamp of the record.
  final String? timestamp;
}
