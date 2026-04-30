/// Response DTO for the Oura API v2 `/usercollection/daily_sleep` endpoint.
class OuraDailySleepResponse {
  /// Creates a response with the given [data] and optional [nextToken].
  const OuraDailySleepResponse({required this.data, this.nextToken});

  /// Deserializes from the Oura API JSON response.
  factory OuraDailySleepResponse.fromJson(Map<String, dynamic> json) =>
      OuraDailySleepResponse(
        data: (json['data'] as List<dynamic>)
            .map(
              (e) => OuraDailySleepData.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        nextToken: json['next_token'] as String?,
      );

  /// The list of daily sleep records.
  final List<OuraDailySleepData> data;

  /// Pagination cursor for the next page, if more data exists.
  final String? nextToken;
}

/// A single daily sleep summary from the Oura API.
class OuraDailySleepData {
  /// Creates a daily sleep data record.
  const OuraDailySleepData({
    required this.id,
    required this.day,
    this.score,
    this.contributors,
    this.timestamp,
  });

  /// Deserializes from the Oura API JSON response.
  factory OuraDailySleepData.fromJson(Map<String, dynamic> json) =>
      OuraDailySleepData(
        id: json['id'] as String,
        day: json['day'] as String,
        score: json['score'] as int?,
        contributors: (json['contributors'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
        timestamp: json['timestamp'] as String?,
      );

  /// Unique identifier for this record.
  final String id;

  /// The date in `YYYY-MM-DD` format.
  final String day;

  /// Overall sleep score (0-100).
  final int? score;

  /// Contributor scores keyed by category name.
  final Map<String, int>? contributors;

  /// ISO 8601 timestamp of the record.
  final String? timestamp;
}
