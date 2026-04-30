import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('BloodOxygenSample', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 10, 5);

    BloodOxygenSample createMinimal() => BloodOxygenSample(
      id: 'bo-1',
      provider: DataProvider.apple,
      providerRecordType: 'HKQuantityTypeIdentifierOxygenSaturation',
      startTime: now,
      endTime: later,
      capturedAt: now,
      percentage: 98.5,
    );

    BloodOxygenSample createFull() => BloodOxygenSample(
      id: 'bo-2',
      provider: DataProvider.garmin,
      providerRecordType: 'spo2',
      startTime: now,
      endTime: later,
      timezone: 'Europe/London',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.native_),
      freshness: Freshness.cached,
      extensions: const {'altitude': 1500},
      percentage: 95,
      supplementalOxygen: true,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.percentage, 98.5);
      expect(record.supplementalOxygen, isNull);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.percentage, 95.0);
      expect(record.supplementalOxygen, isTrue);
      expect(record.timezone, 'Europe/London');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(percentage: 99);
      expect(copy.percentage, 99.0);
      expect(copy.id, 'bo-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = BloodOxygenSample.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(BloodOxygenSample.fromJson(decoded), equals(record));
    });

    test('envelope fields accessible via mixin', () {
      final record = createFull();
      expect(record.id, isNotEmpty);
      expect(record.provider, DataProvider.garmin);
      expect(record.duration, const Duration(minutes: 5));
    });

    test('default values are correct', () {
      final record = createMinimal();
      expect(record.freshness, Freshness.live);
      expect(record.extensions, isEmpty);
      expect(record.provenance, isNull);
    });
  });
}
