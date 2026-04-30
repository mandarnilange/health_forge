import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/models/oura_daily_activity_response.dart';

void main() {
  group('OuraDailyActivityResponse', () {
    late Map<String, dynamic> json;

    setUp(() {
      final file = File('test/fixtures/daily_activity_response.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses data list', () {
      final response = OuraDailyActivityResponse.fromJson(json);
      expect(response.data, hasLength(1));
    });

    group('OuraDailyActivityData', () {
      late OuraDailyActivityData data;

      setUp(() {
        data = OuraDailyActivityResponse.fromJson(json).data.first;
      });

      test('parses id', () {
        expect(data.id, 'activity_001');
      });

      test('parses day', () {
        expect(data.day, '2024-01-15');
      });

      test('parses active_calories', () {
        expect(data.activeCalories, 450);
      });

      test('parses total_calories', () {
        expect(data.totalCalories, 2150);
      });

      test('parses steps', () {
        expect(data.steps, 8523);
      });

      test('parses timestamp', () {
        expect(data.timestamp, '2024-01-15T00:00:00+00:00');
      });
    });
  });
}
