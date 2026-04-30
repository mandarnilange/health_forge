// Examples print to stdout for demonstration purposes only.
// ignore_for_file: avoid_print

import 'package:health_forge/health_forge.dart';

/// Constructs a `HealthForgeClient` and builds a multi-metric query.
///
/// Register providers from the platform-specific adapter packages (e.g.
/// `health_forge_apple`, `health_forge_ghc`) via `forge.use(...)` before
/// executing the query.
void main() {
  final forge = HealthForgeClient();

  final query = (forge.query()
        ..forMetrics([MetricType.heartRate, MetricType.sleepSession])
        ..inRange(
          TimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
        ))
      .build();

  final days = query.timeRange.end.difference(query.timeRange.start).inDays;
  print('Built query for ${query.metrics.length} metric(s) over $days day(s).');
  print('Registered providers: ${forge.registry.all.length}');
}
