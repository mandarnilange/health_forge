/// Response DTO for the Oura API v2 `/usercollection/heartrate` endpoint.
class OuraHeartRateResponse {
  /// Creates a response with the given [data] and optional [nextToken].
  const OuraHeartRateResponse({required this.data, this.nextToken});

  /// Deserializes from the Oura API JSON response.
  factory OuraHeartRateResponse.fromJson(Map<String, dynamic> json) =>
      OuraHeartRateResponse(
        data: (json['data'] as List<dynamic>)
            .map(
              (e) => OuraHeartRateData.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        nextToken: json['next_token'] as String?,
      );

  /// The list of heart rate samples.
  final List<OuraHeartRateData> data;

  /// Pagination cursor for the next page, if more data exists.
  final String? nextToken;
}

/// A single heart rate sample from the Oura API.
class OuraHeartRateData {
  /// Creates a heart rate data record.
  const OuraHeartRateData({
    required this.bpm,
    required this.source,
    required this.timestamp,
  });

  /// Deserializes from the Oura API JSON response.
  factory OuraHeartRateData.fromJson(Map<String, dynamic> json) =>
      OuraHeartRateData(
        bpm: json['bpm'] as int,
        source: json['source'] as String,
        timestamp: json['timestamp'] as String,
      );

  /// Heart rate in beats per minute.
  final int bpm;

  /// The measurement source (e.g. `awake`, `rest`, `sleep`).
  final String source;

  /// ISO 8601 timestamp of the measurement.
  final String timestamp;
}
