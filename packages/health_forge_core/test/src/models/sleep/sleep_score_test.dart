import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('SleepScore', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final bedtime = DateTime.utc(2026, 3, 16, 23);
    final wakeUp = DateTime.utc(2026, 3, 17, 7);

    test('creates with required fields only', () {
      final score = SleepScore(
        id: 'ss-1',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 85,
      );

      expect(score.id, 'ss-1');
      expect(score.provider, DataProvider.oura);
      expect(score.score, 85);
    });

    test('creates with all fields including optionals', () {
      final score = SleepScore(
        id: 'ss-2',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 92,
        qualityRating: 'excellent',
        timezone: 'America/New_York',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
        freshness: Freshness.cached,
        extensions: const {'source': 'oura'},
      );

      expect(score.score, 92);
      expect(score.qualityRating, 'excellent');
      expect(score.timezone, 'America/New_York');
      expect(score.provenance?.dataOrigin, DataOrigin.native_);
      expect(score.freshness, Freshness.cached);
      expect(score.extensions, {'source': 'oura'});
    });

    test('has correct default values', () {
      final score = SleepScore(
        id: 'ss-3',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 70,
      );

      expect(score.freshness, Freshness.live);
      expect(score.extensions, isEmpty);
      expect(score.timezone, isNull);
      expect(score.provenance, isNull);
      expect(score.qualityRating, isNull);
    });

    test('supports equality', () {
      final a = SleepScore(
        id: 'ss-4',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 85,
      );
      final b = SleepScore(
        id: 'ss-4',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 85,
      );
      final c = SleepScore(
        id: 'ss-5',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 60,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      final original = SleepScore(
        id: 'ss-6',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 85,
      );
      final copy = original.copyWith(score: 90, qualityRating: 'good');

      expect(copy.score, 90);
      expect(copy.qualityRating, 'good');
      expect(copy.id, 'ss-6');
    });

    test('serializes to JSON and back', () {
      final score = SleepScore(
        id: 'ss-7',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 85,
        qualityRating: 'good',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
      );

      final json = score.toJson();
      final restored = SleepScore.fromJson(json);
      expect(restored, equals(score));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = SleepScore.fromJson(decoded);
      expect(restored2, equals(score));
    });

    test('provides envelope fields via mixin', () {
      final score = SleepScore(
        id: 'ss-8',
        provider: DataProvider.oura,
        providerRecordType: 'sleep_score',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        score: 80,
        timezone: 'US/Eastern',
        provenance: const Provenance(dataOrigin: DataOrigin.mapped),
        freshness: Freshness.cached,
        extensions: const {'raw': true},
      );

      expect(score.duration, const Duration(hours: 8));
      expect(score.id, 'ss-8');
      expect(score.provider, DataProvider.oura);
      expect(score.providerRecordType, 'sleep_score');
      expect(score.timezone, 'US/Eastern');
      expect(score.provenance?.dataOrigin, DataOrigin.mapped);
      expect(score.freshness, Freshness.cached);
      expect(score.extensions, {'raw': true});
    });
  });
}
