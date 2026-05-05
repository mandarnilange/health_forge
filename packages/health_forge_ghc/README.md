# health_forge_ghc

Google Health Connect adapter for [Health Forge](https://github.com/mandarnilange/health_forge) — reads 14 health metric types from Health Connect on Android and maps them to the unified `health_forge_core` data model.

Built on [`health_forge_core`](https://pub.dev/packages/health_forge_core) (pure Dart data model + merge engine) and typically used with [`health_forge`](https://pub.dev/packages/health_forge) (Flutter client).

## Supported metrics

Activity (4), Cardiovascular (3), Sleep (1 session with stages), Body (4), Respiratory (2) — 14 metric types total, all read-only.

| Family | Metrics |
|---|---|
| Activity | `steps`, `caloriesBurned`, `distanceSample`, `activitySession` (workouts) |
| Cardiovascular | `heartRateSample`, `heartRateVariability`, `restingHeartRate` |
| Sleep | `sleepSession` with `SleepStageSegment`s (5 Health Connect stage types aggregated + deduplicated) |
| Body | `weight`, `bodyFat`, `bloodPressure`, `bloodGlucose` |
| Respiratory | `bloodOxygen`, `respiratoryRate` |

## Installation

```yaml
dependencies:
  health_forge: ^0.1.1
  health_forge_ghc: ^0.1.1
```

Add Health Connect read permissions to `android/app/src/main/AndroidManifest.xml`. See [docs/getting_started.md](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for full Android setup.

> **Using an AI coding agent?** Install the matching skill so Claude Code, Cursor, Codex, or any of the [50+ supported agents](https://skills.sh) can wire this in for you:
> ```bash
> npx skills add mandarnilange/health_forge --skill integrate-health-forge-ghc
> ```

## Usage

```dart
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';

final forge = HealthForgeClient()..use(GhcHealthProvider());

final auth = await forge.auth.authorize(DataProvider.googleHealthConnect);
if (auth.status != AuthStatus.success) return;

final records = await forge.registry
    .getProvider(DataProvider.googleHealthConnect)!
    .fetchRecords(
      metric: MetricType.sleepSession,
      range: TimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
```

## Related packages

| Package | Purpose |
|---|---|
| [`health_forge_core`](https://pub.dev/packages/health_forge_core) | Pure Dart data model + merge engine (required) |
| [`health_forge`](https://pub.dev/packages/health_forge) | Flutter client (recommended) |
| [`health_forge_apple`](https://pub.dev/packages/health_forge_apple) | Apple HealthKit adapter (iOS counterpart) |

## License

MIT
