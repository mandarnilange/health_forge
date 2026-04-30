# health_forge_strava

Strava REST API adapter for [Health Forge](https://github.com/mandarnilange/health_forge_workspace) — fetches workouts, heart rate streams, calories, distance, and elevation via OAuth 2.0 PKCE with page-based pagination and dual rate limiting (100/15min + 1000/day).

Built on [`health_forge_core`](https://pub.dev/packages/health_forge_core) (pure Dart data model + merge engine) and typically used with [`health_forge`](https://pub.dev/packages/health_forge) (Flutter client).

## Supported metrics

5 read-only metrics, `fullWindow` sync.

| Family | Metrics |
|---|---|
| Activity | `activitySession` (workouts with `StravaWorkoutExtension`: suffer score, segment efforts, route polyline) |
| Cardiovascular | `heartRateSample` (from time-series streams) |
| Activity | `caloriesBurned` (kJ → kcal conversion), `distanceSample`, `elevationGain` |

## Provider extension

`StravaWorkoutExtension` preserves Strava-specific fields on `ActivitySession`:

- `sufferScore` — Strava's relative effort metric
- `segmentEfforts` — list of segments completed during the activity
- `routePolyline` — encoded polyline of the GPS route

## Installation

```yaml
dependencies:
  health_forge: ^0.1.0
  health_forge_strava: ^0.1.0
```

Register a Strava app at [strava.com/settings/api](https://www.strava.com/settings/api) to get a client ID and secret. Strava requires a client secret even with PKCE — use a backend token-exchange proxy or accept the security tradeoff for personal apps. The adapter supports a pluggable `StravaTokenExchange` for backend exchange. See [docs/getting_started.md](https://github.com/mandarnilange/health_forge_workspace/blob/main/docs/getting_started.md).

## Usage

```dart
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_strava/health_forge_strava.dart';

final forge = HealthForgeClient()
  ..use(StravaHealthProvider(
    authManager: StravaAuthManager(
      clientId: 'YOUR_CLIENT_ID',
      redirectUri: 'healthforge://strava/callback',
      tokenExchange: MyBackendTokenExchange(), // or provide clientSecret
      launchUrl: (uri) async { /* url_launcher */ },
    ),
  ));

final auth = await forge.auth.authorize(DataProvider.strava);
if (auth.status != AuthStatus.success) return;

final records = await forge.registry
    .getProvider(DataProvider.strava)!
    .fetchRecords(
      metric: MetricType.activitySession,
      range: TimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );
```

## Related packages

| Package | Purpose |
|---|---|
| [`health_forge_core`](https://pub.dev/packages/health_forge_core) | Pure Dart data model + merge engine (required) |
| [`health_forge`](https://pub.dev/packages/health_forge) | Flutter client (recommended) |
| [`health_forge_oura`](https://pub.dev/packages/health_forge_oura) | Oura Ring REST API adapter (recovery data) |

## License

MIT
