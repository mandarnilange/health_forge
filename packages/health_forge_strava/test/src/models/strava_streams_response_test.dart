import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/models/strava_streams_response.dart';

void main() {
  group('StravaStreamsResponse', () {
    test('parses streams from JSON array', () {
      final file = File('test/fixtures/streams_response.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final response = StravaStreamsResponse.fromJson(json);

      expect(response.streams, hasLength(2));
    });

    test('dataForType returns heartrate data', () {
      final file = File('test/fixtures/streams_response.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final response = StravaStreamsResponse.fromJson(json);
      final hrData = response.dataForType('heartrate');

      expect(hrData, isNotNull);
      expect(hrData, [120, 125, 130, 135, 140, 145]);
    });

    test('dataForType returns time data', () {
      final file = File('test/fixtures/streams_response.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final response = StravaStreamsResponse.fromJson(json);
      final timeData = response.dataForType('time');

      expect(timeData, isNotNull);
      expect(timeData, [0, 1, 2, 3, 4, 5]);
    });

    test('dataForType returns null for missing type', () {
      final file = File('test/fixtures/streams_response.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final response = StravaStreamsResponse.fromJson(json);
      expect(response.dataForType('cadence'), isNull);
    });

    test('parses stream metadata', () {
      final file = File('test/fixtures/streams_response.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final response = StravaStreamsResponse.fromJson(json);
      final hrStream =
          response.streams.where((s) => s.type == 'heartrate').first;

      expect(hrStream.seriesType, 'distance');
      expect(hrStream.originalSize, 6);
      expect(hrStream.resolution, 'high');
    });
  });
}
