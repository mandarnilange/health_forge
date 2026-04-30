import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('CaloriesBurned', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    CaloriesBurned createMinimal() => CaloriesBurned(
          id: 'cb-1',
          provider: DataProvider.apple,
          providerRecordType: 'HKQuantityTypeIdentifierActiveEnergyBurned',
          startTime: now,
          endTime: later,
          capturedAt: now,
          totalCalories: 250,
        );

    CaloriesBurned createFull() => CaloriesBurned(
          id: 'cb-2',
          provider: DataProvider.garmin,
          providerRecordType: 'caloriesData',
          startTime: now,
          endTime: later,
          timezone: 'US/Pacific',
          capturedAt: now,
          provenance: const Provenance(dataOrigin: DataOrigin.native_),
          freshness: Freshness.cached,
          extensions: const {'type': 'active'},
          totalCalories: 500,
          activeCalories: 350,
        );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.totalCalories, 250.0);
      expect(record.activeCalories, isNull);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.totalCalories, 500.0);
      expect(record.activeCalories, 350.0);
      expect(record.timezone, 'US/Pacific');
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(activeCalories: 200);
      expect(copy.activeCalories, 200.0);
      expect(copy.totalCalories, 250.0);
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = CaloriesBurned.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(CaloriesBurned.fromJson(decoded), equals(record));
    });

    test('envelope fields accessible via mixin', () {
      final record = createFull();
      expect(record.id, isNotEmpty);
      expect(record.provider, DataProvider.garmin);
      expect(record.duration, const Duration(hours: 1));
    });

    test('default values are correct', () {
      final record = createMinimal();
      expect(record.freshness, Freshness.live);
      expect(record.extensions, isEmpty);
      expect(record.provenance, isNull);
    });
  });
}
