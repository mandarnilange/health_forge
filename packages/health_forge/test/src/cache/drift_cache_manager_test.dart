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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 31),
        ),
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
        provider: DataProvider.apple,
      );

      expect(results, hasLength(1));
      expect((results.first as HeartRateSample).id, 'apple_hr');
    });

    test('invalidate by provider removes only that providers records',
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(results, hasLength(1));
      expect((results.first as HeartRateSample).id, 'oura_hr');
    });

    test('invalidate by metric removes matching records', () async {
      final hrRecord = makeHeartRate(id: 'hr_1');
      final stepsRecord = makeSteps(id: 'steps_1');

      await cache.put([hrRecord, stepsRecord]);
      await cache.invalidate(metric: MetricType.heartRate);

      final hrResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );
      final stepsResults = await cache.get(
        metric: MetricType.steps,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(hrResults, isEmpty);
      expect(stepsResults, hasLength(1));
    });

    test('invalidate with no args removes all records', () async {
      await cache.put([makeHeartRate(id: 'hr_1'), makeSteps(id: 'steps_1')]);
      await cache.invalidate();

      final hrResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
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
      final ouraHr = makeHeartRate(
        provider: DataProvider.oura,
        id: 'oura_hr',
      );

      await cache.put([appleHr, appleSteps, ouraHr]);
      await cache.invalidate(
        provider: DataProvider.apple,
        metric: MetricType.heartRate,
      );

      final stepsResults = await cache.get(
        metric: MetricType.steps,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );
      expect(stepsResults, hasLength(1));

      final ouraResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
        provider: DataProvider.oura,
      );
      expect(ouraResults, hasLength(1));

      final appleHrResults = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
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
          range: TimeRange(
            start: DateTime(2024),
            end: DateTime(2024, 2),
          ),
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
          range: TimeRange(
            start: DateTime(2024),
            end: DateTime(2024, 2),
          ),
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
            sourceDevice: DeviceInfo(
              manufacturer: 'Apple',
              model: 'iPhone 15',
            ),
          ),
        );

        await cache.put([watch, phone]);

        final results = await cache.get(
          metric: MetricType.heartRate,
          range: TimeRange(
            start: DateTime(2024),
            end: DateTime(2024, 2),
          ),
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
          range: TimeRange(
            start: DateTime(2024),
            end: DateTime(2024, 2),
          ),
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(results, hasLength(1));
    });

    test('get skips rows whose JSON fails to deserialize', () async {
      await db.into(db.cachedRecords).insert(
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
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
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 2),
        ),
      );

      expect(remaining, hasLength(1));
      expect(remaining.first.id, 'late');
    });
  });
}
