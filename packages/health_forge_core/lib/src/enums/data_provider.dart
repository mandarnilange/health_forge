import 'package:json_annotation/json_annotation.dart';

/// Supported health data providers.
@JsonEnum()
enum DataProvider {
  /// Apple HealthKit.
  apple,

  /// Google Health Connect (Android).
  googleHealthConnect,

  /// Strava fitness platform.
  strava,

  /// Oura Ring.
  oura,

  /// Garmin Connect.
  garmin,
}
