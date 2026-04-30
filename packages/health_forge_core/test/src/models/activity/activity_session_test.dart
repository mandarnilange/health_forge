import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('ActivitySession', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    ActivitySession createMinimal() => ActivitySession(
          id: 'as-1',
          provider: DataProvider.apple,
          providerRecordType: 'HKWorkout',
          startTime: now,
          endTime: later,
          capturedAt: now,
          activityType: MetricType.workout,
        );

    ActivitySession createFull() => ActivitySession(
          id: 'as-2',
          provider: DataProvider.strava,
          providerRecordType: 'activity',
          startTime: now,
          endTime: later,
          timezone: 'America/New_York',
          capturedAt: now,
          provenance: const Provenance(dataOrigin: DataOrigin.native_),
          freshness: Freshness.cached,
          extensions: const {'source': 'strava'},
          activityType: MetricType.workout,
          activityName: 'Morning Run',
          totalCalories: 350,
          activeCalories: 300,
          distanceMeters: 5000,
          averageHeartRate: 145,
          maxHeartRate: 175,
        );

    test('constructs with required fields only', () {
      final session = createMinimal();

      expect(session.id, 'as-1');
      expect(session.provider, DataProvider.apple);
      expect(session.providerRecordType, 'HKWorkout');
      expect(session.startTime, now);
      expect(session.endTime, later);
      expect(session.activityType, MetricType.workout);
      expect(session.activityName, isNull);
      expect(session.totalCalories, isNull);
      expect(session.activeCalories, isNull);
      expect(session.distanceMeters, isNull);
      expect(session.averageHeartRate, isNull);
      expect(session.maxHeartRate, isNull);
    });

    test('constructs with all fields including optionals', () {
      final session = createFull();

      expect(session.activityName, 'Morning Run');
      expect(session.totalCalories, 350.0);
      expect(session.activeCalories, 300.0);
      expect(session.distanceMeters, 5000.0);
      expect(session.averageHeartRate, 145);
      expect(session.maxHeartRate, 175);
      expect(session.timezone, 'America/New_York');
      expect(session.provenance?.dataOrigin, DataOrigin.native_);
      expect(session.freshness, Freshness.cached);
      expect(session.extensions, {'source': 'strava'});
    });

    test('two identical instances are equal', () {
      final a = createMinimal();
      final b = createMinimal();
      expect(a, equals(b));
    });

    test('copyWith works correctly', () {
      final original = createMinimal();
      final copy = original.copyWith(activityName: 'Evening Jog');

      expect(copy.activityName, 'Evening Jog');
      expect(copy.id, original.id);
      expect(copy.activityType, original.activityType);
    });

    test('JSON round-trip produces equal object', () {
      final session = createFull();
      final json = session.toJson();
      final restored = ActivitySession.fromJson(json);
      expect(restored, equals(session));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = ActivitySession.fromJson(decoded);
      expect(restored2, equals(session));
    });

    test('envelope fields accessible via mixin', () {
      final session = createFull();

      expect(session.id, isNotEmpty);
      expect(session.provider, isA<DataProvider>());
      expect(session.providerRecordType, isNotEmpty);
      expect(session.startTime, isA<DateTime>());
      expect(session.endTime, isA<DateTime>());
      expect(session.capturedAt, isA<DateTime>());
      expect(session.duration, const Duration(hours: 1));
    });

    test('default values are correct', () {
      final session = createMinimal();

      expect(session.freshness, Freshness.live);
      expect(session.extensions, isEmpty);
      expect(session.timezone, isNull);
      expect(session.provenance, isNull);
    });
  });
}
