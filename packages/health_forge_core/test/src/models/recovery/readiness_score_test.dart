import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReadinessScore', () {
    final now = DateTime.utc(2026, 3, 17, 8);
    final dayStart = DateTime.utc(2026, 3, 17);
    final dayEnd = DateTime.utc(2026, 3, 17, 23, 59, 59);

    test('creates with required fields only', () {
      final readiness = ReadinessScore(
        id: 'rs-1',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 82,
      );

      expect(readiness.id, 'rs-1');
      expect(readiness.provider, DataProvider.oura);
      expect(readiness.score, 82);
    });

    test('creates with all fields including optionals', () {
      final readiness = ReadinessScore(
        id: 'rs-2',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 90,
        contributors: const {'sleep': 85, 'hrv': 92, 'activity': 78},
        timezone: 'America/New_York',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
        freshness: Freshness.cached,
        extensions: const {'version': 2},
      );

      expect(readiness.score, 90);
      expect(readiness.contributors, {'sleep': 85, 'hrv': 92, 'activity': 78});
      expect(readiness.timezone, 'America/New_York');
      expect(readiness.provenance?.dataOrigin, DataOrigin.native_);
      expect(readiness.freshness, Freshness.cached);
      expect(readiness.extensions, {'version': 2});
    });

    test('has correct default values', () {
      final readiness = ReadinessScore(
        id: 'rs-3',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 75,
      );

      expect(readiness.freshness, Freshness.live);
      expect(readiness.extensions, isEmpty);
      expect(readiness.timezone, isNull);
      expect(readiness.provenance, isNull);
      expect(readiness.contributors, isNull);
    });

    test('supports equality', () {
      final a = ReadinessScore(
        id: 'rs-4',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 82,
      );
      final b = ReadinessScore(
        id: 'rs-4',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 82,
      );
      final c = ReadinessScore(
        id: 'rs-5',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 60,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      final original = ReadinessScore(
        id: 'rs-6',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 82,
      );
      final copy = original.copyWith(
        score: 95,
        contributors: const {'sleep': 90},
      );

      expect(copy.score, 95);
      expect(copy.contributors, {'sleep': 90});
      expect(copy.id, 'rs-6');
    });

    test('serializes to JSON and back', () {
      final readiness = ReadinessScore(
        id: 'rs-7',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 82,
        contributors: const {'sleep': 85, 'hrv': 92},
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
      );

      final json = readiness.toJson();
      final restored = ReadinessScore.fromJson(json);
      expect(restored, equals(readiness));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = ReadinessScore.fromJson(decoded);
      expect(restored2, equals(readiness));
    });

    test('provides envelope fields via mixin', () {
      final readiness = ReadinessScore(
        id: 'rs-8',
        provider: DataProvider.oura,
        providerRecordType: 'readiness',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 80,
        timezone: 'US/Eastern',
        provenance: const Provenance(dataOrigin: DataOrigin.mapped),
        freshness: Freshness.cached,
        extensions: const {'raw': true},
      );

      expect(readiness.duration.inHours, greaterThan(0));
      expect(readiness.id, 'rs-8');
      expect(readiness.provider, DataProvider.oura);
      expect(readiness.providerRecordType, 'readiness');
      expect(readiness.timezone, 'US/Eastern');
      expect(readiness.provenance?.dataOrigin, DataOrigin.mapped);
      expect(readiness.freshness, Freshness.cached);
      expect(readiness.extensions, {'raw': true});
    });
  });
}
