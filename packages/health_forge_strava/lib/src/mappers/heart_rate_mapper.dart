import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/models/strava_streams_response.dart';

/// Maps Strava API heart rate stream data to [HeartRateSample] records.
class HeartRateMapper {
  const HeartRateMapper._();

  /// Maps heart rate streams for an activity to [HeartRateSample] records.
  ///
  /// [activityStartTime] is the UTC start time of the activity.
  /// [streams] contains the heart rate and time stream data.
  static List<HeartRateSample> map({
    required DateTime activityStartTime,
    required StravaStreamsResponse streams,
    int? activityId,
  }) {
    final hrData = streams.dataForType('heartrate');
    final timeData = streams.dataForType('time');

    if (hrData == null || timeData == null) return const [];
    if (hrData.length != timeData.length) return const [];

    final samples = <HeartRateSample>[];
    for (var i = 0; i < hrData.length; i++) {
      final timestamp = activityStartTime.add(Duration(seconds: timeData[i]));
      samples.add(
        HeartRateSample(
          id: IdGenerator.generate(),
          provider: DataProvider.strava,
          providerRecordType: 'heartrate_stream',
          providerRecordId:
              '${activityId ?? activityStartTime.millisecondsSinceEpoch}_hr_$i',
          startTime: timestamp,
          endTime: timestamp,
          capturedAt: DateTime.now(),
          beatsPerMinute: hrData[i],
          context: 'workout',
          provenance: const Provenance(
            dataOrigin: DataOrigin.mapped,
            sourceApp: 'com.strava',
          ),
        ),
      );
    }
    return samples;
  }
}
