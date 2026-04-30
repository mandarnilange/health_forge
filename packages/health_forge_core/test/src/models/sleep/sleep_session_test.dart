import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('SleepSession', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final bedtime = DateTime.utc(2026, 3, 16, 23);
    final wakeUp = DateTime.utc(2026, 3, 17, 7);

    test('creates with required fields only', () {
      final session = SleepSession(
        id: 'sleep-1',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
      );

      expect(session.id, 'sleep-1');
      expect(session.provider, DataProvider.oura);
      expect(session.providerRecordType, 'sleep');
      expect(session.startTime, bedtime);
      expect(session.endTime, wakeUp);
      expect(session.capturedAt, now);
    });

    test('creates with all fields including optionals', () {
      final session = SleepSession(
        id: 'sleep-2',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        timezone: 'America/New_York',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
        freshness: Freshness.cached,
        extensions: const {'key': 'value'},
        totalSleepMinutes: 420,
        remMinutes: 90,
        deepMinutes: 120,
        lightMinutes: 180,
        awakeMinutes: 30,
        efficiency: 88,
        stages: [
          SleepStageSegment(
            stage: SleepStage.deep,
            startTime: bedtime,
            endTime: bedtime.add(const Duration(hours: 2)),
          ),
        ],
      );

      expect(session.timezone, 'America/New_York');
      expect(session.provenance?.dataOrigin, DataOrigin.native_);
      expect(session.freshness, Freshness.cached);
      expect(session.extensions, {'key': 'value'});
      expect(session.totalSleepMinutes, 420);
      expect(session.remMinutes, 90);
      expect(session.deepMinutes, 120);
      expect(session.lightMinutes, 180);
      expect(session.awakeMinutes, 30);
      expect(session.efficiency, 88);
      expect(session.stages, hasLength(1));
    });

    test('has correct default values', () {
      final session = SleepSession(
        id: 'sleep-3',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
      );

      expect(session.freshness, Freshness.live);
      expect(session.extensions, isEmpty);
      expect(session.stages, isEmpty);
      expect(session.timezone, isNull);
      expect(session.provenance, isNull);
      expect(session.totalSleepMinutes, isNull);
      expect(session.remMinutes, isNull);
      expect(session.deepMinutes, isNull);
      expect(session.lightMinutes, isNull);
      expect(session.awakeMinutes, isNull);
      expect(session.efficiency, isNull);
    });

    test('supports equality', () {
      final a = SleepSession(
        id: 'sleep-4',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
      );
      final b = SleepSession(
        id: 'sleep-4',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
      );
      final c = SleepSession(
        id: 'sleep-5',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      final original = SleepSession(
        id: 'sleep-6',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
      );
      final copy = original.copyWith(efficiency: 95, totalSleepMinutes: 400);

      expect(copy.efficiency, 95);
      expect(copy.totalSleepMinutes, 400);
      expect(copy.id, 'sleep-6');
    });

    test('serializes to JSON and back', () {
      final session = SleepSession(
        id: 'sleep-7',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        totalSleepMinutes: 420,
        efficiency: 88,
      );

      final json = session.toJson();
      final restored = SleepSession.fromJson(json);
      expect(restored, equals(session));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = SleepSession.fromJson(decoded);
      expect(restored2, equals(session));
    });

    test('serializes with nested stages', () {
      final session = SleepSession(
        id: 'sleep-8',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        stages: [
          SleepStageSegment(
            stage: SleepStage.deep,
            startTime: bedtime,
            endTime: bedtime.add(const Duration(hours: 1)),
          ),
          SleepStageSegment(
            stage: SleepStage.rem,
            startTime: bedtime.add(const Duration(hours: 1)),
            endTime: bedtime.add(const Duration(hours: 2)),
          ),
        ],
      );

      final json = session.toJson();
      final restored = SleepSession.fromJson(json);
      expect(restored, equals(session));
      expect(restored.stages, hasLength(2));
      expect(restored.stages[0].stage, SleepStage.deep);
      expect(restored.stages[1].stage, SleepStage.rem);
    });

    test('provides envelope fields via mixin', () {
      final session = SleepSession(
        id: 'sleep-9',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: bedtime,
        endTime: wakeUp,
        capturedAt: now,
        timezone: 'US/Eastern',
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
        freshness: Freshness.cached,
        extensions: const {'oura': 'data'},
      );

      expect(session.duration, const Duration(hours: 8));
      expect(session.id, 'sleep-9');
      expect(session.provider, DataProvider.oura);
      expect(session.providerRecordType, 'sleep');
      expect(session.timezone, 'US/Eastern');
      expect(session.provenance?.dataOrigin, DataOrigin.native_);
      expect(session.freshness, Freshness.cached);
      expect(session.extensions, {'oura': 'data'});
    });
  });
}
