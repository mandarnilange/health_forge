---
name: integrate-health-forge-oura
description: >
  Integrate `health_forge_oura` — the Oura Ring REST API adapter — into a
  user's Flutter app. Trigger when the user wants to read Oura data (sleep,
  readiness, stress, heart rate, activity, SpO2) via OAuth 2.0 PKCE.
  Requires the `health_forge` Flutter client — see related skill
  `integrate-health-forge` for client setup.
  Note: This adapter is code-complete with unit tests but has not yet been
  validated end-to-end against the live Oura API.
---

# Integrate health_forge_oura

Read Oura Ring data via REST API. 8 read-only metrics, OAuth 2.0 PKCE auth, automatic pagination and rate limiting.

**Prerequisite:** This adapter plugs into the `health_forge` Flutter client. Follow [`integrate-health-forge`](../integrate-health-forge/SKILL.md) for client + cache setup first.

> ⚠️ **Not yet validated against the live Oura API.** Unit tests pass; expect minor integration work the first time it's wired against a real developer account.

## Supported metrics (8)

| Family | Metrics |
|---|---|
| Sleep | `sleepSession` (with `OuraSleepExtension`: readiness contributor, temperature deviation, hypnogram), `sleepScore` |
| Cardiovascular | `heartRateSample` |
| Activity | `steps`, `caloriesBurned` |
| Recovery | `readinessScore`, `stressScore` |
| Respiratory | `bloodOxygen` |

## Integration steps

### 1. Register an Oura app

Go to [cloud.ouraring.com/oauth/applications](https://cloud.ouraring.com/oauth/applications) and create an app.

- **Client ID** — copy this (no secret needed; PKCE-only)
- **Redirect URI** — pick a custom scheme, e.g. `com.yourapp://oura-callback` or `healthforge://oura/callback`

### 2. Configure deep links

**iOS** — edit `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.yourapp</string>
    </array>
  </dict>
</array>
```

**Android** — edit `android/app/src/main/AndroidManifest.xml`, add inside the main `<activity>`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="com.yourapp" android:host="oura-callback"/>
</intent-filter>
```

### 3. Add dependencies

```yaml
dependencies:
  health_forge: ^0.1.1
  health_forge_oura: ^0.1.1
  url_launcher: ^6.2.0   # to launch the OAuth URL
  app_links: ^6.0.0      # to capture the redirect
  flutter_secure_storage: ^9.0.0  # for token persistence
```

### 4. Implement the URL launcher callback

The adapter doesn't ship a UI — you open the OAuth URL and await the redirect:

```dart
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

Future<Uri?> launchAndWaitForRedirect(Uri authUrl) async {
  final appLinks = AppLinks();
  final future = appLinks.uriLinkStream
      .firstWhere((uri) => uri.scheme == 'com.yourapp');

  await launchUrl(authUrl, mode: LaunchMode.externalApplication);

  return future.timeout(
    const Duration(minutes: 5),
    onTimeout: () => null,  // user cancelled
  );
}
```

### 5. Wire up the auth manager + provider

```dart
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_oura/health_forge_oura.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStore = TokenStore(const FlutterSecureStorage());

Future<OuraHealthProvider> buildOuraProvider() async {
  // Restore persisted token (if any)
  final savedJson = await tokenStore.load(DataProvider.oura);
  final initialToken = savedJson != null
      ? OuraToken.fromJson(jsonDecode(savedJson) as Map<String, dynamic>)
      : null;

  final ouraAuth = OuraAuthManager(
    clientId: 'YOUR_OURA_CLIENT_ID',
    redirectUri: 'com.yourapp://oura-callback',
    urlLauncher: launchAndWaitForRedirect,
    initialToken: initialToken,
    onTokenChanged: (token) async {
      if (token != null) {
        await tokenStore.save(DataProvider.oura, jsonEncode(token.toJson()));
      } else {
        await tokenStore.delete(DataProvider.oura);
      }
    },
  );

  final ouraApi = OuraApiClient(authManager: ouraAuth);
  return OuraHealthProvider(authManager: ouraAuth, apiClient: ouraApi);
}

// Register with the client
forge.use(await buildOuraProvider());
```

### 6. Authorize

```dart
final result = await forge.auth.authorize(DataProvider.oura);
if (!result.isSuccess) {
  // User cancelled, timed out, or Oura rejected the exchange.
  return;
}
```

This launches the browser, the user grants access, and the redirect completes authorization.

### 7. Fetch data

```dart
final records = await forge.registry
    .getProvider(DataProvider.oura)!
    .fetchRecords(
      metricType: MetricType.readinessScore,
      timeRange: TimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

for (final record in records) {
  if (record is ReadinessScore) {
    print('${record.startTime}: ${record.score}');
  }
}
```

### 8. Read the Oura sleep extension

Sleep sessions carry Oura-specific fields:

```dart
final sleep = records.firstWhere((r) => r is SleepSession) as SleepSession;
final ext = OuraSleepExtension.fromJson(sleep.extensions);

print('Readiness contributor: ${ext.readinessContributorSleep}');
print('Temperature deviation: ${ext.temperatureDeviation}');
// The hypnogram is already parsed into sleep.stages as SleepStageSegments.
```

## Token refresh

The adapter auto-refreshes expired tokens on the next API call. To refresh manually:

```dart
final current = ouraAuth.currentToken;
if (current != null && current.isExpired) {
  await ouraAuth.refreshToken(current);
}
```

`onTokenChanged` fires after every refresh — persist the new token.

## Gotchas

- **Unit-tested only** — no live API validation yet. Expect small surprises (field names, date handling) on first run.
- **Rate limits** — the API client enforces 5 req/sec internally. For heavy pulls, break into smaller time windows.
- **Pagination** — handled automatically via `next_token`. Don't paginate yourself.
- **Token persistence is opt-in** — without `initialToken` + `onTokenChanged`, the user re-authorizes every app launch.
- **Time zones** — Oura reports daily summaries in the user's ring time zone. Stored records use UTC times plus the timezone string in `TimeRange` for display.
- **Read-only** — Oura's API doesn't expose write endpoints.

## Related skills

- [`integrate-health-forge`](../integrate-health-forge/SKILL.md) — client setup (required)
- [`integrate-health-forge-core`](../integrate-health-forge-core/SKILL.md) — data model reference
- [`integrate-health-forge-strava`](../integrate-health-forge-strava/SKILL.md) — the other REST adapter; same OAuth pattern
- [`integrate-health-forge-apple`](../integrate-health-forge-apple/SKILL.md) — iOS HealthKit (can merge with Oura sleep/HR)
- [`integrate-health-forge-ghc`](../integrate-health-forge-ghc/SKILL.md) — Android Health Connect
