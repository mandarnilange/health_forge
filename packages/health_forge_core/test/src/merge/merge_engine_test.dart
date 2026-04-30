import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

/// Non-freezed [HealthRecordMixin] so [MergeEngine] exercises string-based
/// metric classification (`_metricTypeFromProviderRecordType`).
class _FallbackMetricRecord with HealthRecordMixin {
  _FallbackMetricRecord({
    required this.id,
    required this.providerRecordType,
    DateTime? start,
  }) : _start = start ?? DateTime.utc(2026, 3, 17, 10);

  @override
  final String id;

  @override
  final DataProvider provider = DataProvider.apple;

  @override
  final String providerRecordType;

  final DateTime _start;

  @override
  final String? providerRecordId = null;

  @override
  DateTime get startTime => _start;

  @override
  DateTime get endTime => _start.add(const Duration(minutes: 1));

  @override
  final String? timezone = null;

  @override
  DateTime get capturedAt => _start;

  @override
  final Provenance? provenance = null;

  @override
  final Freshness freshness = Freshness.live;

  @override
  final Map<String, dynamic> extensions = const {};
}

void main() {
  group('MergeEngine', () {
    final now = DateTime.utc(2026, 3, 17, 10);

    HeartRateSample makeHR({
      required String id,
      required DataProvider provider,
      required DateTime start,
      required DateTime end,
      int bpm = 72,
    }) =>
        HeartRateSample(
          id: id,
          provider: provider,
          providerRecordType: 'heartRate',
          startTime: start,
          endTime: end,
          capturedAt: now,
          beatsPerMinute: bpm,
        );

    SleepSession makeSleep({
      required String id,
      required DataProvider provider,
      required DateTime start,
      required DateTime end,
    }) =>
        SleepSession(
          id: id,
          provider: provider,
          providerRecordType: 'sleep',
          startTime: start,
          endTime: end,
          capturedAt: now,
        );

    test('non-overlapping records from multiple providers all kept', () {
      final engine = MergeEngine(
        config: const MergeConfig(
          providerPriority: [DataProvider.oura, DataProvider.apple],
        ),
      );

      final result = engine.merge([
        makeHR(
          id: '1',
          provider: DataProvider.apple,
          start: now,
          end: now.add(const Duration(minutes: 1)),
        ),
        makeHR(
          id: '2',
          provider: DataProvider.oura,
          start: now.add(const Duration(minutes: 10)),
          end: now.add(const Duration(minutes: 11)),
        ),
      ]);

      expect(result.resolved, hasLength(2));
      expect(result.conflicts, isEmpty);
    });

    test('overlapping HR from Apple + Oura with priority picks Oura', () {
      final engine = MergeEngine(
        config: const MergeConfig(
          providerPriority: [DataProvider.oura, DataProvider.apple],
        ),
      );

      final result = engine.merge([
        makeHR(
          id: '1',
          provider: DataProvider.apple,
          start: now,
          end: now.add(const Duration(minutes: 5)),
          bpm: 70,
        ),
        makeHR(
          id: '2',
          provider: DataProvider.oura,
          start: now.add(const Duration(minutes: 2)),
          end: now.add(const Duration(minutes: 7)),
          bpm: 75,
        ),
      ]);

      expect(result.resolved, hasLength(1));
      expect(result.resolved.first.provider, DataProvider.oura);
      expect(result.conflicts, hasLength(1));
      expect(result.conflicts.first.strategy, ConflictStrategy.priorityBased);
    });

    test('same sleep session from two providers dedup keeps one', () {
      final engine = MergeEngine(
        config: const MergeConfig(
          providerPriority: [DataProvider.oura, DataProvider.apple],
        ),
      );

      final bedtime = DateTime.utc(2026, 3, 16, 22);
      final wakeup = DateTime.utc(2026, 3, 17, 6);

      final result = engine.merge([
        makeSleep(
          id: '1',
          provider: DataProvider.apple,
          start: bedtime,
          end: wakeup,
        ),
        makeSleep(
          id: '2',
          provider: DataProvider.oura,
          start: bedtime,
          end: wakeup,
        ),
      ]);

      expect(result.resolved, hasLength(1));
      expect(result.resolved.first.provider, DataProvider.oura);
    });

    test('average strategy averages numeric values', () {
      final engine = MergeEngine(
        config: const MergeConfig(
          defaultStrategy: ConflictStrategy.average,
        ),
      );

      final result = engine.merge([
        makeHR(
          id: '1',
          provider: DataProvider.apple,
          start: now,
          end: now.add(const Duration(minutes: 1)),
          bpm: 70,
        ),
        makeHR(
          id: '2',
          provider: DataProvider.oura,
          start: now,
          end: now.add(const Duration(minutes: 1)),
          bpm: 80,
        ),
      ]);

      expect(result.resolved, hasLength(1));
      final hr = result.resolved.first as HeartRateSample;
      expect(hr.beatsPerMinute, 75);
    });

    test('exact duplicates same provider same time deduplicated', () {
      final engine = MergeEngine(config: const MergeConfig());

      final result = engine.merge([
        makeHR(
          id: '1',
          provider: DataProvider.apple,
          start: now,
          end: now.add(const Duration(minutes: 1)),
        ),
        makeHR(
          id: '2',
          provider: DataProvider.apple,
          start: now,
          end: now.add(const Duration(minutes: 1)),
        ),
      ]);

      expect(result.resolved, hasLength(1));
    });

    test('empty input produces empty result', () {
      final engine = MergeEngine(config: const MergeConfig());

      final result = engine.merge([]);

      expect(result.resolved, isEmpty);
      expect(result.conflicts, isEmpty);
      expect(result.rawSources, isEmpty);
    });

    test('mixed metrics resolved independently', () {
      final engine = MergeEngine(
        config: const MergeConfig(
          providerPriority: [DataProvider.oura, DataProvider.apple],
        ),
      );

      final bedtime = DateTime.utc(2026, 3, 16, 22);
      final wakeup = DateTime.utc(2026, 3, 17, 6);

      final result = engine.merge([
        makeHR(
          id: 'hr-1',
          provider: DataProvider.apple,
          start: now,
          end: now.add(const Duration(minutes: 5)),
          bpm: 70,
        ),
        makeHR(
          id: 'hr-2',
          provider: DataProvider.oura,
          start: now.add(const Duration(minutes: 2)),
          end: now.add(const Duration(minutes: 7)),
          bpm: 75,
        ),
        makeSleep(
          id: 'sleep-1',
          provider: DataProvider.apple,
          start: bedtime,
          end: wakeup,
        ),
        makeSleep(
          id: 'sleep-2',
          provider: DataProvider.oura,
          start: bedtime,
          end: wakeup,
        ),
      ]);

      // Each group resolved independently: 1 HR + 1 sleep
      expect(result.resolved, hasLength(2));
      // Both conflicts reported
      expect(result.conflicts, hasLength(2));
    });

    test('rawSources contains all input records', () {
      final engine = MergeEngine(config: const MergeConfig());

      final records = [
        makeHR(
          id: '1',
          provider: DataProvider.apple,
          start: now,
          end: now.add(const Duration(minutes: 1)),
        ),
        makeHR(
          id: '2',
          provider: DataProvider.oura,
          start: now.add(const Duration(minutes: 10)),
          end: now.add(const Duration(minutes: 11)),
        ),
      ];

      final result = engine.merge(records);
      expect(result.rawSources, hasLength(2));
    });

    test('classifies all record types without heartRate fallback', () {
      final engine = MergeEngine(
        config: const MergeConfig(
          providerPriority: [DataProvider.oura, DataProvider.apple],
        ),
      );

      // StepCount should be classified as steps, not heartRate
      final steps = StepCount(
        id: 'step-1',
        provider: DataProvider.apple,
        providerRecordType: 'STEPS_COUNT',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        capturedAt: now,
        count: 1000,
      );
      final hr = makeHR(
        id: 'hr-1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 5)),
      );

      // Different metric groups (steps vs heartRate) resolve independently
      final result = engine.merge([steps, hr]);
      expect(result.resolved, hasLength(2));
    });

    test('custom strategy used via per-metric config', () {
      final engine = MergeEngine(
        config: const MergeConfig(
          perMetricStrategy: {
            MetricType.heartRate: ConflictStrategy.custom,
          },
        ),
        customStrategy: CustomStrategy(
          resolver: (records, metricType) => [records.last], // always pick last
        ),
      );

      final result = engine.merge([
        makeHR(
          id: '1',
          provider: DataProvider.apple,
          start: now,
          end: now.add(const Duration(minutes: 5)),
          bpm: 70,
        ),
        makeHR(
          id: '2',
          provider: DataProvider.oura,
          start: now.add(const Duration(minutes: 2)),
          end: now.add(const Duration(minutes: 7)),
          bpm: 80,
        ),
      ]);

      expect(result.resolved, hasLength(1));
      expect(result.resolved.first.id, '2');
    });

    test('ConflictStrategy.custom without CustomStrategy throws', () {
      final engine = MergeEngine(
        config: const MergeConfig(
          perMetricStrategy: {
            MetricType.heartRate: ConflictStrategy.custom,
          },
        ),
      );

      expect(
        () => engine.merge([
          makeHR(
            id: '1',
            provider: DataProvider.apple,
            start: now,
            end: now.add(const Duration(minutes: 5)),
          ),
          makeHR(
            id: '2',
            provider: DataProvider.oura,
            start: now.add(const Duration(minutes: 2)),
            end: now.add(const Duration(minutes: 7)),
          ),
        ]),
        throwsStateError,
      );
    });

    test('classifies metrics from providerRecordType string aliases', () {
      final engine = MergeEngine(config: const MergeConfig());
      // One alias per [MetricType]; duplicate strings map to the same type and
      // would be overlap-deduped if intervals intersect.
      final aliases = <String>[
        'heartrate',
        'heart_rate_variability',
        'sleep',
        'steps',
        'weight',
        'bodyfat',
        'bloodpressure',
        'bloodglucose',
        'calories',
        'distance',
        'elevation',
        'workout',
        'readiness',
        'stress',
        'recovery',
        'bloodoxygen',
        'respiratoryrate',
        'restingheartrate',
        'sleepscore',
      ];
      final records = <HealthRecordMixin>[
        for (var i = 0; i < aliases.length; i++)
          _FallbackMetricRecord(
            id: 'fb-$i',
            providerRecordType: aliases[i],
            start: now.add(Duration(minutes: i * 5)),
          ),
      ];
      final result = engine.merge(records);
      expect(result.resolved, hasLength(aliases.length));
    });

    test('providerRecordType alternate spellings map to same metrics', () {
      final engine = MergeEngine(config: const MergeConfig());
      final records = <HealthRecordMixin>[
        _FallbackMetricRecord(
          id: 'a',
          providerRecordType: 'sleep_session',
          start: now,
        ),
        _FallbackMetricRecord(
          id: 'b',
          providerRecordType: 'sleepsession',
          start: now.add(const Duration(hours: 2)),
        ),
        _FallbackMetricRecord(
          id: 'c',
          providerRecordType: 'step_count',
          start: now.add(const Duration(hours: 4)),
        ),
      ];
      expect(engine.merge(records).resolved, hasLength(3));
    });

    test('unknown providerRecordType in fallback throws ArgumentError', () {
      final engine = MergeEngine(config: const MergeConfig());
      expect(
        () => engine.merge([
          _FallbackMetricRecord(
            id: 'bad',
            providerRecordType: 'totally_unknown_metric',
          ),
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('classifies concrete record types in exhaustive metric switch', () {
      final engine = MergeEngine(config: const MergeConfig());
      final t = DateTime.utc(2026, 3, 17, 8);
      final records = <HealthRecordMixin>[
        WorkoutRoute(
          id: 'wr',
          provider: DataProvider.strava,
          providerRecordType: 'route',
          startTime: t,
          endTime: t.add(const Duration(minutes: 30)),
          capturedAt: t,
          points: const [
            RoutePoint(latitude: 1, longitude: 2),
          ],
        ),
        RecoveryMetric(
          id: 'rec',
          provider: DataProvider.oura,
          providerRecordType: 'recovery',
          startTime: t,
          endTime: t.add(const Duration(hours: 1)),
          capturedAt: t,
          score: 80,
        ),
        BodyFat(
          id: 'bf',
          provider: DataProvider.apple,
          providerRecordType: 'bf',
          startTime: t,
          endTime: t,
          capturedAt: t,
          percentage: 18.5,
        ),
        BloodPressure(
          id: 'bp',
          provider: DataProvider.apple,
          providerRecordType: 'bp',
          startTime: t,
          endTime: t,
          capturedAt: t,
          systolicMmHg: 120,
          diastolicMmHg: 80,
        ),
        BloodGlucose(
          id: 'bg',
          provider: DataProvider.apple,
          providerRecordType: 'bg',
          startTime: t,
          endTime: t,
          capturedAt: t,
          milligramsPerDeciliter: 95,
        ),
      ];
      expect(engine.merge(records).resolved, hasLength(records.length));
    });
  });
}
