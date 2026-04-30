import 'package:flutter/material.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:intl/intl.dart';

class RecordListItem extends StatelessWidget {
  const RecordListItem({
    required this.record,
    this.onTap,
    super.key,
  });

  final HealthRecordMixin record;
  final VoidCallback? onTap;

  String _extractValue() {
    return switch (record) {
      final HeartRateSample r => '${r.beatsPerMinute} bpm',
      final StepCount r => '${r.count} steps',
      final SleepSession r => '${r.totalSleepMinutes ?? 0} min',
      final ReadinessScore r => 'Score: ${r.score}',
      final CaloriesBurned r => '${r.totalCalories.toStringAsFixed(0)} kcal',
      final BloodOxygenSample r => '${r.percentage.toStringAsFixed(1)}%',
      final StressScore r => 'Score: ${r.score}',
      final SleepScore r => 'Score: ${r.score}',
      final HeartRateVariability r =>
        '${r.sdnnMilliseconds.toStringAsFixed(1)} ms',
      final RestingHeartRate r => '${r.beatsPerMinute} bpm',
      final RespiratoryRate r =>
        '${r.breathsPerMinute.toStringAsFixed(1)} br/min',
      final Weight r => '${r.kilograms.toStringAsFixed(1)} kg',
      final DistanceSample r =>
        '${(r.distanceMeters / 1000).toStringAsFixed(2)} km',
      final ElevationGain r => '${r.elevationMeters.toStringAsFixed(0)} m',
      final ActivitySession r => '${r.activityName ?? "Workout"} - '
          '${r.totalCalories?.toStringAsFixed(0) ?? "?"} kcal',
      _ => record.providerRecordType,
    };
  }

  String _recordTypeName() {
    return switch (record) {
      HeartRateSample() => 'Heart Rate',
      StepCount() => 'Steps',
      SleepSession() => 'Sleep',
      ReadinessScore() => 'Readiness',
      CaloriesBurned() => 'Calories',
      BloodOxygenSample() => 'Blood Oxygen',
      StressScore() => 'Stress',
      SleepScore() => 'Sleep Score',
      HeartRateVariability() => 'HRV',
      RestingHeartRate() => 'Resting HR',
      RespiratoryRate() => 'Respiratory Rate',
      Weight() => 'Weight',
      DistanceSample() => 'Distance',
      ElevationGain() => 'Elevation',
      ActivitySession() => 'Workout',
      _ => record.providerRecordType,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Text(_recordTypeName()),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              record.provider.name,
              style: theme.textTheme.labelSmall,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      subtitle: Text(
        '${dateFormat.format(record.startTime)}'
        ' - ${dateFormat.format(record.endTime)}',
      ),
      trailing: Text(
        _extractValue(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
