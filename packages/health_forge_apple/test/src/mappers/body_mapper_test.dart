import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_apple/src/mappers/body_mapper.dart';
import 'package:health_forge_core/health_forge_core.dart';

void main() {
  final now = DateTime(2024, 6, 15, 8);
  final later = DateTime(2024, 6, 15, 8, 1);

  group('BodyMapper', () {
    group('WEIGHT', () {
      test('maps to Weight with kilograms', () {
        final record = HealthDataRecord(
          type: 'WEIGHT',
          value: 75.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Withings',
          sourceId: 'com.withings',
          uuid: 'weight-uuid',
          deviceModel: 'Body+',
        );

        final result = BodyMapper.map(record);

        expect(result, isA<Weight>());
        final w = result as Weight;
        expect(w.kilograms, 75.5);
        expect(w.provider, DataProvider.apple);
        expect(w.providerRecordType, 'WEIGHT');
        expect(w.id, 'weight-uuid');
        expect(w.provenance, isNotNull);
        expect(w.provenance!.dataOrigin, DataOrigin.native_);
        expect(w.provenance!.sourceDevice?.model, 'Body+');
        expect(w.provenance!.sourceDevice?.manufacturer, 'Withings');
        expect(w.provenance!.sourceApp, 'com.withings');
      });
    });

    group('BODY_FAT_PERCENTAGE', () {
      test('maps to BodyFat with percentage', () {
        final record = HealthDataRecord(
          type: 'BODY_FAT_PERCENTAGE',
          value: 18.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Withings',
          sourceId: 'com.withings',
          uuid: 'bf-uuid',
        );

        final result = BodyMapper.map(record);

        expect(result, isA<BodyFat>());
        final bf = result as BodyFat;
        expect(bf.percentage, 18.5);
        expect(bf.provider, DataProvider.apple);
        expect(bf.providerRecordType, 'BODY_FAT_PERCENTAGE');
      });
    });

    group('BLOOD_PRESSURE_SYSTOLIC', () {
      test('maps to BloodPressure with systolic and diastolic', () {
        final record = HealthDataRecord(
          type: 'BLOOD_PRESSURE_SYSTOLIC',
          value: 120,
          secondaryValue: 80,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Omron',
          sourceId: 'com.omron',
          uuid: 'bp-uuid',
        );

        final result = BodyMapper.map(record);

        expect(result, isA<BloodPressure>());
        final bp = result as BloodPressure;
        expect(bp.systolicMmHg, 120);
        expect(bp.diastolicMmHg, 80);
        expect(bp.provider, DataProvider.apple);
      });

      test('uses 0 for diastolic when secondaryValue is null', () {
        final record = HealthDataRecord(
          type: 'BLOOD_PRESSURE_SYSTOLIC',
          value: 120,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Omron',
          sourceId: 'com.omron',
        );

        final result = BodyMapper.map(record) as BloodPressure;
        expect(result.systolicMmHg, 120);
        expect(result.diastolicMmHg, 0);
      });
    });

    group('BLOOD_GLUCOSE', () {
      test('maps to BloodGlucose with mg/dL', () {
        final record = HealthDataRecord(
          type: 'BLOOD_GLUCOSE',
          value: 95,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Dexcom',
          sourceId: 'com.dexcom',
          uuid: 'bg-uuid',
        );

        final result = BodyMapper.map(record);

        expect(result, isA<BloodGlucose>());
        final bg = result as BloodGlucose;
        expect(bg.milligramsPerDeciliter, 95.0);
        expect(bg.provider, DataProvider.apple);
        expect(bg.providerRecordType, 'BLOOD_GLUCOSE');
      });
    });

    test('throws ArgumentError for unsupported type', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(() => BodyMapper.map(record), throwsArgumentError);
    });
  });
}
