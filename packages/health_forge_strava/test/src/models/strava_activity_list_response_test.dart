import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/models/strava_activity_list_response.dart';

void main() {
  group('StravaActivityListResponse', () {
    test('parses activities from bare JSON array', () {
      final file = File('test/fixtures/activities_response.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final response = StravaActivityListResponse.fromJson(json);

      expect(response.activities, hasLength(2));
    });

    test('parses first activity fields correctly', () {
      final file = File('test/fixtures/activities_response.json');
      final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

      final response = StravaActivityListResponse.fromJson(json);
      final activity = response.activities.first;

      expect(activity.id, 12345678901);
      expect(activity.name, 'Morning Run');
      expect(activity.type, 'Run');
      expect(activity.sportType, 'Run');
      expect(activity.startDate, '2024-01-15T07:00:00Z');
      expect(activity.elapsedTime, 3600);
      expect(activity.movingTime, 3400);
      expect(activity.distance, 10000.0);
      expect(activity.totalElevationGain, 150.5);
      expect(activity.kilojoules, 2510.0);
      expect(activity.averageHeartrate, 145.0);
      expect(activity.maxHeartrate, 172);
      expect(activity.sufferScore, 78);
      expect(activity.hasHeartrate, isTrue);
      expect(activity.mapSummaryPolyline, 'abc123xyz');
      expect(activity.timezone, '(GMT+01:00) Europe/Paris');
    });

    test('parses empty array', () {
      final response = StravaActivityListResponse.fromJson([]);
      expect(response.activities, isEmpty);
    });
  });
}
