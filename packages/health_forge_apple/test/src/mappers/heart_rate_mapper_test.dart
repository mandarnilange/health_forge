import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_apple/src/mappers/heart_rate_mapper.dart';
import 'package:health_forge_core/health_forge_core.dart';

void main() {
  final now = DateTime(2024, 6, 15, 10);
  final later = DateTime(2024, 6, 15, 10, 5);

  group('HeartRateMapper', () {
    group('HEART_RATE', () {
      test('maps to HeartRateSample with correct bpm', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 72,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'hr-uuid-1',
          deviceModel: 'Apple Watch Series 9',
        );

        final result = HeartRateMapper.map(record);

        expect(result, isA<HeartRateSample>());
        final hr = result as HeartRateSample;
        expect(hr.beatsPerMinute, 72);
        expect(hr.provider, DataProvider.apple);
        expect(hr.providerRecordType, 'HEART_RATE');
        expect(hr.startTime, now);
        expect(hr.endTime, later);
        expect(hr.id, 'hr-uuid-1');
        expect(hr.provenance, isNotNull);
        expect(hr.provenance!.dataOrigin, DataOrigin.native_);
        expect(hr.provenance!.sourceDevice?.model, 'Apple Watch Series 9');
        expect(hr.provenance!.sourceDevice?.manufacturer, 'Apple Watch');
        expect(hr.provenance!.sourceApp, 'com.apple.health');
      });

      test('uses uuid from record when available', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 80,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'custom-uuid',
        );

        final result = HeartRateMapper.map(record) as HeartRateSample;
        expect(result.id, 'custom-uuid');
      });

      test('generates id when uuid is empty', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 80,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        final result = HeartRateMapper.map(record) as HeartRateSample;
        expect(result.id, isNotEmpty);
      });

      test('truncates fractional bpm', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 72.7,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
        );

        final result = HeartRateMapper.map(record) as HeartRateSample;
        expect(result.beatsPerMinute, 72);
      });
    });

    group('HEART_RATE_VARIABILITY_SDNN', () {
      test('maps to HeartRateVariability with sdnn milliseconds', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE_VARIABILITY_SDNN',
          value: 45.3,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'hrv-uuid-1',
        );

        final result = HeartRateMapper.map(record);

        expect(result, isA<HeartRateVariability>());
        final hrv = result as HeartRateVariability;
        expect(hrv.sdnnMilliseconds, 45.3);
        expect(hrv.provider, DataProvider.apple);
        expect(hrv.providerRecordType, 'HEART_RATE_VARIABILITY_SDNN');
      });
    });

    group('RESTING_HEART_RATE', () {
      test('maps to RestingHeartRate with correct bpm', () {
        final record = HealthDataRecord(
          type: 'RESTING_HEART_RATE',
          value: 58,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'rhr-uuid-1',
        );

        final result = HeartRateMapper.map(record);

        expect(result, isA<RestingHeartRate>());
        final rhr = result as RestingHeartRate;
        expect(rhr.beatsPerMinute, 58);
        expect(rhr.provider, DataProvider.apple);
        expect(rhr.providerRecordType, 'RESTING_HEART_RATE');
      });
    });

    test('throws ArgumentError for unsupported type', () {
      final record = HealthDataRecord(
        type: 'UNKNOWN_TYPE',
        value: 0,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(() => HeartRateMapper.map(record), throwsArgumentError);
    });
  });
}
