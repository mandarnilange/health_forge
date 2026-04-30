import 'package:json_annotation/json_annotation.dart';

/// Converts [DateTime] to/from ISO 8601 strings for JSON serialization.
class DateTimeConverter implements JsonConverter<DateTime, String> {
  /// Creates a [DateTimeConverter].
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

/// Converts [Duration] to/from microsecond integers for JSON serialization.
class DurationConverter implements JsonConverter<Duration, int> {
  /// Creates a [DurationConverter].
  const DurationConverter();

  @override
  Duration fromJson(int json) => Duration(microseconds: json);

  @override
  int toJson(Duration object) => object.inMicroseconds;
}
