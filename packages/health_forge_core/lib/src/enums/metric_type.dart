import 'package:json_annotation/json_annotation.dart';

/// The type of health metric a record represents.
@JsonEnum()
enum MetricType {
  /// Instantaneous heart rate in beats per minute.
  heartRate,

  /// Step count over a time interval.
  steps,

  /// A sleep session with optional stage breakdowns.
  sleepSession,

  /// Heart rate variability (SDNN / RMSSD).
  hrv,

  /// Resting heart rate measurement.
  restingHeartRate,

  /// Blood oxygen saturation (SpO2) percentage.
  bloodOxygen,

  /// Respiratory rate in breaths per minute.
  respiratoryRate,

  /// Body weight measurement.
  weight,

  /// Body fat percentage measurement.
  bodyFat,

  /// Blood pressure reading (systolic / diastolic).
  bloodPressure,

  /// Blood glucose concentration.
  bloodGlucose,

  /// Calories burned over a time interval.
  calories,

  /// Distance traveled in meters.
  distance,

  /// Elevation gain in meters.
  elevation,

  /// An activity or workout session.
  workout,

  /// Readiness or recovery-readiness score.
  readiness,

  /// Stress level score.
  stress,

  /// Recovery metric score.
  recovery,

  /// Overall sleep quality score.
  sleepScore,
}
