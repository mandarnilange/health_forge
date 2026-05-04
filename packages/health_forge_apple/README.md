# health_forge_apple

Apple HealthKit adapter for [Health Forge](https://github.com/mandarnilange/health_forge) — reads 14 health metric types from HealthKit on iOS and maps them to the unified `health_forge_core` data model.

Built on [`health_forge_core`](https://pub.dev/packages/health_forge_core) (pure Dart data model + merge engine) and typically used with [`health_forge`](https://pub.dev/packages/health_forge) (Flutter client).

## Supported metrics

Activity (4), Cardiovascular (3), Sleep (1 session with stages), Body (4), Respiratory (2) — 14 metric types total, all read-only.

| Family | Metrics |
|---|---|
| Activity | `steps`, `caloriesBurned`, `distanceSample`, `activitySession` (workouts) |
| Cardiovascular | `heartRateSample`, `heartRateVariability`, `restingHeartRate` |
| Sleep | `sleepSession` with `SleepStageSegment`s (6 HealthKit stage types aggregated + deduplicated) |
| Body | `weight`, `bodyFat`, `bloodPressure`, `bloodGlucose` |
| Respiratory | `bloodOxygen`, `respiratoryRate` |

## Installation

```yaml
dependencies:
  health_forge: ^0.1.1
  health_forge_apple: ^0.1.1
```

Add HealthKit entitlement and `NSHealthShareUsageDescription` to `ios/Runner/Info.plist`. See [docs/getting_started.md](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for full iOS setup.

> **Using an AI coding agent?** Install the matching skill so Claude Code, Cursor, Codex, or any of the [50+ supported agents](https://skills.sh) can wire this in for you:
> ```bash
> npx skills add mandarnilange/health_forge --skill integrate-health-forge-apple
> ```

## Usage

```dart
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_apple/health_forge_apple.dart';

final forge = HealthForgeClient()..use(AppleHealthProvider());

final auth = await forge.auth.authorize(DataProvider.apple);
if (auth.status != AuthStatus.success) return;

final records = await forge.registry
    .getProvider(DataProvider.apple)!
    .fetchRecords(
      metric: MetricType.heartRate,
      range: TimeRange(
        start: DateTime.now().subtract(const Duration(days: 1)),
        end: DateTime.now(),
      ),
    );
```

## Related packages

| Package | Purpose |
|---|---|
| [`health_forge_core`](https://pub.dev/packages/health_forge_core) | Pure Dart data model + merge engine (required) |
| [`health_forge`](https://pub.dev/packages/health_forge) | Flutter client (recommended) |
| [`health_forge_ghc`](https://pub.dev/packages/health_forge_ghc) | Google Health Connect adapter (Android counterpart) |

## License

MIT
