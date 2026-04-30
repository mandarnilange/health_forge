import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/models/strava_activity_detail_response.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

/// Maps Strava API activity data to [ActivitySession] records.
class ActivitySessionMapper {
  const ActivitySessionMapper._();

  /// Maps a list of activity summaries to [ActivitySession] records.
  static List<ActivitySession> mapFromList(
    StravaActivityListResponse response,
  ) {
    return response.activities.map(_mapFromSummary).toList();
  }

  /// Maps a detailed activity response to a single [ActivitySession].
  static ActivitySession mapFromDetail(
    StravaActivityDetailResponse detail,
  ) {
    final startTime = DateTime.parse(detail.startDate);
    final endTime = startTime.add(Duration(seconds: detail.elapsedTime));

    final extension = StravaWorkoutExtension(
      sufferScore: detail.sufferScore,
      segmentEfforts: detail.segmentEfforts,
      routePolyline: detail.mapPolyline,
    );

    return ActivitySession(
      id: IdGenerator.generate(),
      provider: DataProvider.strava,
      providerRecordType: 'activity',
      providerRecordId: detail.id.toString(),
      startTime: startTime,
      endTime: endTime,
      capturedAt: DateTime.now(),
      activityType: MetricType.workout,
      activityName: detail.name,
      totalCalories: detail.calories ??
          (detail.kilojoules != null ? detail.kilojoules! / 4.184 : null),
      distanceMeters: detail.distance,
      averageHeartRate: detail.averageHeartrate?.round(),
      maxHeartRate: detail.maxHeartrate,
      extensions: extension.toJson(),
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.strava',
      ),
    );
  }

  static ActivitySession _mapFromSummary(StravaActivitySummary activity) {
    final startTime = DateTime.parse(activity.startDate);
    final endTime = startTime.add(Duration(seconds: activity.elapsedTime));

    final extension = StravaWorkoutExtension(
      sufferScore: activity.sufferScore,
      routePolyline: activity.mapSummaryPolyline,
    );

    return ActivitySession(
      id: IdGenerator.generate(),
      provider: DataProvider.strava,
      providerRecordType: 'activity',
      providerRecordId: activity.id.toString(),
      startTime: startTime,
      endTime: endTime,
      capturedAt: DateTime.now(),
      activityType: MetricType.workout,
      activityName: activity.name,
      totalCalories:
          activity.kilojoules != null ? activity.kilojoules! / 4.184 : null,
      distanceMeters: activity.distance,
      averageHeartRate: activity.averageHeartrate?.round(),
      maxHeartRate: activity.maxHeartrate,
      extensions: extension.toJson(),
      provenance: const Provenance(
        dataOrigin: DataOrigin.mapped,
        sourceApp: 'com.strava',
      ),
    );
  }
}
