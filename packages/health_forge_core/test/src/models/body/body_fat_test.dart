import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('BodyFat', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 10, 1);

    BodyFat createMinimal() => BodyFat(
      id: 'bf-1',
      provider: DataProvider.apple,
      providerRecordType: 'HKQuantityTypeIdentifierBodyFatPercentage',
      startTime: now,
      endTime: later,
      capturedAt: now,
      percentage: 18.5,
    );

    BodyFat createFull() => BodyFat(
      id: 'bf-2',
      provider: DataProvider.garmin,
      providerRecordType: 'bodyFat',
      startTime: now,
      endTime: later,
      timezone: 'US/Pacific',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.native_),
      freshness: Freshness.cached,
      extensions: const {'method': 'bioimpedance'},
      percentage: 22,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.percentage, 18.5);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.percentage, 22.0);
      expect(record.timezone, 'US/Pacific');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(percentage: 20);
      expect(copy.percentage, 20.0);
      expect(copy.id, 'bf-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = BodyFat.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(BodyFat.fromJson(decoded), equals(record));
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
