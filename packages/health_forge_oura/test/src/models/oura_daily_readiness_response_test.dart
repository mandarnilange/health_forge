import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/models/oura_daily_readiness_response.dart';

void main() {
  group('OuraDailyReadinessResponse', () {
    late Map<String, dynamic> json;

    setUp(() {
      final file = File('test/fixtures/daily_readiness_response.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses data list', () {
      final response = OuraDailyReadinessResponse.fromJson(json);
      expect(response.data, hasLength(1));
    });

    group('OuraDailyReadinessData', () {
      late OuraDailyReadinessData data;

      setUp(() {
        data = OuraDailyReadinessResponse.fromJson(json).data.first;
      });

      test('parses id', () {
        expect(data.id, 'readiness_001');
      });

      test('parses score', () {
        expect(data.score, 82);
      });

      test('parses contributors', () {
        expect(data.contributors, isNotNull);
        expect(data.contributors!['activity_balance'], 85);
        expect(data.contributors!['resting_heart_rate'], 92);
      });

      test('parses temperature_deviation', () {
        expect(data.temperatureDeviation, -0.2);
      });

      test('parses timestamp', () {
        expect(data.timestamp, '2024-01-15T00:00:00+00:00');
      });
    });
  });
}
