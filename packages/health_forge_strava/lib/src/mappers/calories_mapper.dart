import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

/// Maps Strava API activity data to [CaloriesBurned] records.
class CaloriesMapper {
  const CaloriesMapper._();

  /// Maps activities with kilojoule data to [CaloriesBurned] records.
  ///
  /// Converts Strava kilojoules to kilocalories (kJ / 4.184 = kcal).
  static List<CaloriesBurned> map(StravaActivityListResponse response) {
    return response.activities
        .where((a) => a.kilojoules != null)
        .map(_mapOne)
        .toList();
  }

  static CaloriesBurned _mapOne(StravaActivitySummary activity) {
    final startTime = DateTime.parse(activity.startDate);
    final endTime = startTime.add(Duration(seconds: activity.elapsedTime));

    return CaloriesBurned(
      id: IdGenerator.generate(),
      provider: DataProvider.strava,
      providerRecordType: 'activity',
      providerRecordId: activity.id.toString(),
      startTime: startTime,
      endTime: endTime,
      capturedAt: DateTime.now(),
      totalCalories: activity.kilojoules! / 4.184,
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.strava',
      ),
    );
  }
}
