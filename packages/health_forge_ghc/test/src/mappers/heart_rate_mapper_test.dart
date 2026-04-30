import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';
import 'package:health_forge_ghc/src/mappers/heart_rate_mapper.dart';

void main() {
  final now = DateTime.utc(2026, 3, 17, 10);
  final later = DateTime.utc(2026, 3, 17, 10, 5);

  group('HeartRateMapper', () {
    group('HEART_RATE', () {
      test('maps to HeartRateSample', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 72,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
          uuid: 'hr-uuid-1',
          deviceModel: 'Pixel Watch 2',
        );

        final result = HeartRateMapper.map(record);

        expect(result, isA<HeartRateSample>());
        final sample = result as HeartRateSample;
        expect(sample.beatsPerMinute, 72);
        expect(sample.provider, DataProvider.googleHealthConnect);
        expect(sample.providerRecordType, 'HEART_RATE');
        expect(sample.startTime, now);
        expect(sample.endTime, later);
        expect(sample.id, 'hr-uuid-1');
        expect(sample.provenance, isNotNull);
        expect(sample.provenance!.dataOrigin, DataOrigin.native_);
        expect(sample.provenance!.sourceDevice?.model, 'Pixel Watch 2');
        expect(sample.provenance!.sourceDevice?.manufacturer, 'Pixel Watch');
        expect(sample.provenance!.sourceApp, 'com.google.android.apps.fitness');
      });

      test('uses uuid when provided', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 80,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
          uuid: 'custom-uuid-123',
        );

        final result = HeartRateMapper.map(record) as HeartRateSample;
        expect(result.id, 'custom-uuid-123');
      });

      test('generates id when uuid is empty', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 80,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = HeartRateMapper.map(record) as HeartRateSample;
        expect(result.id, isNotEmpty);
      });

      test('rounds fractional bpm', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE',
          value: 72.7,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = HeartRateMapper.map(record) as HeartRateSample;
        expect(result.beatsPerMinute, 73);
      });
    });

    group('HEART_RATE_VARIABILITY_SDNN', () {
      test('maps to HeartRateVariability', () {
        final record = HealthDataRecord(
          type: 'HEART_RATE_VARIABILITY_SDNN',
          value: 45.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = HeartRateMapper.map(record);

        expect(result, isA<HeartRateVariability>());
        final hrv = result as HeartRateVariability;
        expect(hrv.sdnnMilliseconds, 45.5);
        expect(hrv.provider, DataProvider.googleHealthConnect);
        expect(hrv.providerRecordType, 'HEART_RATE_VARIABILITY_SDNN');
      });
    });

    group('RESTING_HEART_RATE', () {
      test('maps to RestingHeartRate', () {
        final record = HealthDataRecord(
          type: 'RESTING_HEART_RATE',
          value: 58,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = HeartRateMapper.map(record);

        expect(result, isA<RestingHeartRate>());
        final rhr = result as RestingHeartRate;
        expect(rhr.beatsPerMinute, 58);
        expect(rhr.provider, DataProvider.googleHealthConnect);
        expect(rhr.providerRecordType, 'RESTING_HEART_RATE');
      });
    });

    test('throws for unsupported type', () {
      final record = HealthDataRecord(
        type: 'UNKNOWN_TYPE',
        value: 0,
        dateFrom: now,
        dateTo: later,
        sourceName: 'test',
        sourceId: 'test',
      );

      expect(
        () => HeartRateMapper.map(record),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
