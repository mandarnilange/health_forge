import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/models/oura_daily_stress_response.dart';

void main() {
  group('OuraDailyStressResponse', () {
    late Map<String, dynamic> json;

    setUp(() {
      final file = File('test/fixtures/daily_stress_response.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses data list', () {
      final response = OuraDailyStressResponse.fromJson(json);
      expect(response.data, hasLength(1));
    });

    group('OuraDailyStressData', () {
      late OuraDailyStressData data;

      setUp(() {
        data = OuraDailyStressResponse.fromJson(json).data.first;
      });

      test('parses id', () {
        expect(data.id, 'stress_001');
      });

      test('parses day', () {
        expect(data.day, '2024-01-15');
      });

      test('parses stress_high', () {
        expect(data.stressHigh, 3600);
      });

      test('parses recovery_high', () {
        expect(data.recoveryHigh, 7200);
      });

      test('parses day_summary', () {
        expect(data.daySummary, 'restored');
      });
    });
  });
}
