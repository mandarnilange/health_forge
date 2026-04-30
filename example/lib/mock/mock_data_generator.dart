import 'dart:math';

import 'package:health_forge_core/health_forge_core.dart';

/// Generates realistic fake health records for demonstration purposes.
class MockDataGenerator {
  MockDataGenerator(this.provider) : _random = Random(provider.index);

  final DataProvider provider;
  final Random _random;

  /// Generates records for the given [metricType] within [timeRange].
  List<HealthRecordMixin> generate({
    required MetricType metricType,
    required TimeRange timeRange,
  }) {
    return switch (metricType) {
      MetricType.heartRate => _generateHeartRate(timeRange),
      MetricType.steps => _generateSteps(timeRange),
      MetricType.sleepSession => _generateSleep(timeRange),
      MetricType.readiness => _generateReadiness(timeRange),
      MetricType.calories => _generateCalories(timeRange),
      MetricType.bloodOxygen => _generateBloodOxygen(timeRange),
      MetricType.stress => _generateStress(timeRange),
      MetricType.sleepScore => _generateSleepScore(timeRange),
      MetricType.hrv => _generateHrv(timeRange),
      MetricType.restingHeartRate => _generateRestingHeartRate(timeRange),
      MetricType.respiratoryRate => _generateRespiratoryRate(timeRange),
      MetricType.weight => _generateWeight(timeRange),
      MetricType.distance => _generateDistance(timeRange),
      MetricType.elevation => _generateElevation(timeRange),
      MetricType.workout => _generateWorkout(timeRange),
      _ => [],
    };
  }

  int _intInRange(int min, int max) => min + _random.nextInt(max - min + 1);

  double _doubleInRange(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  List<DateTime> _daysIn(TimeRange range) {
    final days = <DateTime>[];
    var current = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  List<HealthRecordMixin> _generateHeartRate(TimeRange range) {
    final records = <HealthRecordMixin>[];
    for (final day in _daysIn(range)) {
      // Generate a sample every 5 minutes for 8 hours (waking hours)
      for (var hour = 8; hour < 16; hour++) {
        for (var minute = 0; minute < 60; minute += 5) {
          final time = day.add(Duration(hours: hour, minutes: minute));
          if (time.isBefore(range.start) || time.isAfter(range.end)) continue;
          records.add(
            HeartRateSample(
              id: IdGenerator.generate(),
              provider: provider,
              providerRecordType: 'heart_rate',
              startTime: time,
              endTime: time.add(const Duration(seconds: 30)),
              capturedAt: time,
              beatsPerMinute: _intInRange(60, 100),
            ),
          );
        }
      }
    }
    return records;
  }

  List<HealthRecordMixin> _generateSteps(TimeRange range) {
    return _daysIn(range).map((day) {
      final start = day.add(const Duration(hours: 6));
      final end = day.add(const Duration(hours: 22));
      return StepCount(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'steps',
        startTime: start,
        endTime: end,
        capturedAt: end,
        count: _intInRange(3000, 12000),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateSleep(TimeRange range) {
    return _daysIn(range).map((day) {
      final totalMinutes = _intInRange(420, 540); // 7-9 hours
      final bedtime = day.subtract(Duration(hours: _intInRange(0, 1)));
      final wakeTime = bedtime.add(Duration(minutes: totalMinutes));

      final deepMin = _intInRange(60, 120);
      final remMin = _intInRange(60, 120);
      final lightMin = totalMinutes - deepMin - remMin - _intInRange(10, 30);
      final awakeMin = totalMinutes - deepMin - remMin - lightMin;

      var stageStart = bedtime;
      final stages = <SleepStageSegment>[];
      for (final entry in [
        (SleepStage.light, lightMin ~/ 2),
        (SleepStage.deep, deepMin),
        (SleepStage.rem, remMin),
        (SleepStage.light, lightMin - lightMin ~/ 2),
        (SleepStage.awake, awakeMin),
      ]) {
        final stageEnd = stageStart.add(Duration(minutes: entry.$2));
        stages.add(
          SleepStageSegment(
            stage: entry.$1,
            startTime: stageStart,
            endTime: stageEnd,
          ),
        );
        stageStart = stageEnd;
      }

      return SleepSession(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'sleep_session',
        startTime: bedtime,
        endTime: wakeTime,
        capturedAt: wakeTime,
        totalSleepMinutes: totalMinutes,
        deepMinutes: deepMin,
        remMinutes: remMin,
        lightMinutes: lightMin,
        awakeMinutes: awakeMin,
        efficiency: _intInRange(75, 98),
        stages: stages,
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateReadiness(TimeRange range) {
    return _daysIn(range).map((day) {
      final time = day.add(const Duration(hours: 7));
      return ReadinessScore(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'readiness_score',
        startTime: time,
        endTime: time.add(const Duration(hours: 1)),
        capturedAt: time,
        score: _intInRange(50, 95),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateCalories(TimeRange range) {
    return _daysIn(range).map((day) {
      final start = day.add(const Duration(hours: 6));
      final end = day.add(const Duration(hours: 22));
      final total = _doubleInRange(1500, 2500);
      return CaloriesBurned(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'calories_burned',
        startTime: start,
        endTime: end,
        capturedAt: end,
        totalCalories: total,
        activeCalories: total * _doubleInRange(0.3, 0.5),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateBloodOxygen(TimeRange range) {
    final records = <HealthRecordMixin>[];
    for (final day in _daysIn(range)) {
      // A few samples per day
      for (var i = 0; i < 4; i++) {
        final time = day.add(Duration(hours: 6 + i * 4));
        if (time.isBefore(range.start) || time.isAfter(range.end)) continue;
        records.add(
          BloodOxygenSample(
            id: IdGenerator.generate(),
            provider: provider,
            providerRecordType: 'blood_oxygen',
            startTime: time,
            endTime: time.add(const Duration(minutes: 1)),
            capturedAt: time,
            percentage: _doubleInRange(94, 99),
          ),
        );
      }
    }
    return records;
  }

  List<HealthRecordMixin> _generateStress(TimeRange range) {
    return _daysIn(range).map((day) {
      final time = day.add(const Duration(hours: 12));
      return StressScore(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'stress_score',
        startTime: time,
        endTime: time.add(const Duration(hours: 1)),
        capturedAt: time,
        score: _intInRange(10, 80),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateSleepScore(TimeRange range) {
    return _daysIn(range).map((day) {
      final time = day.add(const Duration(hours: 7));
      return SleepScore(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'sleep_score',
        startTime: time,
        endTime: time.add(const Duration(hours: 1)),
        capturedAt: time,
        score: _intInRange(60, 95),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateHrv(TimeRange range) {
    return _daysIn(range).map((day) {
      final time = day.add(const Duration(hours: 7));
      return HeartRateVariability(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'heart_rate_variability',
        startTime: time,
        endTime: time.add(const Duration(minutes: 5)),
        capturedAt: time,
        sdnnMilliseconds: _doubleInRange(20, 80),
        rmssdMilliseconds: _doubleInRange(15, 70),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateRestingHeartRate(TimeRange range) {
    return _daysIn(range).map((day) {
      final time = day.add(const Duration(hours: 7));
      return RestingHeartRate(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'resting_heart_rate',
        startTime: time,
        endTime: time.add(const Duration(minutes: 5)),
        capturedAt: time,
        beatsPerMinute: _intInRange(50, 70),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateRespiratoryRate(TimeRange range) {
    return _daysIn(range).map((day) {
      final time = day.add(const Duration(hours: 3));
      return RespiratoryRate(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'respiratory_rate',
        startTime: time,
        endTime: time.add(const Duration(minutes: 10)),
        capturedAt: time,
        breathsPerMinute: _doubleInRange(12, 20),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateWeight(TimeRange range) {
    return _daysIn(range).map((day) {
      final time = day.add(const Duration(hours: 8));
      return Weight(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'weight',
        startTime: time,
        endTime: time,
        capturedAt: time,
        kilograms: _doubleInRange(65, 85),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateDistance(TimeRange range) {
    return _daysIn(range).map((day) {
      final start = day.add(const Duration(hours: 6));
      final end = day.add(const Duration(hours: 22));
      return DistanceSample(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'distance_sample',
        startTime: start,
        endTime: end,
        capturedAt: end,
        distanceMeters: _doubleInRange(2000, 10000),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateElevation(TimeRange range) {
    return _daysIn(range).map((day) {
      final start = day.add(const Duration(hours: 6));
      final end = day.add(const Duration(hours: 22));
      return ElevationGain(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'elevation_gain',
        startTime: start,
        endTime: end,
        capturedAt: end,
        elevationMeters: _doubleInRange(10, 200),
      );
    }).toList();
  }

  List<HealthRecordMixin> _generateWorkout(TimeRange range) {
    final activities = [
      'Running',
      'Cycling',
      'Swimming',
      'Walking',
      'Yoga',
    ];
    return _daysIn(range).map((day) {
      final hour = _intInRange(6, 18);
      final durationMin = _intInRange(20, 90);
      final start = day.add(Duration(hours: hour));
      final end = start.add(Duration(minutes: durationMin));
      return ActivitySession(
        id: IdGenerator.generate(),
        provider: provider,
        providerRecordType: 'workout',
        startTime: start,
        endTime: end,
        capturedAt: end,
        activityType: MetricType.workout,
        activityName: activities[_random.nextInt(activities.length)],
        totalCalories: _doubleInRange(100, 600),
        activeCalories: _doubleInRange(80, 500),
        distanceMeters: _doubleInRange(1000, 15000),
        averageHeartRate: _intInRange(100, 160),
        maxHeartRate: _intInRange(150, 190),
      );
    }).toList();
  }
}
