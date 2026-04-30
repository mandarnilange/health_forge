import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('StressScore', () {
    final now = DateTime.utc(2026, 3, 17, 8);
    final dayStart = DateTime.utc(2026, 3, 17);
    final dayEnd = DateTime.utc(2026, 3, 17, 23, 59, 59);

    test('creates with required fields only', () {
      final stress = StressScore(
        id: 'st-1',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 42,
      );

      expect(stress.id, 'st-1');
      expect(stress.provider, DataProvider.garmin);
      expect(stress.score, 42);
    });

    test('creates with all fields including optionals', () {
      final stress = StressScore(
        id: 'st-2',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 65,
        level: 'medium',
        timezone: 'America/New_York',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
        freshness: Freshness.cached,
        extensions: const {'garmin_raw': 65},
      );

      expect(stress.score, 65);
      expect(stress.level, 'medium');
      expect(stress.timezone, 'America/New_York');
      expect(stress.provenance?.dataOrigin, DataOrigin.native_);
      expect(stress.freshness, Freshness.cached);
      expect(stress.extensions, {'garmin_raw': 65});
    });

    test('has correct default values', () {
      final stress = StressScore(
        id: 'st-3',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 30,
      );

      expect(stress.freshness, Freshness.live);
      expect(stress.extensions, isEmpty);
      expect(stress.timezone, isNull);
      expect(stress.provenance, isNull);
      expect(stress.level, isNull);
    });

    test('supports equality', () {
      final a = StressScore(
        id: 'st-4',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 42,
      );
      final b = StressScore(
        id: 'st-4',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 42,
      );
      final c = StressScore(
        id: 'st-5',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 80,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      final original = StressScore(
        id: 'st-6',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 42,
      );
      final copy = original.copyWith(score: 75, level: 'high');

      expect(copy.score, 75);
      expect(copy.level, 'high');
      expect(copy.id, 'st-6');
    });

    test('serializes to JSON and back', () {
      final stress = StressScore(
        id: 'st-7',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 42,
        level: 'low',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
      );

      final json = stress.toJson();
      final restored = StressScore.fromJson(json);
      expect(restored, equals(stress));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = StressScore.fromJson(decoded);
      expect(restored2, equals(stress));
    });

    test('provides envelope fields via mixin', () {
      final stress = StressScore(
        id: 'st-8',
        provider: DataProvider.garmin,
        providerRecordType: 'stress',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 50,
        timezone: 'US/Eastern',
        provenance: const Provenance(dataOrigin: DataOrigin.mapped),
        freshness: Freshness.cached,
        extensions: const {'raw': true},
      );

      expect(stress.duration.inHours, greaterThan(0));
      expect(stress.id, 'st-8');
      expect(stress.provider, DataProvider.garmin);
      expect(stress.providerRecordType, 'stress');
      expect(stress.timezone, 'US/Eastern');
      expect(stress.provenance?.dataOrigin, DataOrigin.mapped);
      expect(stress.freshness, Freshness.cached);
      expect(stress.extensions, {'raw': true});
    });
  });
}
