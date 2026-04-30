import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('RespiratoryRate', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    RespiratoryRate createMinimal() => RespiratoryRate(
      id: 'rr-1',
      provider: DataProvider.apple,
      providerRecordType: 'HKQuantityTypeIdentifierRespiratoryRate',
      startTime: now,
      endTime: later,
      capturedAt: now,
      breathsPerMinute: 16,
    );

    RespiratoryRate createFull() => RespiratoryRate(
      id: 'rr-2',
      provider: DataProvider.garmin,
      providerRecordType: 'respiratoryRate',
      startTime: now,
      endTime: later,
      timezone: 'America/New_York',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.mapped),
      freshness: Freshness.cached,
      extensions: const {'sensor': 'chest'},
      breathsPerMinute: 18.5,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.breathsPerMinute, 16.0);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.breathsPerMinute, 18.5);
      expect(record.timezone, 'America/New_York');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(breathsPerMinute: 20);
      expect(copy.breathsPerMinute, 20.0);
      expect(copy.id, 'rr-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = RespiratoryRate.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(RespiratoryRate.fromJson(decoded), equals(record));
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
