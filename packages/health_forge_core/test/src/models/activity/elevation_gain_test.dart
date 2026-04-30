import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('ElevationGain', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    ElevationGain createMinimal() => ElevationGain(
      id: 'eg-1',
      provider: DataProvider.strava,
      providerRecordType: 'elevation',
      startTime: now,
      endTime: later,
      capturedAt: now,
      elevationMeters: 150,
    );

    ElevationGain createFull() => ElevationGain(
      id: 'eg-2',
      provider: DataProvider.garmin,
      providerRecordType: 'elevationData',
      startTime: now,
      endTime: later,
      timezone: 'Europe/Berlin',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.mapped),
      freshness: Freshness.cached,
      extensions: const {'climb': true},
      elevationMeters: 320.5,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.elevationMeters, 150.0);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.elevationMeters, 320.5);
      expect(record.timezone, 'Europe/Berlin');
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(elevationMeters: 200);
      expect(copy.elevationMeters, 200.0);
      expect(copy.id, 'eg-1');
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = ElevationGain.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(ElevationGain.fromJson(decoded), equals(record));
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
