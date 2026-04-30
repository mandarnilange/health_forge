/// A platform-agnostic data transfer object that decouples mapper logic
/// from the `health` package's `HealthDataPoint`.
///
/// This allows mappers to be tested without platform dependencies.
class HealthDataRecord {
  /// Creates a health data record from raw HealthKit values.
  const HealthDataRecord({
    required this.type,
    required this.value,
    required this.dateFrom,
    required this.dateTo,
    required this.sourceName,
    required this.sourceId,
    this.uuid = '',
    this.secondaryValue,
    this.workoutActivityType,
    this.sourceDeviceId = '',
    this.deviceModel,
    this.recordingMethod = 'unknown',
    this.metadata,
  });

  /// The HealthKit data type name (e.g. `HEART_RATE`, `STEPS`).
  final String type;

  /// The primary numeric value of the data point.
  final double value;

  /// The start timestamp of the measurement.
  final DateTime dateFrom;

  /// The end timestamp of the measurement.
  final DateTime dateTo;

  /// The display name of the data source (e.g. "Apple Watch").
  final String sourceName;

  /// The bundle identifier of the data source.
  final String sourceId;

  /// The HealthKit UUID for this data point.
  final String uuid;

  /// An optional secondary value (e.g. diastolic blood pressure).
  final double? secondaryValue;

  /// The workout activity type name, if this is a workout record.
  final String? workoutActivityType;

  /// The hardware device identifier.
  final String sourceDeviceId;

  /// The device model string from HealthKit, if available.
  final String? deviceModel;

  /// How the data was recorded (automatic, manual, active, unknown).
  final String recordingMethod;

  /// Provider-specific key-value metadata pairs.
  final Map<String, dynamic>? metadata;
}
