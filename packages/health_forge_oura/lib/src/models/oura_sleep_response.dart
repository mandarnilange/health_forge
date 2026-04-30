/// Response DTO for the Oura API v2 `/usercollection/sleep` endpoint.
class OuraSleepResponse {
  /// Creates a response with the given [data] and optional [nextToken].
  const OuraSleepResponse({required this.data, this.nextToken});

  /// Deserializes from the Oura API JSON response.
  factory OuraSleepResponse.fromJson(Map<String, dynamic> json) =>
      OuraSleepResponse(
        data: (json['data'] as List<dynamic>)
            .map(
              (e) => OuraSleepData.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        nextToken: json['next_token'] as String?,
      );

  /// The list of sleep period records.
  final List<OuraSleepData> data;

  /// Pagination cursor for the next page, if more data exists.
  final String? nextToken;
}

/// A single sleep period from the Oura API.
class OuraSleepData {
  /// Creates a sleep data record.
  const OuraSleepData({
    required this.id,
    required this.bedtimeStart,
    required this.bedtimeEnd,
    this.averageBreath,
    this.averageHeartRate,
    this.averageHrv,
    this.deepSleepDuration,
    this.efficiency,
    this.hr5Min,
    this.latency,
    this.lightSleepDuration,
    this.lowBatteryAlert,
    this.period,
    this.readinessScoreDelta,
    this.remSleepDuration,
    this.restlessPeriods,
    this.sleepPhase5Min,
    this.timeInBed,
    this.totalSleepDuration,
    this.type,
  });

  /// Deserializes from the Oura API JSON response.
  factory OuraSleepData.fromJson(Map<String, dynamic> json) => OuraSleepData(
        id: json['id'] as String,
        averageBreath: (json['average_breath'] as num?)?.toDouble(),
        averageHeartRate: (json['average_heart_rate'] as num?)?.toDouble(),
        averageHrv: json['average_hrv'] as int?,
        bedtimeStart: json['bedtime_start'] as String,
        bedtimeEnd: json['bedtime_end'] as String,
        deepSleepDuration: json['deep_sleep_duration'] as int?,
        efficiency: json['efficiency'] as int?,
        hr5Min: (json['hr_5_min'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        latency: json['latency'] as int?,
        lightSleepDuration: json['light_sleep_duration'] as int?,
        lowBatteryAlert: json['low_battery_alert'] as bool?,
        period: json['period'] as int?,
        readinessScoreDelta:
            (json['readiness_score_delta'] as num?)?.toDouble(),
        remSleepDuration: json['rem_sleep_duration'] as int?,
        restlessPeriods: json['restless_periods'] as int?,
        sleepPhase5Min: json['sleep_phase_5_min'] as String?,
        timeInBed: json['time_in_bed'] as int?,
        totalSleepDuration: json['total_sleep_duration'] as int?,
        type: json['type'] as String?,
      );

  /// Unique identifier for this sleep period.
  final String id;

  /// Average breathing rate in breaths per minute.
  final double? averageBreath;

  /// Average heart rate in BPM during sleep.
  final double? averageHeartRate;

  /// Average heart rate variability (SDNN) in milliseconds.
  final int? averageHrv;

  /// ISO 8601 timestamp when the user went to bed.
  final String bedtimeStart;

  /// ISO 8601 timestamp when the user got out of bed.
  final String bedtimeEnd;

  /// Deep sleep duration in seconds.
  final int? deepSleepDuration;

  /// Sleep efficiency percentage (0-100).
  final int? efficiency;

  /// Heart rate samples at 5-minute intervals.
  final List<int>? hr5Min;

  /// Sleep onset latency in seconds.
  final int? latency;

  /// Light sleep duration in seconds.
  final int? lightSleepDuration;

  /// Whether a low battery alert occurred during sleep.
  final bool? lowBatteryAlert;

  /// Sleep period index (0 = primary, 1+ = naps).
  final int? period;

  /// Change in readiness score attributed to this sleep.
  final double? readinessScoreDelta;

  /// REM sleep duration in seconds.
  final int? remSleepDuration;

  /// Number of restless periods during sleep.
  final int? restlessPeriods;

  /// Hypnogram encoded as a digit string (5-min intervals).
  final String? sleepPhase5Min;

  /// Total time in bed in seconds.
  final int? timeInBed;

  /// Total sleep duration in seconds.
  final int? totalSleepDuration;

  /// Sleep period type (e.g. `long_sleep`, `rest`).
  final String? type;
}
