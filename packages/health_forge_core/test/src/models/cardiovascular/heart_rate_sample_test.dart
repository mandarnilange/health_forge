import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('HeartRateSample', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 10, 0, 1);

    HeartRateSample createMinimal() => HeartRateSample(
          id: 'hr-1',
          provider: DataProvider.apple,
          providerRecordType: 'HKQuantityTypeIdentifierHeartRate',
          startTime: now,
          endTime: later,
          capturedAt: now,
          beatsPerMinute: 72,
        );

    HeartRateSample createFull() => HeartRateSample(
          id: 'hr-2',
          provider: DataProvider.garmin,
          providerRecordType: 'heartRateSample',
          startTime: now,
          endTime: later,
          timezone: 'America/Chicago',
          capturedAt: now,
          provenance: const Provenance(dataOrigin: DataOrigin.native_),
          freshness: Freshness.cached,
          extensions: const {'sensor': 'wrist'},
          beatsPerMinute: 145,
          context: 'workout',
        );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.beatsPerMinute, 72);
      expect(record.context, isNull);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.beatsPerMinute, 145);
      expect(record.context, 'workout');
      expect(record.timezone, 'America/Chicago');
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(beatsPerMinute: 80);
      expect(copy.beatsPerMinute, 80);
      expect(copy.id, 'hr-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = HeartRateSample.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(HeartRateSample.fromJson(decoded), equals(record));
    });

    test('envelope fields accessible via mixin', () {
      final record = createFull();
      expect(record.id, isNotEmpty);
      expect(record.provider, DataProvider.garmin);
      expect(record.duration, const Duration(seconds: 1));
    });

    test('default values are correct', () {
      final record = createMinimal();
      expect(record.freshness, Freshness.live);
      expect(record.extensions, isEmpty);
      expect(record.provenance, isNull);
    });
  });
}
