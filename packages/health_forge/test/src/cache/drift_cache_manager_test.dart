import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/cache/drift/drift_cache_manager.dart';
import 'package:health_forge/src/cache/drift/health_cache_database.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Exercise [DriftCacheManager] `_typeName` stripping of a single leading `_`.
class _PrivatePrefixRecord with HealthRecordMixin {
  _PrivatePrefixRecord()
    : id = 'priv',
      startTime = DateTime(2024),
      endTime = DateTime(2024, 1, 1, 1);

  @override
  final String id;

  @override
  final DataProvider provider = DataProvider.apple;

  @override
  final String providerRecordType = 'heart_rate';

  @override
  final String? providerRecordId = null;

  @override
  final DateTime startTime;

  @override
  final DateTime endTime;

  @override
  final String? timezone = null;

  @override
  final DateTime capturedAt = DateTime(2024);

  @override
  final Provenance? provenance = null;

  @override
  final Freshness freshness = Freshness.live;

  @override
  final Map<String, dynamic> extensions = const {};
}

void main() {
  late HealthCacheDatabase db;
  late DriftCacheManager cache;

  setUp(() {
    db = HealthCacheDatabase(NativeDatabase.memory());
    cache = DriftCacheManager(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  HeartRateSample makeHeartRate({
    DataProvider provider = DataProvider.apple,
    DateTime? start,
    DateTime? end,
    String? id,
    int bpm = 72,
    Provenance? provenance,
  }) {
    final s = start ?? DateTime(2024);
    return HeartRateSample(
      id: id ?? '${provider.name}_hr_${s.millisecondsSinceEpoch}',
      provider: provider,
      providerRecordType: 'heart_rate',
      startTime: s,
      endTime: end ?? s.add(const Duration(minutes: 5)),
      capturedAt: DateTime(2024),
      beatsPerMinute: bpm,
      provenance: provenance,
    );
  }

  StepCount makeSteps({
    DataProvider provider = DataProvider.apple,
    DateTime? start,
    DateTime? end,
    String? id,
    int count = 1000,
  }) {
    final s = start ?? DateTime(2024);
    return StepCount(
      id: id ?? '${provider.name}_steps_${s.millisecondsSinceEpoch}',
      provider: provider,
      providerRecordType: 'steps',
      startTime: s,
      endTime: end ?? s.add(const Duration(hours: 1)),
      capturedAt: DateTime(2024),
      count: count,
    );
  }

  group('DriftCacheManager', () {
    test('put then get returns records', () async {
      final record = makeHeartRate();

      await cache.put([record]);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );

      expect(results, hasLength(1));
      expect(results.first, isA<HeartRateSample>());
      final hr = results.first as HeartRateSample;
      expect(hr.id, record.id);
      expect(hr.beatsPerMinute, 72);
      expect(hr.provider, DataProvider.apple);
    });

    test('get filters by metric type', () async {
      final hrRecord = makeHeartRate();
      final stepsRecord = makeSteps();

      await cache.put([hrRecord, stepsRecord]);

      final hrResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );

      expect(hrResults, hasLength(1));
      expect((hrResults.first as HeartRateSample).id, hrRecord.id);
    });

    test('get filters by time range', () async {
      final inRange = makeHeartRate(
        start: DateTime(2024, 1, 5),
        end: DateTime(2024, 1, 5, 0, 5),
        id: 'in_range',
      );
      final outOfRange = makeHeartRate(
        start: DateTime(2024, 2),
        end: DateTime(2024, 2, 1, 0, 5),
        id: 'out_of_range',
      );

      await cache.put([inRange, outOfRange]);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 31)),
      );

      expect(results, hasLength(1));
      expect((results.first as HeartRateSample).id, 'in_range');
    });

    test('get filters by provider', () async {
      final appleRecord = makeHeartRate(id: 'apple_hr');
      final ouraRecord = makeHeartRate(
        provider: DataProvider.oura,
        id: 'oura_hr',
      );

      await cache.put([appleRecord, ouraRecord]);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
        provider: DataProvider.apple,
      );

      expect(results, hasLength(1));
      expect((results.first as HeartRateSample).id, 'apple_hr');
    });

    test(
      'invalidate by provider removes only that providers records',
      () async {
        final appleRecord = makeHeartRate(id: 'apple_hr');
        final ouraRecord = makeHeartRate(
          provider: DataProvider.oura,
          id: 'oura_hr',
        );

        await cache.put([appleRecord, ouraRecord]);
        await cache.invalidate(provider: DataProvider.apple);

        final results = await cache.get(
          metric: MetricType.heartRate,
          range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
        );

        expect(results, hasLength(1));
        expect((results.first as HeartRateSample).id, 'oura_hr');
      },
    );

    test('invalidate by metric removes matching records', () async {
      final hrRecord = makeHeartRate(id: 'hr_1');
      final stepsRecord = makeSteps(id: 'steps_1');

      await cache.put([hrRecord, stepsRecord]);
      await cache.invalidate(metric: MetricType.heartRate);

      final hrResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );
      final stepsResults = await cache.get(
        metric: MetricType.steps,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );

      expect(hrResults, isEmpty);
      expect(stepsResults, hasLength(1));
    });

    test('invalidate with no args removes all records', () async {
      await cache.put([makeHeartRate(id: 'hr_1'), makeSteps(id: 'steps_1')]);
      await cache.invalidate();

      final hrResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );
      expect(hrResults, isEmpty);
    });

    test('clear removes all records and sync metadata', () async {
      await cache.put([makeHeartRate()]);
      await cache.updateSyncMetadata(
        DataProvider.apple,
        MetricType.heartRate,
        lastSync: DateTime(2024),
      );

      await cache.clear();

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );
      final syncTime = await cache.lastSyncTime(
        DataProvider.apple,
        MetricType.heartRate,
      );

      expect(results, isEmpty);
      expect(syncTime, isNull);
    });

    test('lastSyncTime returns null when no metadata exists', () async {
      final result = await cache.lastSyncTime(
        DataProvider.apple,
        MetricType.heartRate,
      );

      expect(result, isNull);
    });

    test('updateSyncMetadata and lastSyncTime round-trip', () async {
      final syncTime = DateTime(2024, 3, 15);
      await cache.updateSyncMetadata(
        DataProvider.apple,
        MetricType.heartRate,
        lastSync: syncTime,
      );

      final result = await cache.lastSyncTime(
        DataProvider.apple,
        MetricType.heartRate,
      );

      expect(result, syncTime);
    });

    test('updateSyncMetadata with cursor round-trip', () async {
      await cache.updateSyncMetadata(
        DataProvider.strava,
        MetricType.workout,
        cursor: 'abc123',
      );

      final cursor = await cache.getSyncCursor(
        DataProvider.strava,
        MetricType.workout,
      );

      expect(cursor, 'abc123');
    });

    test('updateSyncMetadata overwrites previous values', () async {
      await cache.updateSyncMetadata(
        DataProvider.oura,
        MetricType.sleepSession,
        lastSync: DateTime(2024),
        cursor: 'first',
      );

      final newSync = DateTime(2024, 6);
      await cache.updateSyncMetadata(
        DataProvider.oura,
        MetricType.sleepSession,
        lastSync: newSync,
        cursor: 'second',
      );

      final syncTime = await cache.lastSyncTime(
        DataProvider.oura,
        MetricType.sleepSession,
      );
      final cursor = await cache.getSyncCursor(
        DataProvider.oura,
        MetricType.sleepSession,
      );

      expect(syncTime, newSync);
      expect(cursor, 'second');
    });

    test('invalidate by provider and metric together', () async {
      final appleHr = makeHeartRate(id: 'apple_hr');
      final appleSteps = makeSteps(id: 'apple_steps');
      final ouraHr = makeHeartRate(provider: DataProvider.oura, id: 'oura_hr');

      await cache.put([appleHr, appleSteps, ouraHr]);
      await cache.invalidate(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
      );

      final stepsResults = await cache.get(
        metric: MetricType.steps,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );
      expect(stepsResults, hasLength(1));

      final ouraResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
        provider: DataProvider.oura,
      );
      expect(ouraResults, hasLength(1));

      final appleHrResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
        provider: DataProvider.apple,
      );
      expect(appleHrResults, isEmpty);
    });

    group('natural key deduplication', () {
      test('same provider+metric+time replaces existing record', () async {
        final time = DateTime(2024, 1, 15, 10);
        final first = makeHeartRate(
          id: 'uuid-1',
          start: time,
          end: time.add(const Duration(minutes: 5)),
          bpm: 60,
        );
        final second = makeHeartRate(
          id: 'uuid-2', // different UUID
          start: time, // same time
          end: time.add(const Duration(minutes: 5)),
          bpm: 90,
        );

        await cache.put([first]);
        await cache.put([second]);

        final results = await cache.get(
          metric: MetricType.heartRate,
          range: TimeRange(start: DateTime(2024), end: DateTime(2024, 2)),
        );

        // Should have 1 record (deduped), with updated value
        expect(results, hasLength(1));
        expect((results.first as HeartRateSample).beatsPerMinute, 90);
      });

      test('different providers with same time are kept separate', () async {
        final time = DateTime(2024, 1, 15, 10);
        final appleHr = makeHeartRate(
          id: 'apple-uuid',
          start: time,
          end: time.add(const Duration(minutes: 5)),
        );
        final ouraHr = makeHeartRate(
          id: 'oura-uuid',
          provider: DataProvider.oura,
          start: time,
          end: time.add(const Duration(minutes: 5)),
          bpm: 74,
        );

        await cache.put([appleHr, ouraHr]);

        final results = await cache.get(
          metric: MetricType.heartRate,
          range: TimeRange(start: DateTime(2024), end: DateTime(2024, 2)),
        );

        expect(results, hasLength(2));
      });

      test('different devices with same time are kept separate', () async {
        final time = DateTime(2024, 1, 15, 10);
        final watch = makeHeartRate(
          id: 'watch-uuid',
          start: time,
          end: time.add(const Duration(minutes: 5)),
          provenance: const Provenance(
            dataOrigin: DataOrigin.native_,
            sourceDevice: DeviceInfo(
              manufacturer: 'Apple',
              model: 'Watch Series 9',
            ),
          ),
        );
        final phone = makeHeartRate(
          id: 'phone-uuid',
          start: time,
          end: time.add(const Duration(minutes: 5)),
          bpm: 74,
          provenance: const Provenance(
            dataOrigin: DataOrigin.native_,
            sourceDevice: DeviceInfo(manufacturer: 'Apple', model: 'iPhone 15'),
          ),
        );

        await cache.put([watch, phone]);

        final results = await cache.get(
          metric: MetricType.heartRate,
          range: TimeRange(start: DateTime(2024), end: DateTime(2024, 2)),
        );

        expect(results, hasLength(2));
      });

      test('same device re-synced updates existing record', () async {
        final time = DateTime(2024, 1, 15, 10);
        const prov = Provenance(
          dataOrigin: DataOrigin.native_,
          sourceDevice: DeviceInfo(
            manufacturer: 'Apple',
            model: 'Watch Series 9',
          ),
        );

        final first = makeHeartRate(
          id: 'first-sync',
          start: time,
          end: time.add(const Duration(minutes: 5)),
          provenance: prov,
        );
        final second = makeHeartRate(
          id: 'second-sync',
          start: time,
          end: time.add(const Duration(minutes: 5)),
          bpm: 75,
          provenance: prov,
        );

        await cache.put([first]);
        await cache.put([second]);

        final results = await cache.get(
          metric: MetricType.heartRate,
          range: TimeRange(start: DateTime(2024), end: DateTime(2024, 2)),
        );

        expect(results, hasLength(1));
        expect((results.first as HeartRateSample).beatsPerMinute, 75);
      });
    });

    test('caches records with platform-specific providerRecordType', () async {
      final record = CaloriesBurned(
        id: 'cal-1',
        provider: DataProvider.apple,
        providerRecordType: 'ACTIVE_ENERGY_BURNED',
        startTime: DateTime(2024),
        endTime: DateTime(2024, 1, 1, 1),
        capturedAt: DateTime(2024),
        totalCalories: 250,
      );

      await cache.put([record]);

      final results = await cache.get(
        metric: MetricType.calories,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );

      expect(results, hasLength(1));
      expect(results.first, isA<CaloriesBurned>());
      expect((results.first as CaloriesBurned).totalCalories, 250);
    });

    test('batch put stores many records efficiently', () async {
      final records = List.generate(
        100,
        (i) => makeHeartRate(
          id: 'hr_$i',
          start: DateTime(2024, 1, 1, 0, i),
          end: DateTime(2024, 1, 1, 0, i, 30),
          bpm: 60 + i,
        ),
      );

      await cache.put(records);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );

      expect(results, hasLength(100));
    });

    test('close completes without error', () async {
      await expectLater(cache.close(), completes);
    });

    test('put ignores mixin types with private runtimeType prefix', () async {
      await cache.put([_PrivatePrefixRecord(), makeHeartRate()]);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );

      expect(results, hasLength(1));
    });

    test('get skips rows whose JSON fails to deserialize', () async {
      await db
          .into(db.cachedRecords)
          .insert(
            CachedRecordsCompanion.insert(
              recordId: 'bad-row',
              provider: DataProvider.apple.name,
              metricType: MetricType.heartRate.name,
              recordType: 'HeartRateSample',
              startTime: DateTime(2024),
              endTime: DateTime(2024, 1, 1, 1),
              cachedAt: DateTime(2024),
              jsonPayload: jsonEncode({
                '_recordTypeName': 'HeartRateSample',
                'invalid': true,
              }),
            ),
          );

      await cache.put([makeHeartRate(id: 'good-row')]);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 1, 2)),
      );

      expect(results, hasLength(1));
      expect(results.first.id, 'good-row');
    });

    test('invalidate by time range only removes overlapping rows', () async {
      final early = makeHeartRate(
        id: 'early',
        start: DateTime(2024, 1, 1, 6),
        end: DateTime(2024, 1, 1, 6, 30),
      );
      final late = makeHeartRate(
        id: 'late',
        start: DateTime(2024, 1, 10),
        end: DateTime(2024, 1, 10, 0, 30),
      );
      await cache.put([early, late]);

      await cache.invalidate(
        range: TimeRange(
          start: DateTime(2024, 1, 1, 5),
          end: DateTime(2024, 1, 1, 7),
        ),
      );

      final remaining = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(start: DateTime(2024), end: DateTime(2024, 2)),
      );

      expect(remaining, hasLength(1));
      expect(remaining.first.id, 'late');
    });
  });

  group('DriftCacheManager full round-trip per record type', () {
    final start = DateTime.utc(2024, 1, 1, 22, 15, 30, 123);
    final end = DateTime.utc(2024, 1, 2, 6, 45, 10, 456);
    final capturedAt = DateTime.utc(2024, 1, 2, 7, 0, 0, 789);
    final range = TimeRange(
      start: DateTime.utc(2024),
      end: DateTime.utc(2024, 1, 3),
    );

    Provenance provenanceFor(String type) => Provenance(
      dataOrigin: DataOrigin.native_,
      sourceDevice: DeviceInfo(
        model: '$type Model X',
        manufacturer: 'Acme',
        firmware: '1.2.3',
      ),
      sourceApp: 'com.example.$type',
      rawPayloadRef: 'raw/$type/42',
    );

    Map<String, dynamic> extensionsFor(String type) => <String, dynamic>{
      'vendorType': type,
      'vendorScore': 87,
      'vendorRatio': 0.25,
      'vendorFlag': true,
      'vendorNull': null,
      'vendorNested': <String, dynamic>{
        'list': <dynamic>[1, 2.5, 'three', false],
        'map': <String, dynamic>{'k': 'v'},
      },
    };

    final cases =
        <({String type, HealthRecordMixin record, MetricType metric})>[
          (
            type: 'HeartRateSample',
            metric: MetricType.heartRate,
            record: HeartRateSample(
              id: 'hr-full',
              provider: DataProvider.apple,
              providerRecordType: 'HKQuantityTypeIdentifierHeartRate',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              beatsPerMinute: 64,
              providerRecordId: 'apple-hr-1',
              timezone: 'Europe/London',
              provenance: provenanceFor('HeartRateSample'),
              context: 'resting',
              freshness: Freshness.cached,
              extensions: extensionsFor('HeartRateSample'),
            ),
          ),
          (
            type: 'RestingHeartRate',
            metric: MetricType.restingHeartRate,
            record: RestingHeartRate(
              id: 'rhr-full',
              provider: DataProvider.oura,
              providerRecordType: 'resting_heart_rate',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              beatsPerMinute: 52,
              providerRecordId: 'oura-rhr-1',
              timezone: 'America/New_York',
              provenance: provenanceFor('RestingHeartRate'),
              freshness: Freshness.cached,
              extensions: extensionsFor('RestingHeartRate'),
            ),
          ),
          (
            type: 'HeartRateVariability',
            metric: MetricType.hrv,
            record: HeartRateVariability(
              id: 'hrv-full',
              provider: DataProvider.garmin,
              providerRecordType: 'hrv',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              sdnnMilliseconds: 48.5,
              providerRecordId: 'garmin-hrv-1',
              timezone: 'Asia/Kolkata',
              provenance: provenanceFor('HeartRateVariability'),
              rmssdMilliseconds: 41.25,
              freshness: Freshness.cached,
              extensions: extensionsFor('HeartRateVariability'),
            ),
          ),
          (
            type: 'StepCount',
            metric: MetricType.steps,
            record: StepCount(
              id: 'steps-full',
              provider: DataProvider.apple,
              providerRecordType: 'HKQuantityTypeIdentifierStepCount',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              count: 12345,
              providerRecordId: 'apple-steps-1',
              timezone: 'Europe/Berlin',
              provenance: provenanceFor('StepCount'),
              source: 'watch',
              freshness: Freshness.cached,
              extensions: extensionsFor('StepCount'),
            ),
          ),
          (
            type: 'CaloriesBurned',
            metric: MetricType.calories,
            record: CaloriesBurned(
              id: 'cal-full',
              provider: DataProvider.apple,
              providerRecordType: 'ACTIVE_ENERGY_BURNED',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              totalCalories: 2150.5,
              providerRecordId: 'apple-cal-1',
              timezone: 'Europe/Paris',
              provenance: provenanceFor('CaloriesBurned'),
              activeCalories: 620.75,
              freshness: Freshness.cached,
              extensions: extensionsFor('CaloriesBurned'),
            ),
          ),
          (
            type: 'DistanceSample',
            metric: MetricType.distance,
            record: DistanceSample(
              id: 'dist-full',
              provider: DataProvider.garmin,
              providerRecordType: 'distance',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              distanceMeters: 8421.3,
              providerRecordId: 'garmin-dist-1',
              timezone: 'Europe/Madrid',
              provenance: provenanceFor('DistanceSample'),
              freshness: Freshness.cached,
              extensions: extensionsFor('DistanceSample'),
            ),
          ),
          (
            type: 'ElevationGain',
            metric: MetricType.elevation,
            record: ElevationGain(
              id: 'elev-full',
              provider: DataProvider.garmin,
              providerRecordType: 'elevation_gain',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              elevationMeters: 312.4,
              providerRecordId: 'garmin-elev-1',
              timezone: 'America/Denver',
              provenance: provenanceFor('ElevationGain'),
              freshness: Freshness.cached,
              extensions: extensionsFor('ElevationGain'),
            ),
          ),
          (
            type: 'ActivitySession',
            metric: MetricType.workout,
            record: ActivitySession(
              id: 'activity-full',
              provider: DataProvider.strava,
              providerRecordType: 'Run',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              activityType: MetricType.workout,
              providerRecordId: 'strava-activity-1',
              timezone: 'America/Los_Angeles',
              provenance: provenanceFor('ActivitySession'),
              activityName: 'Morning Run',
              totalCalories: 780.5,
              activeCalories: 650.25,
              distanceMeters: 10012.7,
              averageHeartRate: 148,
              maxHeartRate: 182,
              freshness: Freshness.cached,
              extensions: StravaWorkoutExtension(
                sufferScore: 97,
                segmentEfforts: [
                  <String, dynamic>{
                    'name': 'Hill Climb',
                    'elapsed_time': 312,
                    'pr_rank': 1,
                  },
                  <String, dynamic>{
                    'name': 'Sprint',
                    'elapsed_time': 45.5,
                    'pr_rank': null,
                  },
                ],
                routePolyline: 'a~l~Fjk~uOwHJy@P',
              ).toJson(),
            ),
          ),
          (
            type: 'WorkoutRoute',
            metric: MetricType.workout,
            record: WorkoutRoute(
              id: 'route-full',
              provider: DataProvider.strava,
              providerRecordType: 'route',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              points: [
                RoutePoint(
                  latitude: 51.5007,
                  longitude: -0.1246,
                  altitudeMeters: 12.5,
                  timestamp: start,
                ),
                RoutePoint(
                  latitude: 51.5014,
                  longitude: -0.1419,
                  altitudeMeters: 18.25,
                  timestamp: start.add(const Duration(minutes: 7)),
                ),
                RoutePoint(
                  latitude: 51.5033,
                  longitude: -0.1195,
                  altitudeMeters: 9.75,
                  timestamp: end,
                ),
              ],
              providerRecordId: 'strava-route-1',
              timezone: 'Europe/London',
              provenance: provenanceFor('WorkoutRoute'),
              totalDistanceMeters: 4210.5,
              elevationGainMeters: 38.2,
              freshness: Freshness.cached,
              extensions: extensionsFor('WorkoutRoute'),
            ),
          ),
          (
            type: 'SleepSession',
            metric: MetricType.sleepSession,
            record: SleepSession(
              id: 'sleep-full',
              provider: DataProvider.oura,
              providerRecordType: 'long_sleep',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              providerRecordId: 'oura-sleep-1',
              timezone: 'Europe/Amsterdam',
              provenance: provenanceFor('SleepSession'),
              freshness: Freshness.cached,
              extensions: OuraSleepExtension(
                readinessScore: 82,
                temperatureDeviation: -0.35,
                readinessContributorSleep: 91,
              ).toJson(),
              totalSleepMinutes: 450,
              remMinutes: 95,
              deepMinutes: 80,
              lightMinutes: 245,
              awakeMinutes: 30,
              efficiency: 93,
              stages: [
                SleepStageSegment(
                  stage: SleepStage.awake,
                  startTime: start,
                  endTime: start.add(const Duration(minutes: 10)),
                ),
                SleepStageSegment(
                  stage: SleepStage.light,
                  startTime: start.add(const Duration(minutes: 10)),
                  endTime: start.add(const Duration(minutes: 70)),
                ),
                SleepStageSegment(
                  stage: SleepStage.deep,
                  startTime: start.add(const Duration(minutes: 70)),
                  endTime: start.add(const Duration(minutes: 150)),
                ),
                SleepStageSegment(
                  stage: SleepStage.rem,
                  startTime: start.add(const Duration(minutes: 150)),
                  endTime: start.add(const Duration(minutes: 245)),
                ),
                SleepStageSegment(
                  stage: SleepStage.unknown,
                  startTime: start.add(const Duration(minutes: 245)),
                  endTime: end,
                ),
              ],
            ),
          ),
          (
            type: 'SleepScore',
            metric: MetricType.sleepScore,
            record: SleepScore(
              id: 'sleep-score-full',
              provider: DataProvider.garmin,
              providerRecordType: 'sleep_score',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              score: 84,
              providerRecordId: 'garmin-sleep-score-1',
              qualityRating: 'good',
              timezone: 'Australia/Sydney',
              provenance: provenanceFor('SleepScore'),
              freshness: Freshness.cached,
              extensions: GarminSleepExtension(
                bodyBatteryChange: 42,
                stressQualifier: 'calm',
              ).toJson(),
            ),
          ),
          (
            type: 'ReadinessScore',
            metric: MetricType.readiness,
            record: ReadinessScore(
              id: 'readiness-full',
              provider: DataProvider.oura,
              providerRecordType: 'daily_readiness',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              score: 78,
              providerRecordId: 'oura-readiness-1',
              contributors: const {
                'activity_balance': 80,
                'body_temperature': 95,
                'hrv_balance': 70,
              },
              timezone: 'Europe/Oslo',
              provenance: provenanceFor('ReadinessScore'),
              freshness: Freshness.cached,
              extensions: extensionsFor('ReadinessScore'),
            ),
          ),
          (
            type: 'StressScore',
            metric: MetricType.stress,
            record: StressScore(
              id: 'stress-full',
              provider: DataProvider.garmin,
              providerRecordType: 'stress',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              score: 33,
              providerRecordId: 'garmin-stress-1',
              level: 'low',
              timezone: 'Asia/Tokyo',
              provenance: provenanceFor('StressScore'),
              freshness: Freshness.cached,
              extensions: extensionsFor('StressScore'),
            ),
          ),
          (
            type: 'RecoveryMetric',
            metric: MetricType.recovery,
            record: RecoveryMetric(
              id: 'recovery-full',
              provider: DataProvider.oura,
              providerRecordType: 'recovery',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              score: 71,
              providerRecordId: 'oura-recovery-1',
              recoveryLevel: 'moderate',
              timezone: 'Europe/Rome',
              provenance: provenanceFor('RecoveryMetric'),
              freshness: Freshness.cached,
              extensions: extensionsFor('RecoveryMetric'),
            ),
          ),
          (
            type: 'BloodOxygenSample',
            metric: MetricType.bloodOxygen,
            record: BloodOxygenSample(
              id: 'spo2-full',
              provider: DataProvider.apple,
              providerRecordType: 'HKQuantityTypeIdentifierOxygenSaturation',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              percentage: 97.5,
              providerRecordId: 'apple-spo2-1',
              supplementalOxygen: false,
              timezone: 'Europe/Dublin',
              provenance: provenanceFor('BloodOxygenSample'),
              freshness: Freshness.cached,
              extensions: extensionsFor('BloodOxygenSample'),
            ),
          ),
          (
            type: 'RespiratoryRate',
            metric: MetricType.respiratoryRate,
            record: RespiratoryRate(
              id: 'resp-full',
              provider: DataProvider.apple,
              providerRecordType: 'HKQuantityTypeIdentifierRespiratoryRate',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              breathsPerMinute: 14.5,
              providerRecordId: 'apple-resp-1',
              timezone: 'Europe/Lisbon',
              provenance: provenanceFor('RespiratoryRate'),
              freshness: Freshness.cached,
              extensions: extensionsFor('RespiratoryRate'),
            ),
          ),
          (
            type: 'Weight',
            metric: MetricType.weight,
            record: Weight(
              id: 'weight-full',
              provider: DataProvider.apple,
              providerRecordType: 'HKQuantityTypeIdentifierBodyMass',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              kilograms: 72.35,
              providerRecordId: 'apple-weight-1',
              bmi: 22.8,
              timezone: 'Europe/Vienna',
              provenance: provenanceFor('Weight'),
              freshness: Freshness.cached,
              extensions: extensionsFor('Weight'),
            ),
          ),
          (
            type: 'BodyFat',
            metric: MetricType.bodyFat,
            record: BodyFat(
              id: 'bodyfat-full',
              provider: DataProvider.apple,
              providerRecordType: 'HKQuantityTypeIdentifierBodyFatPercentage',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              percentage: 18.4,
              providerRecordId: 'apple-bodyfat-1',
              timezone: 'Europe/Prague',
              provenance: provenanceFor('BodyFat'),
              freshness: Freshness.cached,
              extensions: extensionsFor('BodyFat'),
            ),
          ),
          (
            type: 'BloodPressure',
            metric: MetricType.bloodPressure,
            record: BloodPressure(
              id: 'bp-full',
              provider: DataProvider.apple,
              providerRecordType: 'HKCorrelationTypeIdentifierBloodPressure',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              systolicMmHg: 118,
              diastolicMmHg: 76,
              providerRecordId: 'apple-bp-1',
              pulseBpm: 62,
              timezone: 'Europe/Warsaw',
              provenance: provenanceFor('BloodPressure'),
              freshness: Freshness.cached,
              extensions: extensionsFor('BloodPressure'),
            ),
          ),
          (
            type: 'BloodGlucose',
            metric: MetricType.bloodGlucose,
            record: BloodGlucose(
              id: 'glucose-full',
              provider: DataProvider.apple,
              providerRecordType: 'HKQuantityTypeIdentifierBloodGlucose',
              startTime: start,
              endTime: end,
              capturedAt: capturedAt,
              milligramsPerDeciliter: 95.5,
              providerRecordId: 'apple-glucose-1',
              mealContext: 'fasting',
              timezone: 'Europe/Zurich',
              provenance: provenanceFor('BloodGlucose'),
              freshness: Freshness.cached,
              extensions: extensionsFor('BloodGlucose'),
            ),
          ),
        ];

    for (final c in cases) {
      test(
        '${c.type} round-trips through put/get with full equality',
        () async {
          await cache.put([c.record]);

          final rows = await db.select(db.cachedRecords).get();
          expect(rows, hasLength(1), reason: 'put() skipped ${c.type}');
          expect(rows.single.recordType, c.type);
          expect(rows.single.metricType, c.metric.name);

          final results = await cache.get(metric: c.metric, range: range);

          expect(results, hasLength(1));
          expect(results.single, isA<HealthRecordMixin>());
          expect(results.single.runtimeType, c.record.runtimeType);
          expect(results.single, c.record);
        },
      );
    }

    test('covers every record type with a built-in deserializer', () {
      expect(
        cases.map((c) => c.type).toSet(),
        hasLength(20),
        reason: 'one case per _defaultDeserializers entry',
      );
    });
  });
}
