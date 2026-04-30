import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/health_forge.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthProvider extends Mock implements HealthProvider {}

class FakeTimeRange extends Fake implements TimeRange {}

void main() {
  late MockHealthProvider stravaProvider;
  late MockHealthProvider appleProvider;
  late MockHealthProvider ghcProvider;
  late HealthForgeClient client;
  final now = DateTime(2026, 3, 18, 12);
  final range = TimeRange(
    start: now.subtract(const Duration(hours: 2)),
    end: now,
  );

  setUpAll(() {
    registerFallbackValue(MetricType.heartRate);
    registerFallbackValue(FakeTimeRange());
  });

  setUp(() {
    stravaProvider = MockHealthProvider();
    appleProvider = MockHealthProvider();
    ghcProvider = MockHealthProvider();

    when(() => stravaProvider.providerType).thenReturn(DataProvider.strava);
    when(() => stravaProvider.displayName).thenReturn('Strava');
    when(() => stravaProvider.capabilities).thenReturn(
      const ProviderCapabilities(
        supportedMetrics: {
          MetricType.workout: AccessMode.read,
          MetricType.heartRate: AccessMode.read,
          MetricType.calories: AccessMode.read,
        },
        syncModel: SyncModel.fullWindow,
      ),
    );

    when(() => appleProvider.providerType).thenReturn(DataProvider.apple);
    when(() => appleProvider.displayName).thenReturn('Apple HealthKit');
    when(() => appleProvider.capabilities).thenReturn(
      const ProviderCapabilities(
        supportedMetrics: {
          MetricType.workout: AccessMode.read,
          MetricType.heartRate: AccessMode.read,
          MetricType.calories: AccessMode.read,
        },
        syncModel: SyncModel.fullWindow,
      ),
    );

    when(() => ghcProvider.providerType)
        .thenReturn(DataProvider.googleHealthConnect);
    when(() => ghcProvider.displayName).thenReturn('Google Health Connect');
    when(() => ghcProvider.capabilities).thenReturn(
      const ProviderCapabilities(
        supportedMetrics: {
          MetricType.workout: AccessMode.read,
          MetricType.heartRate: AccessMode.read,
          MetricType.calories: AccessMode.read,
        },
        syncModel: SyncModel.fullWindow,
      ),
    );

    client = HealthForgeClient();
  });

  group('Strava + Apple overlapping workouts', () {
    test('priority strategy keeps Apple record over Strava', () async {
      // Same 30-minute run tracked by both providers at the same time.
      final stravaWorkout = ActivitySession(
        id: 'strava-run-1',
        provider: DataProvider.strava,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now.subtract(const Duration(minutes: 30)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Morning Run',
        distanceMeters: 5000,
        totalCalories: 320,
      );
      final appleWorkout = ActivitySession(
        id: 'apple-run-1',
        provider: DataProvider.apple,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now.subtract(const Duration(minutes: 30)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Outdoor Run',
        distanceMeters: 5012,
        totalCalories: 315,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaWorkout]);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleWorkout]);

      client
        ..use(stravaProvider)
        ..use(appleProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [
          DataProvider.apple,
          DataProvider.googleHealthConnect,
          DataProvider.oura,
          DataProvider.strava,
          DataProvider.garmin,
        ],
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.workout)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      expect(result.mergeResult, isNotNull);
      expect(result.records, hasLength(1));
      expect(result.records.first.provider, DataProvider.apple);
      expect(result.mergeResult!.conflicts, hasLength(1));
      expect(
        result.mergeResult!.conflicts.first.strategy,
        ConflictStrategy.priorityBased,
      );
    });

    test('keepAll strategy retains both Strava and Apple workouts', () async {
      final stravaWorkout = ActivitySession(
        id: 'strava-run-2',
        provider: DataProvider.strava,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now.subtract(const Duration(minutes: 30)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Morning Run',
        distanceMeters: 5000,
      );
      final appleWorkout = ActivitySession(
        id: 'apple-run-2',
        provider: DataProvider.apple,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now.subtract(const Duration(minutes: 30)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Outdoor Run',
        distanceMeters: 5012,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaWorkout]);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleWorkout]);

      client
        ..use(stravaProvider)
        ..use(appleProvider);

      const mergeConfig = MergeConfig(
        defaultStrategy: ConflictStrategy.keepAll,
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.workout)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      expect(result.mergeResult, isNotNull);
      expect(result.records, hasLength(2));

      final providers = result.records.map((r) => r.provider).toSet();
      expect(providers, containsAll([DataProvider.strava, DataProvider.apple]));
    });
  });

  group('Strava + Apple overlapping heart rate', () {
    test('priority strategy keeps Apple heart rate over Strava', () async {
      final stravaHr = HeartRateSample(
        id: 'strava-hr-1',
        provider: DataProvider.strava,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.subtract(const Duration(minutes: 29)),
        capturedAt: now,
        beatsPerMinute: 145,
      );
      final appleHr = HeartRateSample(
        id: 'apple-hr-1',
        provider: DataProvider.apple,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.subtract(const Duration(minutes: 29)),
        capturedAt: now,
        beatsPerMinute: 142,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaHr]);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleHr]);

      client
        ..use(stravaProvider)
        ..use(appleProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [
          DataProvider.apple,
          DataProvider.strava,
        ],
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.heartRate)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      expect(result.records, hasLength(1));
      expect(result.records.first.provider, DataProvider.apple);
      expect(
        (result.records.first as HeartRateSample).beatsPerMinute,
        142,
      );
    });

    test('average strategy averages bpm from Strava and Apple', () async {
      final stravaHr = HeartRateSample(
        id: 'strava-hr-avg-1',
        provider: DataProvider.strava,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.subtract(const Duration(minutes: 29)),
        capturedAt: now,
        beatsPerMinute: 150,
      );
      final appleHr = HeartRateSample(
        id: 'apple-hr-avg-1',
        provider: DataProvider.apple,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.subtract(const Duration(minutes: 29)),
        capturedAt: now,
        beatsPerMinute: 140,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaHr]);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleHr]);

      client
        ..use(stravaProvider)
        ..use(appleProvider);

      const mergeConfig = MergeConfig(
        defaultStrategy: ConflictStrategy.average,
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.heartRate)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      expect(result.records, hasLength(1));
      // (150 + 140) ~/ 2 = 145
      expect(
        (result.records.first as HeartRateSample).beatsPerMinute,
        145,
      );
    });

    test('keepAll strategy retains both heart rate samples', () async {
      final stravaHr = HeartRateSample(
        id: 'strava-hr-keep-1',
        provider: DataProvider.strava,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.subtract(const Duration(minutes: 29)),
        capturedAt: now,
        beatsPerMinute: 150,
      );
      final appleHr = HeartRateSample(
        id: 'apple-hr-keep-1',
        provider: DataProvider.apple,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.subtract(const Duration(minutes: 29)),
        capturedAt: now,
        beatsPerMinute: 140,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaHr]);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleHr]);

      client
        ..use(stravaProvider)
        ..use(appleProvider);

      const mergeConfig = MergeConfig(
        defaultStrategy: ConflictStrategy.keepAll,
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.heartRate)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      expect(result.records, hasLength(2));

      final bpmValues = result.records
          .cast<HeartRateSample>()
          .map((r) => r.beatsPerMinute)
          .toSet();
      expect(bpmValues, containsAll([150, 140]));
    });
  });

  group('Strava + GHC cross-provider merge', () {
    test('priority strategy keeps GHC workout over Strava', () async {
      final stravaWorkout = ActivitySession(
        id: 'strava-ghc-run-1',
        provider: DataProvider.strava,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 90)),
        endTime: now.subtract(const Duration(minutes: 45)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Afternoon Ride',
        distanceMeters: 15000,
      );
      final ghcWorkout = ActivitySession(
        id: 'ghc-run-1',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 90)),
        endTime: now.subtract(const Duration(minutes: 45)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Cycling',
        distanceMeters: 14800,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaWorkout]);
      when(
        () => ghcProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ghcWorkout]);

      client
        ..use(stravaProvider)
        ..use(ghcProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [
          DataProvider.apple,
          DataProvider.googleHealthConnect,
          DataProvider.oura,
          DataProvider.strava,
          DataProvider.garmin,
        ],
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.workout)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      expect(result.records, hasLength(1));
      expect(
        result.records.first.provider,
        DataProvider.googleHealthConnect,
      );
    });

    test('priority strategy keeps GHC calories over Strava', () async {
      final stravaCal = CaloriesBurned(
        id: 'strava-cal-1',
        provider: DataProvider.strava,
        providerRecordType: 'calories',
        startTime: now.subtract(const Duration(minutes: 90)),
        endTime: now.subtract(const Duration(minutes: 45)),
        capturedAt: now,
        totalCalories: 520,
      );
      final ghcCal = CaloriesBurned(
        id: 'ghc-cal-1',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'calories',
        startTime: now.subtract(const Duration(minutes: 90)),
        endTime: now.subtract(const Duration(minutes: 45)),
        capturedAt: now,
        totalCalories: 495,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaCal]);
      when(
        () => ghcProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ghcCal]);

      client
        ..use(stravaProvider)
        ..use(ghcProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [
          DataProvider.apple,
          DataProvider.googleHealthConnect,
          DataProvider.oura,
          DataProvider.strava,
          DataProvider.garmin,
        ],
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.calories)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      expect(result.records, hasLength(1));
      expect(
        result.records.first.provider,
        DataProvider.googleHealthConnect,
      );
      expect(
        (result.records.first as CaloriesBurned).totalCalories,
        495,
      );
    });

    test('per-metric strategy uses keepAll for workouts but priority for HR',
        () async {
      final stravaWorkout = ActivitySession(
        id: 'strava-mixed-run',
        provider: DataProvider.strava,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 90)),
        endTime: now.subtract(const Duration(minutes: 45)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Ride',
        distanceMeters: 15000,
      );
      final ghcWorkout = ActivitySession(
        id: 'ghc-mixed-run',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 90)),
        endTime: now.subtract(const Duration(minutes: 45)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Cycling',
        distanceMeters: 14800,
      );
      final stravaHr = HeartRateSample(
        id: 'strava-mixed-hr',
        provider: DataProvider.strava,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now.subtract(const Duration(minutes: 59)),
        capturedAt: now,
        beatsPerMinute: 155,
      );
      final ghcHr = HeartRateSample(
        id: 'ghc-mixed-hr',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now.subtract(const Duration(minutes: 59)),
        capturedAt: now,
        beatsPerMinute: 152,
      );

      // Return all records regardless of metric type — the MergeEngine
      // groups by MetricType internally, so returning everything is safe.
      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaWorkout, stravaHr]);
      when(
        () => ghcProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ghcWorkout, ghcHr]);

      client
        ..use(stravaProvider)
        ..use(ghcProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [
          DataProvider.googleHealthConnect,
          DataProvider.strava,
        ],
        perMetricStrategy: {
          MetricType.workout: ConflictStrategy.keepAll,
        },
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.workout)
        ..forMetric(MetricType.heartRate)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      // Workouts: keepAll → both kept
      final workouts = result.records.whereType<ActivitySession>().toList();
      expect(workouts, hasLength(2));

      // Heart rate: priority → only GHC kept
      final hrs = result.records.whereType<HeartRateSample>().toList();
      expect(hrs, hasLength(1));
      expect(hrs.first.provider, DataProvider.googleHealthConnect);
    });
  });

  group('Multi-provider no overlap', () {
    test('non-overlapping Strava and Apple records are all kept', () async {
      // Records >5 min apart so DuplicateDetector does not group them.
      final stravaHr = HeartRateSample(
        id: 'strava-no-overlap-1',
        provider: DataProvider.strava,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 90)),
        endTime: now.subtract(const Duration(minutes: 89)),
        capturedAt: now,
        beatsPerMinute: 130,
      );
      final appleHr = HeartRateSample(
        id: 'apple-no-overlap-1',
        provider: DataProvider.apple,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 10)),
        endTime: now.subtract(const Duration(minutes: 9)),
        capturedAt: now,
        beatsPerMinute: 68,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaHr]);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleHr]);

      client
        ..use(stravaProvider)
        ..use(appleProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [DataProvider.apple, DataProvider.strava],
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.heartRate)
        ..inRange(range)
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      // No overlaps detected → both records kept, no conflicts
      expect(result.records, hasLength(2));
      expect(result.mergeResult!.conflicts, isEmpty);
    });

    test('non-overlapping Strava and GHC workouts are all kept', () async {
      // Morning workout on Strava, evening workout on GHC — far apart.
      final stravaWorkout = ActivitySession(
        id: 'strava-morning',
        provider: DataProvider.strava,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(hours: 10)),
        endTime: now.subtract(const Duration(hours: 9)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Morning Run',
        distanceMeters: 5000,
      );
      final ghcWorkout = ActivitySession(
        id: 'ghc-evening',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'workout',
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now.subtract(const Duration(minutes: 30)),
        capturedAt: now,
        activityType: MetricType.workout,
        activityName: 'Evening Walk',
        distanceMeters: 2000,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaWorkout]);
      when(
        () => ghcProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ghcWorkout]);

      client
        ..use(stravaProvider)
        ..use(ghcProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [
          DataProvider.googleHealthConnect,
          DataProvider.strava,
        ],
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.workout)
        ..inRange(
          TimeRange(
            start: now.subtract(const Duration(hours: 12)),
            end: now,
          ),
        )
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      expect(result.records, hasLength(2));
      expect(result.mergeResult!.conflicts, isEmpty);
    });

    test('three providers with no overlaps keeps all records', () async {
      // Each provider has a heart rate sample at a very different time.
      final stravaHr = HeartRateSample(
        id: 'strava-tri-1',
        provider: DataProvider.strava,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 100)),
        endTime: now.subtract(const Duration(minutes: 99)),
        capturedAt: now,
        beatsPerMinute: 155,
      );
      final appleHr = HeartRateSample(
        id: 'apple-tri-1',
        provider: DataProvider.apple,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 50)),
        endTime: now.subtract(const Duration(minutes: 49)),
        capturedAt: now,
        beatsPerMinute: 72,
      );
      final ghcHr = HeartRateSample(
        id: 'ghc-tri-1',
        provider: DataProvider.googleHealthConnect,
        providerRecordType: 'heart_rate',
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now.subtract(const Duration(minutes: 4)),
        capturedAt: now,
        beatsPerMinute: 65,
      );

      when(
        () => stravaProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [stravaHr]);
      when(
        () => appleProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [appleHr]);
      when(
        () => ghcProvider.fetchRecords(
          metricType: any(named: 'metricType'),
          timeRange: any(named: 'timeRange'),
        ),
      ).thenAnswer((_) async => [ghcHr]);

      client
        ..use(stravaProvider)
        ..use(appleProvider)
        ..use(ghcProvider);

      const mergeConfig = MergeConfig(
        providerPriority: [
          DataProvider.apple,
          DataProvider.googleHealthConnect,
          DataProvider.strava,
        ],
      );

      final queryBuilder = client.query()
        ..forMetric(MetricType.heartRate)
        ..inRange(
          TimeRange(
            start: now.subtract(const Duration(hours: 2)),
            end: now,
          ),
        )
        ..withMerge(mergeConfig);

      final executor = QueryExecutor(
        registry: client.registry,
        mergeEngine: MergeEngine(config: mergeConfig),
      );
      final result = await executor.execute(queryBuilder.build());

      // All far apart → no duplicates detected → all kept
      expect(result.records, hasLength(3));
      expect(result.mergeResult!.conflicts, isEmpty);

      final providers = result.records.map((r) => r.provider).toSet();
      expect(
        providers,
        containsAll([
          DataProvider.strava,
          DataProvider.apple,
          DataProvider.googleHealthConnect,
        ]),
      );
    });
  });
}
