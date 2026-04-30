import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('BloodPressure', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 10, 1);

    BloodPressure createMinimal() => BloodPressure(
      id: 'bp-1',
      provider: DataProvider.apple,
      providerRecordType: 'HKCorrelationTypeIdentifierBloodPressure',
      startTime: now,
      endTime: later,
      capturedAt: now,
      systolicMmHg: 120,
      diastolicMmHg: 80,
    );

    BloodPressure createFull() => BloodPressure(
      id: 'bp-2',
      provider: DataProvider.garmin,
      providerRecordType: 'bloodPressure',
      startTime: now,
      endTime: later,
      timezone: 'Europe/Berlin',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.mapped),
      freshness: Freshness.cached,
      extensions: const {'cuff': 'left_arm'},
      systolicMmHg: 135,
      diastolicMmHg: 85,
      pulseBpm: 72,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.systolicMmHg, 120);
      expect(record.diastolicMmHg, 80);
      expect(record.pulseBpm, isNull);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.systolicMmHg, 135);
      expect(record.diastolicMmHg, 85);
      expect(record.pulseBpm, 72);
      expect(record.timezone, 'Europe/Berlin');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(systolicMmHg: 130);
      expect(copy.systolicMmHg, 130);
      expect(copy.id, 'bp-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = BloodPressure.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(BloodPressure.fromJson(decoded), equals(record));
    });

    test('envelope fields accessible via mixin', () {
      final record = createFull();
      expect(record.id, isNotEmpty);
      expect(record.provider, DataProvider.garmin);
      expect(record.duration, const Duration(minutes: 1));
    });

    test('default values are correct', () {
      final record = createMinimal();
      expect(record.freshness, Freshness.live);
      expect(record.extensions, isEmpty);
      expect(record.provenance, isNull);
    });
  });
}
