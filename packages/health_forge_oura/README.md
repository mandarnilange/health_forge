# health_forge_oura

Oura Ring REST API adapter for [Health Forge](https://github.com/mandarnilange/health_forge) — fetches sleep, heart rate, readiness, stress, activity, and SpO2 data via OAuth 2.0 PKCE with automatic pagination and rate limiting.

Built on [`health_forge_core`](https://pub.dev/packages/health_forge_core) (pure Dart data model + merge engine) and typically used with [`health_forge`](https://pub.dev/packages/health_forge) (Flutter client).

## Supported metrics

8 read-only metrics, incremental sync via `next_token` pagination.

| Family | Metrics |
|---|---|
| Sleep | `sleepSession` (with `OuraSleepExtension`: readiness contributor, temperature deviation, hypnogram), `sleepScore` |
| Cardiovascular | `heartRateSample` |
| Activity | `steps`, `caloriesBurned` |
| Recovery | `readinessScore`, `stressScore` |
| Respiratory | `bloodOxygen` |

## Provider extension

`OuraSleepExtension` preserves Oura-specific fields that don't fit the unified model:

- `readinessContributorSleep` — sleep's contribution to daily readiness
- `temperatureDeviation` — body temperature deviation from baseline
- Hypnogram string (parsed into `SleepStageSegment`s on the main record)

## Installation

```yaml
dependencies:
  health_forge: ^0.1.1
  health_forge_oura: ^0.1.1
```

Register an Oura app at [cloud.ouraring.com](https://cloud.ouraring.com/oauth/applications) to get a client ID. Configure your OAuth redirect URI (e.g. `healthforge://oura/callback`). See [docs/getting_started.md](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for deep-link setup.

> **Using an AI coding agent?** Install the matching skill so Claude Code, Cursor, Codex, or any of the [50+ supported agents](https://skills.sh) can wire this in for you:
> ```bash
> npx skills add mandarnilange/health_forge --skill integrate-health-forge-oura
> ```

## Usage

```dart
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_oura/health_forge_oura.dart';

final forge = HealthForgeClient()
  ..use(OuraHealthProvider(
    authManager: OuraAuthManager(
      clientId: 'YOUR_CLIENT_ID',
      redirectUri: 'healthforge://oura/callback',
      launchUrl: (uri) async { /* url_launcher */ },
    ),
  ));

final auth = await forge.auth.authorize(DataProvider.oura);
if (auth.status != AuthStatus.success) return;

final records = await forge.registry
    .getProvider(DataProvider.oura)!
    .fetchRecords(
      metric: MetricType.readinessScore,
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
| [`health_forge_strava`](https://pub.dev/packages/health_forge_strava) | Strava REST API adapter (fitness data) |

## License

MIT
