import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/models/oura_daily_sleep_response.dart';

void main() {
  group('OuraDailySleepResponse', () {
    late Map<String, dynamic> json;

    setUp(() {
      final file = File('test/fixtures/daily_sleep_response.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses data list', () {
      final response = OuraDailySleepResponse.fromJson(json);
      expect(response.data, hasLength(1));
    });

    test('parses null next_token', () {
      final response = OuraDailySleepResponse.fromJson(json);
      expect(response.nextToken, isNull);
    });

    group('OuraDailySleepData', () {
      late OuraDailySleepData data;

      setUp(() {
        data = OuraDailySleepResponse.fromJson(json).data.first;
      });

      test('parses id', () {
        expect(data.id, 'daily_sleep_001');
      });

      test('parses day', () {
        expect(data.day, '2024-01-15');
      });

      test('parses score', () {
        expect(data.score, 85);
      });

      test('parses contributors', () {
        expect(data.contributors, isNotNull);
        expect(data.contributors!['deep_sleep'], 90);
        expect(data.contributors!['efficiency'], 88);
      });

      test('parses timestamp', () {
        expect(data.timestamp, '2024-01-15T00:00:00+00:00');
      });
    });
  });
}
