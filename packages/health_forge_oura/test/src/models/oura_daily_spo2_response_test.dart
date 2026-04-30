import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/models/oura_daily_spo2_response.dart';

void main() {
  group('OuraDailySpo2Response', () {
    late Map<String, dynamic> json;

    setUp(() {
      final file = File('test/fixtures/daily_spo2_response.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses data list', () {
      final response = OuraDailySpo2Response.fromJson(json);
      expect(response.data, hasLength(1));
    });

    group('OuraDailySpo2Data', () {
      late OuraDailySpo2Data data;

      setUp(() {
        data = OuraDailySpo2Response.fromJson(json).data.first;
      });

      test('parses id', () {
        expect(data.id, 'spo2_001');
      });

      test('parses day', () {
        expect(data.day, '2024-01-15');
      });

      test('parses spo2 average', () {
        expect(data.spo2Percentage, isNotNull);
        expect(data.spo2Percentage!.average, 97.5);
      });

      test('parses breathing_disturbance_index', () {
        expect(data.breathingDisturbanceIndex, 1.2);
      });
    });
  });
}
