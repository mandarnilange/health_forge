import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/cache/cache_manager.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthRecord extends Mock implements HealthRecordMixin {}

MockHealthRecord _makeRecord({
  required DataProvider provider,
  required String recordType,
  required DateTime start,
  required DateTime end,
}) {
  final record = MockHealthRecord();
  when(() => record.provider).thenReturn(provider);
  when(() => record.providerRecordType).thenReturn(recordType);
  when(() => record.startTime).thenReturn(start);
  when(() => record.endTime).thenReturn(end);
  when(() => record.id).thenReturn(
    '${provider.name}_${start.millisecondsSinceEpoch}',
  );
  return record;
}

void main() {
  late InMemoryCacheManager cache;

  setUp(() {
    cache = InMemoryCacheManager();
  });

  group('InMemoryCacheManager', () {
    test('put then get returns records', () async {
      final record = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );

      await cache.put([record]);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(results, [record]);
    });

    test('get filters by metric type', () async {
      final hrRecord = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );
      final stepsRecord = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'steps',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );

      await cache.put([hrRecord, stepsRecord]);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(results, [hrRecord]);
    });

    test('get filters by time range', () async {
      final inRange = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024, 1, 5),
        end: DateTime(2024, 1, 5, 0, 5),
      );
      final outOfRange = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024, 2),
        end: DateTime(2024, 2, 1, 0, 5),
      );

      await cache.put([inRange, outOfRange]);

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 31),
        ),
      );

      expect(results, [inRange]);
    });

    test('get filters by provider', () async {
      final appleRecord = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );
      final ouraRecord = _makeRecord(
        provider: DataProvider.oura,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
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

      expect(results, [appleRecord]);
    });

    test(
      'invalidate by provider removes only that providers '
      'records',
      () async {
        final appleRecord = _makeRecord(
          provider: DataProvider.apple,
          recordType: 'heart_rate',
          start: DateTime(2024),
          end: DateTime(2024, 1, 1, 0, 5),
        );
        final ouraRecord = _makeRecord(
          provider: DataProvider.oura,
          recordType: 'heart_rate',
          start: DateTime(2024),
          end: DateTime(2024, 1, 1, 0, 5),
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

        expect(results, [ouraRecord]);
      },
    );

    test('invalidate by metric removes matching records', () async {
      final hrRecord = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );
      final stepsRecord = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'steps',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );

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
      expect(stepsResults, [stepsRecord]);
    });

    test('clear removes all records', () async {
      final record = _makeRecord(
        provider: DataProvider.apple,
        recordType: 'heart_rate',
        start: DateTime(2024),
        end: DateTime(2024, 1, 1, 0, 5),
      );

      await cache.put([record]);
      await cache.clear();

      final results = await cache.get(
        metric: MetricType.heartRate,
        range: TimeRange(
          start: DateTime(2024),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(results, isEmpty);
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

    test('lastSyncTime returns null when no metadata exists', () async {
      final result = await cache.lastSyncTime(
        DataProvider.apple,
        MetricType.heartRate,
      );

      expect(result, isNull);
    });

    test('updateSyncMetadata with cursor', () async {
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

    test('clear also clears sync metadata', () async {
      await cache.updateSyncMetadata(
        DataProvider.apple,
        MetricType.heartRate,
        lastSync: DateTime(2024),
      );

      await cache.clear();

      final result = await cache.lastSyncTime(
        DataProvider.apple,
        MetricType.heartRate,
      );
      expect(result, isNull);
    });
  });
}
