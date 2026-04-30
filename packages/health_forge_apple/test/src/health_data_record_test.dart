import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_apple/src/health_data_record.dart';

void main() {
  final now = DateTime(2024, 6, 15, 8);
  final later = DateTime(2024, 6, 15, 8, 30);

  group('HealthDataRecord', () {
    test('construction with all required fields', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(record.type, 'HEART_RATE');
      expect(record.value, 72);
      expect(record.dateFrom, now);
      expect(record.dateTo, later);
      expect(record.sourceName, 'Apple Watch');
      expect(record.sourceId, 'com.apple.health');
    });

    test('uuid defaults to empty string', () {
      final record = HealthDataRecord(
        type: 'WEIGHT',
        value: 75.5,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Withings',
        sourceId: 'com.withings',
      );

      expect(record.uuid, '');
    });

    test('uuid can be set explicitly', () {
      final record = HealthDataRecord(
        type: 'WEIGHT',
        value: 75.5,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Withings',
        sourceId: 'com.withings',
        uuid: 'custom-uuid-123',
      );

      expect(record.uuid, 'custom-uuid-123');
    });

    test('secondaryValue is nullable and defaults to null', () {
      final record = HealthDataRecord(
        type: 'BLOOD_PRESSURE_SYSTOLIC',
        value: 120,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Omron',
        sourceId: 'com.omron',
      );

      expect(record.secondaryValue, isNull);
    });

    test('secondaryValue can be set', () {
      final record = HealthDataRecord(
        type: 'BLOOD_PRESSURE_SYSTOLIC',
        value: 120,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Omron',
        sourceId: 'com.omron',
        secondaryValue: 80,
      );

      expect(record.secondaryValue, 80);
    });

    test('workoutActivityType is nullable and defaults to null', () {
      final record = HealthDataRecord(
        type: 'STEPS',
        value: 10000,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(record.workoutActivityType, isNull);
    });

    test('workoutActivityType can be set', () {
      final record = HealthDataRecord(
        type: 'WORKOUT',
        value: 30,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
        workoutActivityType: 'RUNNING',
      );

      expect(record.workoutActivityType, 'RUNNING');
    });

    test('all fields set simultaneously', () {
      final record = HealthDataRecord(
        type: 'WORKOUT',
        value: 45,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
        uuid: 'full-uuid',
        secondaryValue: 150.5,
        workoutActivityType: 'CYCLING',
        sourceDeviceId: 'device-123',
        deviceModel: 'Apple Watch Series 9',
        recordingMethod: 'automatic',
        metadata: {'key': 'value'},
      );

      expect(record.type, 'WORKOUT');
      expect(record.value, 45);
      expect(record.dateFrom, now);
      expect(record.dateTo, later);
      expect(record.sourceName, 'Apple Watch');
      expect(record.sourceId, 'com.apple.health');
      expect(record.uuid, 'full-uuid');
      expect(record.secondaryValue, 150.5);
      expect(record.workoutActivityType, 'CYCLING');
      expect(record.sourceDeviceId, 'device-123');
      expect(record.deviceModel, 'Apple Watch Series 9');
      expect(record.recordingMethod, 'automatic');
      expect(record.metadata, {'key': 'value'});
    });

    test('sourceDeviceId defaults to empty string', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(record.sourceDeviceId, '');
    });

    test('deviceModel defaults to null', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(record.deviceModel, isNull);
    });

    test('recordingMethod defaults to unknown', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(record.recordingMethod, 'unknown');
    });

    test('metadata defaults to null', () {
      final record = HealthDataRecord(
        type: 'HEART_RATE',
        value: 72,
        dateFrom: now,
        dateTo: later,
        sourceName: 'Apple Watch',
        sourceId: 'com.apple.health',
      );

      expect(record.metadata, isNull);
    });
  });
}
