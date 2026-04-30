/// Response DTO for the Oura API v2 `/usercollection/daily_stress` endpoint.
class OuraDailyStressResponse {
  /// Creates a response with the given [data] and optional [nextToken].
  const OuraDailyStressResponse({required this.data, this.nextToken});

  /// Deserializes from the Oura API JSON response.
  factory OuraDailyStressResponse.fromJson(Map<String, dynamic> json) =>
      OuraDailyStressResponse(
        data: (json['data'] as List<dynamic>)
            .map(
              (e) => OuraDailyStressData.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        nextToken: json['next_token'] as String?,
      );

  /// The list of daily stress records.
  final List<OuraDailyStressData> data;

  /// Pagination cursor for the next page, if more data exists.
  final String? nextToken;
}

/// A single daily stress record from the Oura API.
class OuraDailyStressData {
  /// Creates a daily stress data record.
  const OuraDailyStressData({
    required this.id,
    required this.day,
    this.stressHigh,
    this.recoveryHigh,
    this.daySummary,
    this.timestamp,
  });

  /// Deserializes from the Oura API JSON response.
  factory OuraDailyStressData.fromJson(Map<String, dynamic> json) =>
      OuraDailyStressData(
        id: json['id'] as String,
        day: json['day'] as String,
        stressHigh: json['stress_high'] as int?,
        recoveryHigh: json['recovery_high'] as int?,
        daySummary: json['day_summary'] as String?,
        timestamp: json['timestamp'] as String?,
      );

  /// Unique identifier for this record.
  final String id;

  /// The date in `YYYY-MM-DD` format.
  final String day;

  /// Peak stress level for the day in seconds.
  final int? stressHigh;

  /// Peak recovery level for the day in seconds.
  final int? recoveryHigh;

  /// Textual summary of the day's stress level.
  final String? daySummary;

  /// ISO 8601 timestamp of the record.
  final String? timestamp;
}
