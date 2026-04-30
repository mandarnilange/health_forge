import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/models/oura_heart_rate_response.dart';

void main() {
  group('OuraHeartRateResponse', () {
    late Map<String, dynamic> json;

    setUp(() {
      final file = File('test/fixtures/heart_rate_response.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses data list', () {
      final response = OuraHeartRateResponse.fromJson(json);
      expect(response.data, hasLength(2));
    });

    group('OuraHeartRateData', () {
      late OuraHeartRateData data;

      setUp(() {
        data = OuraHeartRateResponse.fromJson(json).data.first;
      });

      test('parses bpm', () {
        expect(data.bpm, 72);
      });

      test('parses source', () {
        expect(data.source, 'awake');
      });

      test('parses timestamp', () {
        expect(data.timestamp, '2024-01-15T10:30:00+00:00');
      });
    });
  });
}
