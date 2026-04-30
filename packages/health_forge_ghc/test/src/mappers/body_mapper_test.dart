import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';
import 'package:health_forge_ghc/src/mappers/body_mapper.dart';

void main() {
  final now = DateTime.utc(2026, 3, 17, 10);
  final later = DateTime.utc(2026, 3, 17, 10, 5);

  group('BodyMapper', () {
    group('WEIGHT', () {
      test('maps to Weight', () {
        final record = HealthDataRecord(
          type: 'WEIGHT',
          value: 75.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Google Fit',
          sourceId: 'com.google.android.apps.fitness',
          uuid: 'weight-uuid-1',
          deviceModel: 'Pixel Scale',
        );

        final result = BodyMapper.map(record);

        expect(result, isA<Weight>());
        final weight = result as Weight;
        expect(weight.kilograms, 75.5);
        expect(weight.provider, DataProvider.googleHealthConnect);
        expect(weight.providerRecordType, 'WEIGHT');
        expect(weight.startTime, now);
        expect(weight.endTime, later);
        expect(weight.id, 'weight-uuid-1');
        expect(weight.provenance, isNotNull);
        expect(weight.provenance!.dataOrigin, DataOrigin.native_);
        expect(weight.provenance!.sourceDevice?.model, 'Pixel Scale');
        expect(weight.provenance!.sourceDevice?.manufacturer, 'Google Fit');
        expect(
          weight.provenance!.sourceApp,
          'com.google.android.apps.fitness',
        );
      });

      test('uses uuid when provided', () {
        final record = HealthDataRecord(
          type: 'WEIGHT',
          value: 70,
          dateFrom: now,
          dateTo: later,
          sourceName: 'test',
          sourceId: 'test',
          uuid: 'weight-uuid-1',
        );

        final result = BodyMapper.map(record) as Weight;
        expect(result.id, 'weight-uuid-1');
      });
    });

    group('BODY_FAT_PERCENTAGE', () {
      test('maps to BodyFat', () {
        final record = HealthDataRecord(
          type: 'BODY_FAT_PERCENTAGE',
          value: 18.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Google Fit',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = BodyMapper.map(record);

        expect(result, isA<BodyFat>());
        final bodyFat = result as BodyFat;
        expect(bodyFat.percentage, 18.5);
        expect(bodyFat.provider, DataProvider.googleHealthConnect);
        expect(bodyFat.providerRecordType, 'BODY_FAT_PERCENTAGE');
      });
    });

    group('BLOOD_PRESSURE_SYSTOLIC', () {
      test('maps to BloodPressure', () {
        final record = HealthDataRecord(
          type: 'BLOOD_PRESSURE_SYSTOLIC',
          value: 120,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Google Fit',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = BodyMapper.map(record);

        expect(result, isA<BloodPressure>());
        final bp = result as BloodPressure;
        expect(bp.systolicMmHg, 120);
        expect(bp.diastolicMmHg, 0);
        expect(bp.provider, DataProvider.googleHealthConnect);
        expect(bp.providerRecordType, 'BLOOD_PRESSURE_SYSTOLIC');
      });
    });

    group('BLOOD_GLUCOSE', () {
      test('maps to BloodGlucose', () {
        final record = HealthDataRecord(
          type: 'BLOOD_GLUCOSE',
          value: 95.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Google Fit',
          sourceId: 'com.google.android.apps.fitness',
        );

        final result = BodyMapper.map(record);

        expect(result, isA<BloodGlucose>());
        final glucose = result as BloodGlucose;
        expect(glucose.milligramsPerDeciliter, 95.5);
        expect(glucose.provider, DataProvider.googleHealthConnect);
        expect(glucose.providerRecordType, 'BLOOD_GLUCOSE');
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
        () => BodyMapper.map(record),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
