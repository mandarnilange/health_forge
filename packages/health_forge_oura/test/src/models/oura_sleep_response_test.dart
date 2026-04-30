import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/models/oura_sleep_response.dart';

void main() {
  group('OuraSleepResponse', () {
    late Map<String, dynamic> json;

    setUp(() {
      final file = File('test/fixtures/sleep_response.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses data list from JSON', () {
      final response = OuraSleepResponse.fromJson(json);
      expect(response.data, hasLength(1));
    });

    test('parses next_token', () {
      json['next_token'] = 'abc123';
      final response = OuraSleepResponse.fromJson(json);
      expect(response.nextToken, 'abc123');
    });

    test('parses null next_token', () {
      final response = OuraSleepResponse.fromJson(json);
      expect(response.nextToken, isNull);
    });

    group('OuraSleepData', () {
      late OuraSleepData data;

      setUp(() {
        final response = OuraSleepResponse.fromJson(json);
        data = response.data.first;
      });

      test('parses id', () {
        expect(data.id, 'sleep_001');
      });

      test('parses average_breath', () {
        expect(data.averageBreath, 14.5);
      });

      test('parses average_heart_rate', () {
        expect(data.averageHeartRate, 52.3);
      });

      test('parses average_hrv', () {
        expect(data.averageHrv, 45);
      });

      test('parses bedtime timestamps', () {
        expect(data.bedtimeStart, '2024-01-15T22:30:00+00:00');
        expect(data.bedtimeEnd, '2024-01-16T06:45:00+00:00');
      });

      test('parses sleep durations', () {
        expect(data.deepSleepDuration, 5400);
        expect(data.lightSleepDuration, 14400);
        expect(data.remSleepDuration, 7200);
        expect(data.totalSleepDuration, 27000);
      });

      test('parses efficiency', () {
        expect(data.efficiency, 92);
      });

      test('parses hr_5_min', () {
        expect(data.hr5Min, [55, 54, 52, 50, 49, 48, 50, 52, 54, 56]);
      });

      test('parses sleep_phase_5_min', () {
        expect(data.sleepPhase5Min, '4411112233334411122333344111');
      });

      test('parses time_in_bed', () {
        expect(data.timeInBed, 29700);
      });

      test('parses type', () {
        expect(data.type, 'long_sleep');
      });

      test('parses latency', () {
        expect(data.latency, 300);
      });

      test('parses restless_periods', () {
        expect(data.restlessPeriods, 3);
      });
    });
  });
}
