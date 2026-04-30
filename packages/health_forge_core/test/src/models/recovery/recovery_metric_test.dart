import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('RecoveryMetric', () {
    final now = DateTime.utc(2026, 3, 17, 8);
    final dayStart = DateTime.utc(2026, 3, 17);
    final dayEnd = DateTime.utc(2026, 3, 17, 23, 59, 59);

    test('creates with required fields only', () {
      final metric = RecoveryMetric(
        id: 'rm-1',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 72,
      );

      expect(metric.id, 'rm-1');
      expect(metric.provider, DataProvider.garmin);
      expect(metric.score, 72);
    });

    test('creates with all fields including optionals', () {
      final metric = RecoveryMetric(
        id: 'rm-2',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 88,
        recoveryLevel: 'high',
        timezone: 'America/New_York',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
        freshness: Freshness.cached,
        extensions: const {'source': 'garmin'},
      );

      expect(metric.score, 88);
      expect(metric.recoveryLevel, 'high');
      expect(metric.timezone, 'America/New_York');
      expect(metric.provenance?.dataOrigin, DataOrigin.native_);
      expect(metric.freshness, Freshness.cached);
      expect(metric.extensions, {'source': 'garmin'});
    });

    test('has correct default values', () {
      final metric = RecoveryMetric(
        id: 'rm-3',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 50,
      );

      expect(metric.freshness, Freshness.live);
      expect(metric.extensions, isEmpty);
      expect(metric.timezone, isNull);
      expect(metric.provenance, isNull);
      expect(metric.recoveryLevel, isNull);
    });

    test('supports equality', () {
      final a = RecoveryMetric(
        id: 'rm-4',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 72,
      );
      final b = RecoveryMetric(
        id: 'rm-4',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 72,
      );
      final c = RecoveryMetric(
        id: 'rm-5',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 30,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      final original = RecoveryMetric(
        id: 'rm-6',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 72,
      );
      final copy = original.copyWith(score: 90, recoveryLevel: 'excellent');

      expect(copy.score, 90);
      expect(copy.recoveryLevel, 'excellent');
      expect(copy.id, 'rm-6');
    });

    test('serializes to JSON and back', () {
      final metric = RecoveryMetric(
        id: 'rm-7',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 72,
        recoveryLevel: 'moderate',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
      );

      final json = metric.toJson();
      final restored = RecoveryMetric.fromJson(json);
      expect(restored, equals(metric));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = RecoveryMetric.fromJson(decoded);
      expect(restored2, equals(metric));
    });

    test('provides envelope fields via mixin', () {
      final metric = RecoveryMetric(
        id: 'rm-8',
        provider: DataProvider.garmin,
        providerRecordType: 'recovery',
        startTime: dayStart,
        endTime: dayEnd,
        capturedAt: now,
        score: 60,
        timezone: 'US/Eastern',
        provenance: const Provenance(dataOrigin: DataOrigin.mapped),
        freshness: Freshness.cached,
        extensions: const {'raw': true},
      );

      expect(metric.duration.inHours, greaterThan(0));
      expect(metric.id, 'rm-8');
      expect(metric.provider, DataProvider.garmin);
      expect(metric.providerRecordType, 'recovery');
      expect(metric.timezone, 'US/Eastern');
      expect(metric.provenance?.dataOrigin, DataOrigin.mapped);
      expect(metric.freshness, Freshness.cached);
      expect(metric.extensions, {'raw': true});
    });
  });
}
