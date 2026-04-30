import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';

void main() {
  final now = DateTime.utc(2026, 3, 17, 10);
  final later = DateTime.utc(2026, 3, 17, 10, 30);

  group('HealthDataRecord', () {
    test('construction with all required fields', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Google Fit',
        sourceId: 'com.google.android.apps.fitness',
      );

      expect(record.type, 'HEART_RATE');
      expect(record.value, 72);
      expect(record.dateFrom, now);
      expect(record.dateTo, later);
      expect(record.sourceName, 'Google Fit');
      expect(record.sourceId, 'com.google.android.apps.fitness');
    });

    test('uuid defaults to empty string', () {
      final record = HealthDataRecord(
        type: 'WEIGHT',
        value: 75.5,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Google Fit',
        sourceId: 'com.google.android.apps.fitness',
      );

      expect(record.uuid, '');
    });

    test('uuid can be set explicitly', () {
      final record = HealthDataRecord(
        type: 'WEIGHT',
        value: 75.5,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Google Fit',
        sourceId: 'com.google.android.apps.fitness',
        uuid: 'ghc-uuid-456',
      );

      expect(record.uuid, 'ghc-uuid-456');
    });

    test('value stores numeric data', () {
      final record = HealthDataRecord(
        type: 'STEPS',
        value: 10000,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Google Fit',
        sourceId: 'com.google.android.apps.fitness',
      );

      expect(record.value, 10000);
    });

    test('all fields set simultaneously', () {
      final record = HealthDataRecord(
        type: 'BLOOD_GLUCOSE',
        value: 95.3,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Samsung Health',
        sourceId: 'com.samsung.health',
        uuid: 'full-uuid-789',
        sourceDeviceId: 'device-456',
        deviceModel: 'Galaxy Watch 6',
        recordingMethod: 'automatic',
        metadata: {'key': 'value'},
      );

      expect(record.type, 'BLOOD_GLUCOSE');
      expect(record.value, 95.3);
      expect(record.dateFrom, now);
      expect(record.dateTo, later);
      expect(record.sourceName, 'Samsung Health');
      expect(record.sourceId, 'com.samsung.health');
      expect(record.uuid, 'full-uuid-789');
      expect(record.sourceDeviceId, 'device-456');
      expect(record.deviceModel, 'Galaxy Watch 6');
      expect(record.recordingMethod, 'automatic');
      expect(record.metadata, {'key': 'value'});
    });

    test('sourceDeviceId defaults to empty string', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Google Fit',
        sourceId: 'com.google.android.apps.fitness',
      );

      expect(record.sourceDeviceId, '');
    });

    test('deviceModel defaults to null', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Google Fit',
        sourceId: 'com.google.android.apps.fitness',
      );

      expect(record.deviceModel, isNull);
    });

    test('recordingMethod defaults to unknown', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Google Fit',
        sourceId: 'com.google.android.apps.fitness',
      );

      expect(record.recordingMethod, 'unknown');
    });

    test('metadata defaults to null', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Google Fit',
        sourceId: 'com.google.android.apps.fitness',
      );

      expect(record.metadata, isNull);
    });
  });
}
