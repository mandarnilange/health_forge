import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_example/widgets/record_list_item.dart';

class _UnknownRecord with HealthRecordMixin {
  _UnknownRecord()
      : id = 'u1',
        provider = DataProvider.apple,
        providerRecordType = 'custom.type',
        providerRecordId = null,
        startTime = DateTime.utc(2024, 1, 1, 8),
        endTime = DateTime.utc(2024, 1, 1, 9),
        timezone = null,
        capturedAt = DateTime.utc(2024, 1, 1, 9),
        provenance = null;

  @override
  final String id;

  @override
  final DataProvider provider;

  @override
  final String providerRecordType;

  @override
  final String? providerRecordId;

  @override
  final DateTime startTime;

  @override
  final DateTime endTime;

  @override
  final String? timezone;

  @override
  final DateTime capturedAt;

  @override
  final Provenance? provenance;

  @override
  final Freshness freshness = Freshness.live;

  @override
  final Map<String, dynamic> extensions = const {};
}

void main() {
  final t0 = DateTime.utc(2024, 3, 15, 7);
  final t1 = DateTime.utc(2024, 3, 15, 8);

  Widget wrap(HealthRecordMixin r) {
    return MaterialApp(
      home: Scaffold(
        body: RecordListItem(record: r),
      ),
    );
  }

  testWidgets('renders heart rate', (tester) async {
    await tester.pumpWidget(
      wrap(
        HeartRateSample(
          id: '1',
          provider: DataProvider.apple,
          providerRecordType: 'hr',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          beatsPerMinute: 72,
        ),
      ),
    );
    expect(find.textContaining('bpm'), findsOneWidget);
    expect(find.text('Heart Rate'), findsOneWidget);
  });

  testWidgets('renders steps', (tester) async {
    await tester.pumpWidget(
      wrap(
        StepCount(
          id: '2',
          provider: DataProvider.oura,
          providerRecordType: 'steps',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          count: 5000,
        ),
      ),
    );
    expect(find.textContaining('steps'), findsOneWidget);
  });

  testWidgets('renders sleep session', (tester) async {
    await tester.pumpWidget(
      wrap(
        SleepSession(
          id: '3',
          provider: DataProvider.oura,
          providerRecordType: 'sleep',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          totalSleepMinutes: 480,
        ),
      ),
    );
    expect(find.textContaining('min'), findsOneWidget);
  });

  testWidgets('renders readiness', (tester) async {
    await tester.pumpWidget(
      wrap(
        ReadinessScore(
          id: '4',
          provider: DataProvider.oura,
          providerRecordType: 'readiness',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          score: 82,
        ),
      ),
    );
    expect(find.textContaining('82'), findsOneWidget);
  });

  testWidgets('renders calories', (tester) async {
    await tester.pumpWidget(
      wrap(
        CaloriesBurned(
          id: '5',
          provider: DataProvider.apple,
          providerRecordType: 'cal',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          totalCalories: 2100,
        ),
      ),
    );
    expect(find.textContaining('kcal'), findsOneWidget);
  });

  testWidgets('renders blood oxygen', (tester) async {
    await tester.pumpWidget(
      wrap(
        BloodOxygenSample(
          id: '6',
          provider: DataProvider.apple,
          providerRecordType: 'spo2',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          percentage: 97.5,
        ),
      ),
    );
    expect(find.textContaining('%'), findsOneWidget);
  });

  testWidgets('renders stress', (tester) async {
    await tester.pumpWidget(
      wrap(
        StressScore(
          id: '7',
          provider: DataProvider.oura,
          providerRecordType: 'stress',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          score: 35,
        ),
      ),
    );
    expect(find.textContaining('35'), findsOneWidget);
  });

  testWidgets('renders sleep score', (tester) async {
    await tester.pumpWidget(
      wrap(
        SleepScore(
          id: '8',
          provider: DataProvider.oura,
          providerRecordType: 'sleep_score',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          score: 88,
        ),
      ),
    );
    expect(find.textContaining('88'), findsOneWidget);
  });

  testWidgets('renders HRV', (tester) async {
    await tester.pumpWidget(
      wrap(
        HeartRateVariability(
          id: '9',
          provider: DataProvider.apple,
          providerRecordType: 'hrv',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          sdnnMilliseconds: 45.2,
          rmssdMilliseconds: 32.1,
        ),
      ),
    );
    expect(find.textContaining('ms'), findsOneWidget);
  });

  testWidgets('renders resting HR', (tester) async {
    await tester.pumpWidget(
      wrap(
        RestingHeartRate(
          id: '10',
          provider: DataProvider.apple,
          providerRecordType: 'rhr',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          beatsPerMinute: 58,
        ),
      ),
    );
    expect(find.textContaining('58'), findsOneWidget);
  });

  testWidgets('renders respiratory rate', (tester) async {
    await tester.pumpWidget(
      wrap(
        RespiratoryRate(
          id: '11',
          provider: DataProvider.apple,
          providerRecordType: 'rr',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          breathsPerMinute: 14.5,
        ),
      ),
    );
    expect(find.textContaining('br/min'), findsOneWidget);
  });

  testWidgets('renders weight', (tester) async {
    await tester.pumpWidget(
      wrap(
        Weight(
          id: '12',
          provider: DataProvider.apple,
          providerRecordType: 'w',
          startTime: t0,
          endTime: t0,
          capturedAt: t0,
          kilograms: 72.3,
        ),
      ),
    );
    expect(find.textContaining('kg'), findsOneWidget);
  });

  testWidgets('renders distance', (tester) async {
    await tester.pumpWidget(
      wrap(
        DistanceSample(
          id: '13',
          provider: DataProvider.strava,
          providerRecordType: 'dist',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          distanceMeters: 5200,
        ),
      ),
    );
    expect(find.textContaining('km'), findsOneWidget);
  });

  testWidgets('renders elevation', (tester) async {
    await tester.pumpWidget(
      wrap(
        ElevationGain(
          id: '14',
          provider: DataProvider.strava,
          providerRecordType: 'el',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          elevationMeters: 120,
        ),
      ),
    );
    expect(find.textContaining('120'), findsOneWidget);
  });

  testWidgets('renders workout', (tester) async {
    await tester.pumpWidget(
      wrap(
        ActivitySession(
          id: '15',
          provider: DataProvider.strava,
          providerRecordType: 'workout',
          startTime: t0,
          endTime: t1,
          capturedAt: t1,
          activityType: MetricType.workout,
          activityName: 'Run',
          totalCalories: 400,
        ),
      ),
    );
    expect(find.textContaining('Run'), findsOneWidget);
  });

  testWidgets('renders unknown record type as providerRecordType',
      (tester) async {
    await tester.pumpWidget(wrap(_UnknownRecord()));
    // Title and trailing both use providerRecordType for unknown mixins.
    expect(find.text('custom.type'), findsNWidgets(2));
  });

  testWidgets('onTap fires when set', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordListItem(
            record: HeartRateSample(
              id: '1',
              provider: DataProvider.apple,
              providerRecordType: 'hr',
              startTime: t0,
              endTime: t1,
              capturedAt: t1,
              beatsPerMinute: 70,
            ),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });
}
