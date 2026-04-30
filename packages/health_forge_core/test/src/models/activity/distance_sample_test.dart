import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('DistanceSample', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    DistanceSample createMinimal() => DistanceSample(
      id: 'ds-1',
      provider: DataProvider.strava,
      providerRecordType: 'distance',
      startTime: now,
      endTime: later,
      capturedAt: now,
      distanceMeters: 5000,
    );

    DistanceSample createFull() => DistanceSample(
      id: 'ds-2',
      provider: DataProvider.apple,
      providerRecordType: 'HKQuantityTypeIdentifierDistanceWalkingRunning',
      startTime: now,
      endTime: later,
      timezone: 'Asia/Tokyo',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.native_),
      freshness: Freshness.cached,
      extensions: const {'unit': 'meters'},
      distanceMeters: 10500.5,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.distanceMeters, 5000.0);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.distanceMeters, 10500.5);
      expect(record.timezone, 'Asia/Tokyo');
      expect(record.freshness, Freshness.cached);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(distanceMeters: 8000);
      expect(copy.distanceMeters, 8000.0);
      expect(copy.id, 'ds-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = DistanceSample.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(DistanceSample.fromJson(decoded), equals(record));
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
