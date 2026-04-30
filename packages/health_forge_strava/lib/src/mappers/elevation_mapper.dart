import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

/// Maps Strava API activity data to [ElevationGain] records.
class ElevationMapper {
  const ElevationMapper._();

  /// Maps activities with elevation data to [ElevationGain] records.
  static List<ElevationGain> map(StravaActivityListResponse response) {
    return response.activities
        .where((a) => a.totalElevationGain != null)
        .map(_mapOne)
        .toList();
  }

  static ElevationGain _mapOne(StravaActivitySummary activity) {
    final startTime = DateTime.parse(activity.startDate);
    final endTime = startTime.add(Duration(seconds: activity.elapsedTime));

    return ElevationGain(
      id: IdGenerator.generate(),
      provider: DataProvider.strava,
      providerRecordType: 'activity',
      providerRecordId: activity.id.toString(),
      startTime: startTime,
      endTime: endTime,
      capturedAt: DateTime.now(),
      elevationMeters: activity.totalElevationGain!,
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.strava',
      ),
    );
  }
}
