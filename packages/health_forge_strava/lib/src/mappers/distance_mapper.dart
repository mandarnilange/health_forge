import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

/// Maps Strava API activity data to [DistanceSample] records.
class DistanceMapper {
  const DistanceMapper._();

  /// Maps activities with distance data to [DistanceSample] records.
  static List<DistanceSample> map(StravaActivityListResponse response) {
    return response.activities
        .where((a) => a.distance != null)
        .map(_mapOne)
        .toList();
  }

  static DistanceSample _mapOne(StravaActivitySummary activity) {
    final startTime = DateTime.parse(activity.startDate);
    final endTime = startTime.add(Duration(seconds: activity.elapsedTime));

    return DistanceSample(
      id: IdGenerator.generate(),
      provider: DataProvider.strava,
      providerRecordType: 'activity',
      providerRecordId: activity.id.toString(),
      startTime: startTime,
      endTime: endTime,
      capturedAt: DateTime.now(),
      distanceMeters: activity.distance!,
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.strava',
      ),
    );
  }
}
