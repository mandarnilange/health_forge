import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';
import 'package:health_forge_ghc/src/mappers/respiratory_mapper.dart';

void main() {
  final now = DateTime.utc(2026, 3, 17, 10);
  final later = DateTime.utc(2026, 3, 17, 10, 5);

  group('RespiratoryMapper', () {
    group('BLOOD_OXYGEN', () {
      test('maps to BloodOxygenSample', () {
        final record = HealthDataRecord(
          type: 'BLOOD_OXYGEN',
          value: 98.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
          uuid: 'spo2-uuid-1',
          deviceModel: 'Pixel Watch 2',
        );

        final result = RespiratoryMapper.map(record);

        expect(result, isA<BloodOxygenSample>());
        final sample = result as BloodOxygenSample;
        expect(sample.percentage, 98.5);
        expect(sample.provider, DataProvider.googleHealthConnect);
        expect(sample.providerRecordType, 'BLOOD_OXYGEN');
        expect(sample.startTime, now);
        expect(sample.endTime, later);
        expect(sample.id, 'spo2-uuid-1');
        expect(sample.provenance, isNotNull);
        expect(sample.provenance!.dataOrigin, DataOrigin.native_);
        expect(sample.provenance!.sourceDevice?.model, 'Pixel Watch 2');
        expect(sample.provenance!.sourceDevice?.manufacturer, 'Pixel Watch');
        expect(
          sample.provenance!.sourceApp,
          'com.google.android.apps.fitness',
        );
      });

      test('uses uuid when provided', () {
        final record = HealthDataRecord(
          type: 'BLOOD_OXYGEN',
          value: 97,
          dateFrom: now,
          dateTo: later,
          sourceName: 'test',
          sourceId: 'test',
          uuid: 'spo2-uuid-1',
        );

        final result = RespiratoryMapper.map(record) as BloodOxygenSample;
        expect(result.id, 'spo2-uuid-1');
      });
    });

    group('RESPIRATORY_RATE', () {
      test('maps to RespiratoryRate', () {
        final record = HealthDataRecord(
          type: 'RESPIRATORY_RATE',
          value: 16.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Pixel Watch',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = RespiratoryMapper.map(record);

        expect(result, isA<RespiratoryRate>());
        final rate = result as RespiratoryRate;
        expect(rate.breathsPerMinute, 16.5);
        expect(rate.provider, DataProvider.googleHealthConnect);
        expect(rate.providerRecordType, 'RESPIRATORY_RATE');
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
        () => RespiratoryMapper.map(record),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
