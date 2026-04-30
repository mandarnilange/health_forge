import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health_forge/health_forge.dart';

import 'package:health_forge_example/widgets/metric_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.client, super.key});

  final HealthForgeClient client;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  int? _steps;
  SleepSession? _sleepSession;
  int? _heartRate;
  int? _readinessScore;
  int? _calories;
  double? _distanceKm;
  int? _restingHr;
  double? _spo2;
  double? _weightKg;
  int? _workoutCount;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDashboard());
  }

  Future<void> _loadDashboard() async {
    // Reset values so stale data is cleared before re-syncing.
    setState(() {
      _steps = null;
      _sleepSession = null;
      _heartRate = null;
      _readinessScore = null;
      _calories = null;
      _distanceKm = null;
      _restingHr = null;
      _spo2 = null;
      _weightKg = null;
      _workoutCount = null;
    });

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final todayRange = TimeRange(start: todayStart, end: todayEnd);
    final overnightRange = TimeRange(start: yesterdayStart, end: todayEnd);

    // Sync all providers and metrics in parallel.
    final syncFutures = <Future<void>>[];
    final dayMetrics = [
      MetricType.steps,
      MetricType.heartRate,
      MetricType.readiness,
      MetricType.calories,
      MetricType.distance,
      MetricType.restingHeartRate,
      MetricType.bloodOxygen,
      MetricType.weight,
      MetricType.workout,
    ];

    for (final provider in widget.client.registry.all) {
      final type = provider.providerType;
      for (final metric in dayMetrics) {
        if (provider.capabilities.supports(metric)) {
          syncFutures.add(
            widget.client.sync(
              provider: type,
              metric: metric,
              range: todayRange,
            ),
          );
        }
      }
      if (provider.capabilities.supports(MetricType.sleepSession)) {
        syncFutures.add(
          widget.client.sync(
            provider: type,
            metric: MetricType.sleepSession,
            range: overnightRange,
          ),
        );
      }
    }
    await Future.wait(syncFutures);

    // Read from cache
    final stepRecords = await widget.client.cache.get(
      metric: MetricType.steps,
      range: todayRange,
    );
    final sleepRecords = await widget.client.cache.get(
      metric: MetricType.sleepSession,
      range: overnightRange,
    );
    final hrRecords = await widget.client.cache.get(
      metric: MetricType.heartRate,
      range: todayRange,
    );
    final readinessRecords = await widget.client.cache.get(
      metric: MetricType.readiness,
      range: todayRange,
    );
    final calRecords = await widget.client.cache.get(
      metric: MetricType.calories,
      range: todayRange,
    );
    final distRecords = await widget.client.cache.get(
      metric: MetricType.distance,
      range: todayRange,
    );
    final restHrRecords = await widget.client.cache.get(
      metric: MetricType.restingHeartRate,
      range: todayRange,
    );
    final spo2Records = await widget.client.cache.get(
      metric: MetricType.bloodOxygen,
      range: todayRange,
    );
    final weightRecords = await widget.client.cache.get(
      metric: MetricType.weight,
      range: todayRange,
    );
    final workoutRecords = await widget.client.cache.get(
      metric: MetricType.workout,
      range: todayRange,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _steps = _maxBySource<StepCount>(
        stepRecords,
        (s) => s.count,
      );
      // Pick the sleep session with the most detailed stage data.
      // Multiple sources (Apple Watch, iPhone, Garmin) may each report
      // sleep — select the most informative one for the dashboard.
      final sessions = sleepRecords.whereType<SleepSession>().toList();
      if (sessions.isNotEmpty) {
        sessions.sort((a, b) => b.stages.length.compareTo(a.stages.length));
        _sleepSession = sessions.first;
      }
      if (hrRecords.isNotEmpty) {
        final samples = hrRecords.whereType<HeartRateSample>().toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
        if (samples.isNotEmpty) _heartRate = samples.first.beatsPerMinute;
      }
      if (readinessRecords.isNotEmpty) {
        final r = readinessRecords.first;
        if (r is ReadinessScore) _readinessScore = r.score;
      }
      _calories = _maxBySource<CaloriesBurned>(
        calRecords,
        (c) => c.totalCalories.toInt(),
      );
      final distMax = _maxBySourceDouble<DistanceSample>(
        distRecords,
        (d) => d.distanceMeters,
      );
      if (distMax != null) _distanceKm = distMax / 1000;
      if (restHrRecords.isNotEmpty) {
        final samples = restHrRecords.whereType<RestingHeartRate>().toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
        if (samples.isNotEmpty) _restingHr = samples.first.beatsPerMinute;
      }
      if (spo2Records.isNotEmpty) {
        final samples = spo2Records.whereType<BloodOxygenSample>().toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
        if (samples.isNotEmpty) _spo2 = samples.first.percentage;
      }
      if (weightRecords.isNotEmpty) {
        final samples = weightRecords.whereType<Weight>().toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
        if (samples.isNotEmpty) _weightKg = samples.first.kilograms;
      }
      _workoutCount = workoutRecords.whereType<ActivitySession>().length;
    });
  }

  /// Sum values within each (provider, sourceApp) pair, then return the
  /// max across all sources. Apple Health can report the same steps from
  /// both the iPhone (Health) and Apple Watch (Connect) — summing across
  /// sources would double-count.
  int? _maxBySource<T extends HealthRecordMixin>(
    List<HealthRecordMixin> records,
    int Function(T) getValue,
  ) {
    final bySource = <String, int>{};
    for (final r in records.whereType<T>()) {
      final key = '${r.provider.name}:${r.provenance?.sourceApp ?? ""}';
      bySource[key] = (bySource[key] ?? 0) + getValue(r);
    }
    if (bySource.isEmpty) return null;
    return bySource.values.reduce((a, b) => a > b ? a : b);
  }

  double? _maxBySourceDouble<T extends HealthRecordMixin>(
    List<HealthRecordMixin> records,
    double Function(T) getValue,
  ) {
    final bySource = <String, double>{};
    for (final r in records.whereType<T>()) {
      final key = '${r.provider.name}:${r.provenance?.sourceApp ?? ""}';
      bySource[key] = (bySource[key] ?? 0) + getValue(r);
    }
    if (bySource.isEmpty) return null;
    return bySource.values.reduce((a, b) => a > b ? a : b);
  }

  Widget _buildSleepCard(BuildContext context) {
    final theme = Theme.of(context);
    final session = _sleepSession;
    final total = _formatSleep(session?.totalSleepMinutes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bedtime,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sleep',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  total,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (session != null && _hasStageData(session)) ...[
              const SizedBox(height: 12),
              _buildStageBar(context, session),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stageLegend(
                    context,
                    'Deep',
                    session.deepMinutes,
                    const Color(0xFF1A237E),
                  ),
                  _stageLegend(
                    context,
                    'Light',
                    session.lightMinutes,
                    const Color(0xFF42A5F5),
                  ),
                  _stageLegend(
                    context,
                    'REM',
                    session.remMinutes,
                    const Color(0xFF7E57C2),
                  ),
                  _stageLegend(
                    context,
                    'Awake',
                    session.awakeMinutes,
                    const Color(0xFFFF7043),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasStageData(SleepSession session) {
    return (session.deepMinutes ?? 0) > 0 ||
        (session.lightMinutes ?? 0) > 0 ||
        (session.remMinutes ?? 0) > 0 ||
        (session.awakeMinutes ?? 0) > 0;
  }

  Widget _buildStageBar(BuildContext context, SleepSession session) {
    final deep = (session.deepMinutes ?? 0).toDouble();
    final light = (session.lightMinutes ?? 0).toDouble();
    final rem = (session.remMinutes ?? 0).toDouble();
    final awake = (session.awakeMinutes ?? 0).toDouble();
    final total = deep + light + rem + awake;
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (deep > 0)
              Expanded(
                flex: (deep / total * 100).round(),
                child: Container(color: const Color(0xFF1A237E)),
              ),
            if (light > 0)
              Expanded(
                flex: (light / total * 100).round(),
                child: Container(color: const Color(0xFF42A5F5)),
              ),
            if (rem > 0)
              Expanded(
                flex: (rem / total * 100).round(),
                child: Container(color: const Color(0xFF7E57C2)),
              ),
            if (awake > 0)
              Expanded(
                flex: (awake / total * 100).round(),
                child: Container(color: const Color(0xFFFF7043)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stageLegend(
    BuildContext context,
    String label,
    int? minutes,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _formatSleep(minutes),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatSleep(int? minutes) {
    if (minutes == null) return '--';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "Today's Summary",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Steps',
                          value: _steps?.toString() ?? '--',
                          unit: 'steps',
                          icon: Icons.directions_walk,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          title: 'Calories',
                          value: _calories?.toString() ?? '--',
                          unit: 'kcal',
                          icon: Icons.local_fire_department,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Distance',
                          value: _distanceKm?.toStringAsFixed(1) ?? '--',
                          unit: 'km',
                          icon: Icons.straighten,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          title: 'Workouts',
                          value: _workoutCount?.toString() ?? '--',
                          unit: 'today',
                          icon: Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Heart Rate',
                          value: _heartRate?.toString() ?? '--',
                          unit: 'bpm',
                          icon: Icons.favorite,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          title: 'Resting HR',
                          value: _restingHr?.toString() ?? '--',
                          unit: 'bpm',
                          icon: Icons.monitor_heart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSleepCard(context),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Readiness',
                          value: _readinessScore?.toString() ?? '--',
                          unit: '/100',
                          icon: Icons.bolt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'SpO2',
                          value: _spo2?.toStringAsFixed(1) ?? '--',
                          unit: '%',
                          icon: Icons.air,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          title: 'Weight',
                          value: _weightKg?.toStringAsFixed(1) ?? '--',
                          unit: 'kg',
                          icon: Icons.monitor_weight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
