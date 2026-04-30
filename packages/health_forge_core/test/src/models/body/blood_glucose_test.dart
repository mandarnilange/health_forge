import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('BloodGlucose', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 10, 5);

    BloodGlucose createMinimal() => BloodGlucose(
          id: 'bg-1',
          provider: DataProvider.apple,
          providerRecordType: 'HKQuantityTypeIdentifierBloodGlucose',
          startTime: now,
          endTime: later,
          capturedAt: now,
          milligramsPerDeciliter: 95,
        );

    BloodGlucose createFull() => BloodGlucose(
          id: 'bg-2',
          provider: DataProvider.garmin,
          providerRecordType: 'bloodGlucose',
          startTime: now,
          endTime: later,
          timezone: 'America/Chicago',
          capturedAt: now,
          provenance: const Provenance(dataOrigin: DataOrigin.native_),
          freshness: Freshness.cached,
          extensions: const {'meter': 'Dexcom G7'},
          milligramsPerDeciliter: 140,
          mealContext: 'postprandial',
        );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.milligramsPerDeciliter, 95.0);
      expect(record.mealContext, isNull);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.milligramsPerDeciliter, 140.0);
      expect(record.mealContext, 'postprandial');
      expect(record.timezone, 'America/Chicago');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(milligramsPerDeciliter: 110);
      expect(copy.milligramsPerDeciliter, 110.0);
      expect(copy.id, 'bg-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = BloodGlucose.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(BloodGlucose.fromJson(decoded), equals(record));
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
