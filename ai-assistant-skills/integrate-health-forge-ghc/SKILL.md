---
name: integrate-health-forge-ghc
description: >
  Integrate `health_forge_ghc` — the Google Health Connect adapter — into a
  user's Flutter app. Trigger when the user wants to read Health Connect
  data on Android (steps, heart rate, sleep stages, workouts, body metrics,
  SpO2, etc.). Requires the `health_forge` Flutter client — see related
  skill `integrate-health-forge` for client setup and
  `integrate-health-forge-core` for the pure-Dart foundation.
---

# Integrate health_forge_ghc

Read Google Health Connect data on Android. 14 read-only metric types, mapped to the unified `health_forge_core` model.

**Prerequisite:** This adapter plugs into the `health_forge` Flutter client. Follow [`integrate-health-forge`](../integrate-health-forge/SKILL.md) for client + cache setup first.

## Supported metrics (14)

| Family | Metrics |
|---|---|
| Activity | `steps`, `caloriesBurned`, `distanceSample`, `activitySession` (workouts) |
| Cardiovascular | `heartRateSample`, `heartRateVariability`, `restingHeartRate` |
| Sleep | `sleepSession` with `SleepStageSegment`s (5 Health Connect stage types aggregated + deduplicated into one session per night) |
| Body | `weight`, `bodyFat`, `bloodPressure`, `bloodGlucose` |
| Respiratory | `bloodOxygen`, `respiratoryRate` |

## Integration steps

### 1. Add dependency

```yaml
dependencies:
  health_forge: ^0.1.0
  health_forge_ghc: ^0.1.0
```

### 2. Android — permissions

Edit `android/app/src/main/AndroidManifest.xml` — add inside `<manifest>`, **before** `<application>`:

```xml
<uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
<uses-permission android:name="android.permission.health.READ_HEART_RATE_VARIABILITY"/>
<uses-permission android:name="android.permission.health.READ_RESTING_HEART_RATE"/>
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_SLEEP"/>
<uses-permission android:name="android.permission.health.READ_EXERCISE"/>
<uses-permission android:name="android.permission.health.READ_DISTANCE"/>
<uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED"/>
<uses-permission android:name="android.permission.health.READ_WEIGHT"/>
<uses-permission android:name="android.permission.health.READ_BODY_FAT"/>
<uses-permission android:name="android.permission.health.READ_BLOOD_PRESSURE"/>
<uses-permission android:name="android.permission.health.READ_BLOOD_GLUCOSE"/>
<uses-permission android:name="android.permission.health.READ_OXYGEN_SATURATION"/>
<uses-permission android:name="android.permission.health.READ_RESPIRATORY_RATE"/>
```

Only include permissions for metrics you'll actually read — users are shown this list.

### 3. Android — Health Connect availability

Health Connect ships pre-installed on Android 14+. On Android 13, the user must install the [Health Connect app](https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata) from Play Store. Gracefully handle the unavailable case — your `authorize()` call will return a failure result if Health Connect is missing.

### 4. Register the provider

Gate on platform:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';

final forge = HealthForgeClient();

if (!kIsWeb && Platform.isAndroid) {
  forge.use(GhcHealthProvider());
}
```

### 5. Authorize

```dart
final result = await forge.auth.authorize(DataProvider.googleHealthConnect);
if (!result.isSuccess) {
  // User denied, Health Connect not installed, or permissions screen skipped.
  // Send the user to the Health Connect app to review permissions.
  return;
}
```

### 6. Fetch data

```dart
final records = await forge.registry
    .getProvider(DataProvider.googleHealthConnect)!
    .fetchRecords(
      metricType: MetricType.sleepSession,
      timeRange: TimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

for (final record in records) {
  if (record is SleepSession) {
    print('${record.totalSleepMinutes} min sleep on ${record.startTime}');
    for (final stage in record.stages) {
      print('  ${stage.stage}: ${stage.durationMinutes} min');
    }
  }
}
```

Or use the client's query API — see [`integrate-health-forge`](../integrate-health-forge/SKILL.md) step 5.

## Provenance

Health Connect records include source metadata — the adapter populates:

```dart
record.provider                         // DataProvider.googleHealthConnect
record.providerRecordId                 // Health Connect record ID
record.provenance?.dataOrigin           // DataOrigin.native_
record.provenance?.sourceDevice?.model  // Device (when reported)
record.provenance?.sourceApp            // Package name, e.g. "com.samsung.android.shealth"
```

## Gotchas

- **Android 13 split** — Health Connect is not guaranteed available. On Android 14+ it's pre-installed; on Android 13 users must install it. Detect via the adapter's `authorize()` return value.
- **Write permissions — not supported** yet. All GHC adapter metrics are read-only.
- **Sleep sessions** — Health Connect returns individual stage records (awake, light, deep, REM, out-of-bed) with minute durations. The adapter aggregates and deduplicates these into one `SleepSession` per night with `SleepStageSegment`s.
- **Permissions UI** — Health Connect shows users a single system permissions screen. If they decline everything, `authorize()` returns failure; individual permissions aren't visible to the app.
- **MinSdkVersion** — Health Connect requires `minSdkVersion 28` (Android 9). Set this in `android/app/build.gradle`.
- **High-frequency metrics** (steps, HR) — if the user has both a phone and a watch reporting to Health Connect, expect overlap. Use `ConflictStrategy.keepAll` per-metric in `MergeConfig` if you want every sample preserved.

## Related skills

- [`integrate-health-forge`](../integrate-health-forge/SKILL.md) — client setup (required)
- [`integrate-health-forge-core`](../integrate-health-forge-core/SKILL.md) — data model reference
- [`integrate-health-forge-apple`](../integrate-health-forge-apple/SKILL.md) — iOS counterpart
- [`integrate-health-forge-oura`](../integrate-health-forge-oura/SKILL.md) — cross-platform Oura data
- [`integrate-health-forge-strava`](../integrate-health-forge-strava/SKILL.md) — cross-platform Strava data
