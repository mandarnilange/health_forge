import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_strava/src/mappers/heart_rate_mapper.dart';
import 'package:health_forge_strava/src/models/strava_streams_response.dart';

void main() {
  group('HeartRateMapper', () {
    test('maps streams to HeartRateSample list', () {
      const streams = StravaStreamsResponse(
        streams: [
          StravaStream(type: 'time', data: [0, 5, 10]),
          StravaStream(type: 'heartrate', data: [120, 130, 140]),
        ],
      );

      final samples = HeartRateMapper.map(
        activityStartTime: DateTime.utc(2024, 1, 15, 7),
        streams: streams,
      );

      expect(samples, hasLength(3));
      expect(samples[0].beatsPerMinute, 120);
      expect(samples[1].beatsPerMinute, 130);
      expect(samples[2].beatsPerMinute, 140);
    });

    test('calculates absolute timestamps from offsets', () {
      const streams = StravaStreamsResponse(
        streams: [
          StravaStream(type: 'time', data: [0, 60, 120]),
          StravaStream(type: 'heartrate', data: [120, 130, 140]),
        ],
      );

      final start = DateTime.utc(2024, 1, 15, 7);
      final samples = HeartRateMapper.map(
        activityStartTime: start,
        streams: streams,
      );

      expect(samples[0].startTime, start);
      expect(samples[1].startTime, start.add(const Duration(seconds: 60)));
      expect(
        samples[2].startTime,
        start.add(const Duration(seconds: 120)),
      );
    });

    test('sets provider to strava', () {
      const streams = StravaStreamsResponse(
        streams: [
          StravaStream(type: 'time', data: [0]),
          StravaStream(type: 'heartrate', data: [120]),
        ],
      );

      final samples = HeartRateMapper.map(
        activityStartTime: DateTime.utc(2024, 1, 15, 7),
        streams: streams,
      );

      expect(samples.first.provider, DataProvider.strava);
    });

    test('sets context to workout', () {
      const streams = StravaStreamsResponse(
        streams: [
          StravaStream(type: 'time', data: [0]),
          StravaStream(type: 'heartrate', data: [120]),
        ],
      );

      final samples = HeartRateMapper.map(
        activityStartTime: DateTime.utc(2024, 1, 15, 7),
        streams: streams,
      );

      expect(samples.first.context, 'workout');
    });

    test('returns empty list when heartrate stream is missing', () {
      const streams = StravaStreamsResponse(
        streams: [
          StravaStream(type: 'time', data: [0, 5, 10]),
        ],
      );

      final samples = HeartRateMapper.map(
        activityStartTime: DateTime.utc(2024, 1, 15, 7),
        streams: streams,
      );

      expect(samples, isEmpty);
    });

    test('returns empty list when time stream is missing', () {
      const streams = StravaStreamsResponse(
        streams: [
          StravaStream(type: 'heartrate', data: [120, 130]),
        ],
      );

      final samples = HeartRateMapper.map(
        activityStartTime: DateTime.utc(2024, 1, 15, 7),
        streams: streams,
      );

      expect(samples, isEmpty);
    });

    test('returns empty list when stream lengths mismatch', () {
      const streams = StravaStreamsResponse(
        streams: [
          StravaStream(type: 'time', data: [0, 5]),
          StravaStream(type: 'heartrate', data: [120, 130, 140]),
        ],
      );

      final samples = HeartRateMapper.map(
        activityStartTime: DateTime.utc(2024, 1, 15, 7),
        streams: streams,
      );

      expect(samples, isEmpty);
    });

    test('generates providerRecordId when activityId is null', () {
      final start = DateTime.utc(2024, 1, 15, 7);
      const streams = StravaStreamsResponse(
        streams: [
          StravaStream(type: 'time', data: [0, 5]),
          StravaStream(type: 'heartrate', data: [120, 130]),
        ],
      );

      final samples = HeartRateMapper.map(
        activityStartTime: start,
        streams: streams,
      );

      expect(samples[0].providerRecordId, isNotNull);
      expect(samples[1].providerRecordId, isNotNull);
      expect(samples[0].providerRecordId, isNot(samples[1].providerRecordId));
    });
  });
}
