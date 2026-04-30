/// A platform-agnostic data transfer object that decouples mapper logic
/// from the `health` package's `HealthDataPoint`.
///
/// This allows mappers to be tested without platform dependencies.
class HealthDataRecord {
  /// Creates a health data record from raw Health Connect values.
  const HealthDataRecord({
    required this.type,
    required this.value,
    required this.dateFrom,
    required this.dateTo,
    required this.sourceName,
    required this.sourceId,
    this.uuid = '',
    this.sourceDeviceId = '',
    this.deviceModel,
    this.recordingMethod = 'unknown',
    this.metadata,
  });

  /// The Health Connect data type name (e.g. `HEART_RATE`, `STEPS`).
  final String type;

  /// The primary numeric value of the data point.
  final double value;

  /// The start timestamp of the measurement.
  final DateTime dateFrom;

  /// The end timestamp of the measurement.
  final DateTime dateTo;

  /// The display name of the data source.
  final String sourceName;

  /// The package name of the data source.
  final String sourceId;

  /// The Health Connect UUID for this data point.
  final String uuid;

  /// The hardware device identifier.
  final String sourceDeviceId;

  /// The device model string.
  final String? deviceModel;

  /// How the data was recorded.
  ///
  /// Known values from the `health` plugin: `automatic`, `manual`,
  /// `active`, `unknown`.
  final String recordingMethod;

  /// Provider-specific key-value metadata pairs.
  final Map<String, dynamic>? metadata;
}
