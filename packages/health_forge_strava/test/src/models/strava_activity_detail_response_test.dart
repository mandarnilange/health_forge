import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/models/strava_activity_detail_response.dart';

void main() {
  group('StravaActivityDetailResponse', () {
    test('parses detail response from JSON', () {
      final file = File('test/fixtures/activity_detail_response.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final response = StravaActivityDetailResponse.fromJson(json);

      expect(response.id, 12345678901);
      expect(response.name, 'Morning Run');
      expect(response.type, 'Run');
      expect(response.distance, 10000.0);
      expect(response.totalElevationGain, 150.5);
      expect(response.kilojoules, 2510.0);
      expect(response.calories, 600.0);
      expect(response.averageHeartrate, 145.0);
      expect(response.maxHeartrate, 172);
      expect(response.sufferScore, 78);
    });

    test('parses segment efforts', () {
      final file = File('test/fixtures/activity_detail_response.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final response = StravaActivityDetailResponse.fromJson(json);

      expect(response.segmentEfforts, isNotNull);
      expect(response.segmentEfforts, hasLength(1));
      expect(response.segmentEfforts!.first['name'], 'Park Loop');
    });

    test('parses map polylines', () {
      final file = File('test/fixtures/activity_detail_response.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final response = StravaActivityDetailResponse.fromJson(json);

      expect(response.mapPolyline, 'full_encoded_polyline_here');
      expect(response.mapSummaryPolyline, 'abc123xyz');
    });
  });
}
