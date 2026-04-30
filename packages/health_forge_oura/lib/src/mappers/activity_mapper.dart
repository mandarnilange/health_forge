import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/models/oura_daily_activity_response.dart';

/// Maps Oura API daily activity data to [StepCount] and [CaloriesBurned].
class ActivityMapper {
  const ActivityMapper._();

  static const _provenance = Provenance(
    dataOrigin: DataOrigin.mapped,
    sourceApp: 'com.ouraring.oura',
  );

  /// Converts daily activity data to [StepCount] records.
  static List<StepCount> mapSteps(OuraDailyActivityResponse response) {
    return response.data
        .where((d) => d.steps != null)
        .map(_mapStepCount)
        .toList();
  }

  /// Converts daily activity data to [CaloriesBurned] records.
  static List<CaloriesBurned> mapCalories(
    OuraDailyActivityResponse response,
  ) {
    return response.data
        .where((d) => d.totalCalories != null)
        .map(_mapCalories)
        .toList();
  }

  static StepCount _mapStepCount(OuraDailyActivityData data) {
    final day = DateTime.parse('${data.day}T00:00:00Z');

    return StepCount(
      id: IdGenerator.generate(),
      provider: DataProvider.oura,
      providerRecordType: 'daily_activity',
      providerRecordId: data.id,
      startTime: day,
      endTime: day.add(const Duration(days: 1)),
      capturedAt: DateTime.now(),
      count: data.steps!,
      provenance: _provenance,
    );
  }

  static CaloriesBurned _mapCalories(OuraDailyActivityData data) {
    final day = DateTime.parse('${data.day}T00:00:00Z');

    return CaloriesBurned(
      id: IdGenerator.generate(),
      provider: DataProvider.oura,
      providerRecordType: 'daily_activity',
      providerRecordId: data.id,
      startTime: day,
      endTime: day.add(const Duration(days: 1)),
      capturedAt: DateTime.now(),
      totalCalories: data.totalCalories!.toDouble(),
      activeCalories: data.activeCalories?.toDouble(),
      provenance: _provenance,
    );
  }
}
