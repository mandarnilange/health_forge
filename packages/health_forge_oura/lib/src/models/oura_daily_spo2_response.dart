/// Response DTO for the Oura API v2 `/usercollection/daily_spo2` endpoint.
class OuraDailySpo2Response {
  /// Creates a response with the given [data] and optional [nextToken].
  const OuraDailySpo2Response({required this.data, this.nextToken});

  /// Deserializes from the Oura API JSON response.
  factory OuraDailySpo2Response.fromJson(Map<String, dynamic> json) =>
      OuraDailySpo2Response(
        data: (json['data'] as List<dynamic>)
            .map(
              (e) => OuraDailySpo2Data.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        nextToken: json['next_token'] as String?,
      );

  /// The list of daily SpO2 records.
  final List<OuraDailySpo2Data> data;

  /// Pagination cursor for the next page, if more data exists.
  final String? nextToken;
}

/// A single daily SpO2 record from the Oura API.
class OuraDailySpo2Data {
  /// Creates a daily SpO2 data record.
  const OuraDailySpo2Data({
    required this.id,
    required this.day,
    this.spo2Percentage,
    this.breathingDisturbanceIndex,
    this.timestamp,
  });

  /// Deserializes from the Oura API JSON response.
  factory OuraDailySpo2Data.fromJson(Map<String, dynamic> json) =>
      OuraDailySpo2Data(
        id: json['id'] as String,
        day: json['day'] as String,
        spo2Percentage: json['spo2_percentage'] != null
            ? OuraSpo2Percentage.fromJson(
                json['spo2_percentage'] as Map<String, dynamic>,
              )
            : null,
        breathingDisturbanceIndex:
            (json['breathing_disturbance_index'] as num?)?.toDouble(),
        timestamp: json['timestamp'] as String?,
      );

  /// Unique identifier for this record.
  final String id;

  /// The date in `YYYY-MM-DD` format.
  final String day;

  /// The SpO2 percentage data.
  final OuraSpo2Percentage? spo2Percentage;

  /// Breathing disturbance index value.
  final double? breathingDisturbanceIndex;

  /// ISO 8601 timestamp of the record.
  final String? timestamp;
}

/// SpO2 percentage data from the Oura API.
class OuraSpo2Percentage {
  /// Creates an SpO2 percentage record.
  const OuraSpo2Percentage({this.average});

  /// Deserializes from the Oura API JSON response.
  factory OuraSpo2Percentage.fromJson(Map<String, dynamic> json) =>
      OuraSpo2Percentage(
        average: (json['average'] as num?)?.toDouble(),
      );

  /// The average SpO2 percentage for the day.
  final double? average;
}
