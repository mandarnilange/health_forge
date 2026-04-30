import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('RestingHeartRate', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    RestingHeartRate createMinimal() => RestingHeartRate(
      id: 'rhr-1',
      provider: DataProvider.oura,
      providerRecordType: 'restingHeartRate',
      startTime: now,
      endTime: later,
      capturedAt: now,
      beatsPerMinute: 58,
    );

    RestingHeartRate createFull() => RestingHeartRate(
      id: 'rhr-2',
      provider: DataProvider.apple,
      providerRecordType: 'HKQuantityTypeIdentifierRestingHeartRate',
      startTime: now,
      endTime: later,
      timezone: 'Europe/Paris',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.native_),
      freshness: Freshness.cached,
      extensions: const {'algo': 'v2'},
      beatsPerMinute: 52,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.beatsPerMinute, 58);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.beatsPerMinute, 52);
      expect(record.timezone, 'Europe/Paris');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(beatsPerMinute: 60);
      expect(copy.beatsPerMinute, 60);
      expect(copy.id, 'rhr-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = RestingHeartRate.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(RestingHeartRate.fromJson(decoded), equals(record));
    });

    test('envelope fields accessible via mixin', () {
      final record = createFull();
      expect(record.id, isNotEmpty);
      expect(record.provider, DataProvider.apple);
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
