---
name: integrate-health-forge-strava
description: >
  Integrate `health_forge_strava` — the Strava REST API adapter — into a
  user's Flutter app. Trigger when the user wants to read Strava data
  (workouts, heart rate streams, calories, distance, elevation) via
  OAuth 2.0 PKCE. Requires the `health_forge` Flutter client — see related
  skill `integrate-health-forge` for client setup. Strava requires a client
  secret; prefer a backend token-exchange proxy for production.
  Note: This adapter is code-complete with unit tests but has not yet been
  validated end-to-end against the live Strava API.
---

# Integrate health_forge_strava

Read Strava data via REST API. 5 read-only metrics, OAuth 2.0 PKCE auth, dual rate limiting (100/15min + 1000/day).

**Prerequisite:** This adapter plugs into the `health_forge` Flutter client. Follow [`integrate-health-forge`](../integrate-health-forge/SKILL.md) for client + cache setup first.

> ⚠️ **Not yet validated against the live Strava API.** Unit tests pass; expect minor integration work the first time it's wired against a real developer account.

## Supported metrics (5)

| Family | Metrics |
|---|---|
| Activity | `activitySession` (workouts with `StravaWorkoutExtension`: suffer score, segment efforts, route polyline), `caloriesBurned` (kJ → kcal), `distanceSample`, `elevationGain` |
| Cardiovascular | `heartRateSample` (from per-activity time-series streams) |

## Key decision — backend vs. direct token exchange

Strava's token endpoint **requires a client secret** even with PKCE. You have two choices:

| | Backend exchange (recommended) | Direct exchange (dev only) |
|---|---|---|
| Where secret lives | Your server | Embedded in the app |
| Security | ✅ Secret never leaves server | ❌ Recoverable from APK/IPA |
| Setup | Implement `StravaTokenExchange` | Pass `clientSecret` to `StravaAuthManager` |
| Use for | Production | Local dev, personal apps |

**Always use backend exchange for published apps.**

## Integration steps

### 1. Register a Strava app

Go to [strava.com/settings/api](https://www.strava.com/settings/api) and create an app.

- **Client ID** — ships in the app
- **Client Secret** — keep on your server (production) or embed (dev only)
- **Authorization Callback Domain** — the scheme part of your redirect URI (e.g. `com.yourapp`)

### 2. Configure deep links

Same pattern as Oura — see [`integrate-health-forge-oura`](../integrate-health-forge-oura/SKILL.md) step 2. Use a redirect URI like `com.yourapp://strava-callback`.

### 3. Add dependencies

```yaml
dependencies:
  health_forge: ^0.1.1
  health_forge_strava: ^0.1.1
  url_launcher: ^6.2.0
  app_links: ^6.0.0
  flutter_secure_storage: ^9.0.0
  dio: ^5.4.0  # if using backend exchange
```

### 4a. Backend token exchange (production)

Build a server endpoint (`POST /strava/token`) that:
1. Accepts `grant_type`, `code`, `code_verifier`, `redirect_uri` (authorize) or `grant_type`, `refresh_token` (refresh).
2. Adds `client_id` and `client_secret` from server config.
3. Forwards to `https://www.strava.com/api/v3/oauth/token`.
4. Returns Strava's JSON as-is.

Then implement `StravaTokenExchange`:

```dart
import 'package:dio/dio.dart';
import 'package:health_forge_strava/health_forge_strava.dart';

StravaToken _tokenFromApi(Map<String, dynamic> body) => StravaToken(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
      expiresAt: DateTime.now()
          .add(Duration(seconds: (body['expires_in'] as num).toInt())),
    );

class BackendStravaExchange implements StravaTokenExchange {
  BackendStravaExchange(this._dio, {required this.baseUrl});
  final Dio _dio;
  final String baseUrl;

  @override
  Future<StravaToken> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/strava/token',
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': codeVerifier,
        'redirect_uri': redirectUri,
      },
    );
    return _tokenFromApi(res.data!);
  }

  @override
  Future<StravaToken> refreshAccessToken({required String refreshToken}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/strava/token',
      data: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
    );
    return _tokenFromApi(res.data!);
  }
}

final stravaAuth = StravaAuthManager(
  clientId: 'YOUR_STRAVA_CLIENT_ID',
  tokenExchange: BackendStravaExchange(Dio(), baseUrl: 'https://api.yourapp.com'),
  redirectUri: 'com.yourapp://strava-callback',
  urlLauncher: launchAndWaitForRedirect,
  initialToken: savedToken,
  onTokenChanged: saveToken,
);
```

### 4b. Direct token exchange (development only)

```dart
import 'package:health_forge_strava/health_forge_strava.dart';

final stravaAuth = StravaAuthManager(
  clientId: 'YOUR_STRAVA_CLIENT_ID',
  clientSecret: 'YOUR_STRAVA_CLIENT_SECRET',  // ⚠️ visible in compiled app
  redirectUri: 'com.yourapp://strava-callback',
  urlLauncher: launchAndWaitForRedirect,
  initialToken: savedToken,
  onTokenChanged: saveToken,
);
```

### 5. Build and register the provider

```dart
final stravaApi = StravaApiClient(authManager: stravaAuth);
final stravaProvider = StravaHealthProvider(
  authManager: stravaAuth,
  apiClient: stravaApi,
);

forge.use(stravaProvider);
```

### 6. Authorize and fetch

```dart
final auth = await forge.auth.authorize(DataProvider.strava);
if (!auth.isSuccess) return;

final workouts = await forge.registry
    .getProvider(DataProvider.strava)!
    .fetchRecords(
      metricType: MetricType.activitySession,
      timeRange: TimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );
```

### 7. Read the Strava workout extension

```dart
for (final record in workouts) {
  if (record is ActivitySession) {
    final ext = StravaWorkoutExtension.fromJson(record.extensions);
    print('${record.activityName}: suffer score = ${ext.sufferScore}');
    print('Route polyline: ${ext.routePolyline}');
    print('Segments: ${ext.segmentEfforts?.length ?? 0}');
  }
}
```

## Heart rate streams

Strava returns heart rate as per-activity time-series **streams**, not individual samples. The adapter fetches the streams endpoint for each activity and emits `HeartRateSample` records with timestamps derived from the activity start + time offset stream. Expect many samples per activity.

## Token persistence

Identical pattern to Oura — see [`integrate-health-forge-oura`](../integrate-health-forge-oura/SKILL.md) step 5. Pass `initialToken` + `onTokenChanged` to persist across app launches.

## Gotchas

- **Unit-tested only** — no live API validation yet.
- **Client secret must be protected** — direct exchange embeds a recoverable secret. Prefer backend exchange for anything published.
- **Rate limits are dual** — 100 requests per 15 minutes AND 1000 per day. The adapter enforces both; if you hit them, requests are delayed.
- **kJ → kcal conversion** — Strava reports activity energy in kilojoules. The `CaloriesMapper` converts to kcal (÷ 4.184) automatically.
- **Scope** — the adapter requests `activity:read_all`. If the user authorized an earlier token with a narrower scope, calls will 401 until they reauthorize.
- **Read-only** — Strava's API supports uploads but the adapter doesn't wrap them.
- **Heart rate stream volume** — per-activity HR streams can produce thousands of samples. Consider caching via `forge.sync()` and reading from cache instead of querying live for long ranges.

## Related skills

- [`integrate-health-forge`](../integrate-health-forge/SKILL.md) — client setup (required)
- [`integrate-health-forge-core`](../integrate-health-forge-core/SKILL.md) — data model reference
- [`integrate-health-forge-oura`](../integrate-health-forge-oura/SKILL.md) — the other REST adapter; same OAuth pattern
- [`integrate-health-forge-apple`](../integrate-health-forge-apple/SKILL.md) — iOS workouts (can merge with Strava)
- [`integrate-health-forge-ghc`](../integrate-health-forge-ghc/SKILL.md) — Android workouts (can merge with Strava)
