import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('Weight', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 10, 1);

    Weight createMinimal() => Weight(
          id: 'w-1',
          provider: DataProvider.apple,
          providerRecordType: 'HKQuantityTypeIdentifierBodyMass',
          startTime: now,
          endTime: later,
          capturedAt: now,
          kilograms: 75.5,
        );

    Weight createFull() => Weight(
          id: 'w-2',
          provider: DataProvider.garmin,
          providerRecordType: 'weight',
          startTime: now,
          endTime: later,
          timezone: 'Asia/Tokyo',
          capturedAt: now,
          provenance: const Provenance(dataOrigin: DataOrigin.mapped),
          freshness: Freshness.cached,
          extensions: const {'scale': 'Withings'},
          kilograms: 80.2,
          bmi: 24.5,
        );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.kilograms, 75.5);
      expect(record.bmi, isNull);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.kilograms, 80.2);
      expect(record.bmi, 24.5);
      expect(record.timezone, 'Asia/Tokyo');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(kilograms: 70);
      expect(copy.kilograms, 70.0);
      expect(copy.id, 'w-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = Weight.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(Weight.fromJson(decoded), equals(record));
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
