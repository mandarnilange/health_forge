import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_apple/src/health_data_record.dart';
import 'package:health_forge_apple/src/mappers/respiratory_mapper.dart';
import 'package:health_forge_core/health_forge_core.dart';

void main() {
  final now = DateTime(2024, 6, 15, 10);
  final later = DateTime(2024, 6, 15, 10, 5);

  group('RespiratoryMapper', () {
    group('BLOOD_OXYGEN', () {
      test('maps to BloodOxygenSample with percentage', () {
        final record = HealthDataRecord(
          type: 'BLOOD_OXYGEN',
          value: 98.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'spo2-uuid',
          deviceModel: 'Apple Watch Series 9',
        );

        final result = RespiratoryMapper.map(record);

        expect(result, isA<BloodOxygenSample>());
        final spo2 = result as BloodOxygenSample;
        expect(spo2.percentage, 98.5);
        expect(spo2.provider, DataProvider.apple);
        expect(spo2.providerRecordType, 'BLOOD_OXYGEN');
        expect(spo2.startTime, now);
        expect(spo2.endTime, later);
        expect(spo2.id, 'spo2-uuid');
        expect(spo2.provenance, isNotNull);
        expect(spo2.provenance!.dataOrigin, DataOrigin.native_);
        expect(spo2.provenance!.sourceDevice?.model, 'Apple Watch Series 9');
        expect(spo2.provenance!.sourceDevice?.manufacturer, 'Apple Watch');
        expect(spo2.provenance!.sourceApp, 'com.apple.health');
      });
    });

    group('RESPIRATORY_RATE', () {
      test('maps to RespiratoryRate with breaths per minute', () {
        final record = HealthDataRecord(
          type: 'RESPIRATORY_RATE',
          value: 16.5,
          dateFrom: now,
          dateTo: later,
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.health',
          uuid: 'rr-uuid',
        );

        final result = RespiratoryMapper.map(record);

        expect(result, isA<RespiratoryRate>());
        final rr = result as RespiratoryRate;
        expect(rr.breathsPerMinute, 16.5);
        expect(rr.provider, DataProvider.apple);
        expect(rr.providerRecordType, 'RESPIRATORY_RATE');
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

      expect(() => RespiratoryMapper.map(record), throwsArgumentError);
    });
  });
}
