/// Response DTO for the Strava API `/activities/{id}/streams` endpoint.
///
/// Strava returns an array of stream objects, each containing typed
/// data arrays.
class StravaStreamsResponse {
  /// Creates a streams response with the given [streams].
  const StravaStreamsResponse({required this.streams});

  /// Deserializes from the Strava API JSON array response.
  factory StravaStreamsResponse.fromJson(List<dynamic> json) =>
      StravaStreamsResponse(
        streams: json
            .map((e) => StravaStream.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// The list of typed data streams.
  final List<StravaStream> streams;

  /// Returns the data array for a given stream type, or null if not present.
  List<int>? dataForType(String type) {
    final stream = streams.where((s) => s.type == type).firstOrNull;
    return stream?.data;
  }
}

/// A single stream from the Strava streams API.
class StravaStream {
  /// Creates a stream record.
  const StravaStream({
    required this.type,
    required this.data,
    this.seriesType,
    this.originalSize,
    this.resolution,
  });

  /// Deserializes from the Strava API JSON response.
  factory StravaStream.fromJson(Map<String, dynamic> json) => StravaStream(
        type: json['type'] as String,
        data: (json['data'] as List<dynamic>).cast<int>(),
        seriesType: json['series_type'] as String?,
        originalSize: json['original_size'] as int?,
        resolution: json['resolution'] as String?,
      );

  /// The stream type key (e.g. `heartrate`, `time`).
  final String type;

  /// The array of integer data values.
  final List<int> data;

  /// The series type (e.g. `distance`, `time`).
  final String? seriesType;

  /// The original number of data points before downsampling.
  final int? originalSize;

  /// The resolution of the stream (e.g. `low`, `medium`, `high`).
  final String? resolution;
}
