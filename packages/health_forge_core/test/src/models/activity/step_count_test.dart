import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('StepCount', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    StepCount createMinimal() => StepCount(
      id: 'sc-1',
      provider: DataProvider.apple,
      providerRecordType: 'HKQuantityTypeIdentifierStepCount',
      startTime: now,
      endTime: later,
      capturedAt: now,
      count: 5000,
    );

    StepCount createFull() => StepCount(
      id: 'sc-2',
      provider: DataProvider.garmin,
      providerRecordType: 'dailySteps',
      startTime: now,
      endTime: later,
      timezone: 'Europe/London',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.mapped),
      freshness: Freshness.cached,
      extensions: const {'device': 'watch'},
      count: 12345,
      source: 'Garmin Venu',
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.count, 5000);
      expect(record.source, isNull);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.count, 12345);
      expect(record.source, 'Garmin Venu');
      expect(record.timezone, 'Europe/London');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(count: 9999);
      expect(copy.count, 9999);
      expect(copy.id, 'sc-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = StepCount.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(StepCount.fromJson(decoded), equals(record));
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
