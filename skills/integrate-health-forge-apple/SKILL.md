---
name: integrate-health-forge-apple
description: >
  Integrate `health_forge_apple` — the Apple HealthKit adapter — into a
  user's Flutter app. Trigger when the user wants to read HealthKit data on
  iOS (steps, heart rate, sleep stages, workouts, body metrics, SpO2, etc.).
  Requires the `health_forge` Flutter client — see related skill
  `integrate-health-forge` for client setup and the pure-Dart foundation
  `integrate-health-forge-core`.
license: MIT
metadata:
  author: Health Forge
  version: "0.1.1"
---

# Integrate health_forge_apple

Read Apple HealthKit data on iOS. 14 read-only metric types, mapped to the unified `health_forge_core` model.

**Prerequisite:** This adapter plugs into the `health_forge` Flutter client. Follow [`integrate-health-forge`](../integrate-health-forge/SKILL.md) for client + cache setup first.

## Supported metrics (14)

| Family | Metrics |
|---|---|
| Activity | `steps`, `caloriesBurned`, `distanceSample`, `activitySession` (workouts) |
| Cardiovascular | `heartRateSample`, `heartRateVariability`, `restingHeartRate` |
| Sleep | `sleepSession` with `SleepStageSegment`s (6 HealthKit stage types aggregated + deduplicated into one session per night) |
| Body | `weight`, `bodyFat`, `bloodPressure`, `bloodGlucose` |
| Respiratory | `bloodOxygen`, `respiratoryRate` |

## Integration steps

### 1. Add dependency

```yaml
dependencies:
  health_forge: ^0.1.1
  health_forge_apple: ^0.1.1
```

### 2. iOS — entitlements

Create or edit `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
    <key>com.apple.developer.healthkit.access</key>
    <array/>
</dict>
</plist>
```

### 3. iOS — Info.plist usage descriptions

Edit `ios/Runner/Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app reads your health data to show fitness and wellness metrics.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>This app writes health data to keep your records in sync.</string>
```

(`NSHealthUpdateUsageDescription` is required even though this adapter is read-only — Apple rejects apps that link HealthKit without it.)

### 4. iOS — enable HealthKit capability in Xcode

Open `ios/Runner.xcworkspace` → select the **Runner** target → **Signing & Capabilities** → click **+ Capability** → add **HealthKit**. Commit the resulting project/entitlements changes.

### 5. Register the provider

Gate on platform to avoid crashes on Android/desktop/web:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_apple/health_forge_apple.dart';

final forge = HealthForgeClient();

if (!kIsWeb && Platform.isIOS) {
  forge.use(AppleHealthProvider());
}
```

### 6. Authorize

```dart
final result = await forge.auth.authorize(DataProvider.apple);
if (!result.isSuccess) {
  // User denied or prompt was skipped — tell the user to grant access
  // in Settings → Privacy & Security → Health → [Your App].
  return;
}
```

### 7. Fetch data

```dart
final records = await forge.registry
    .getProvider(DataProvider.apple)!
    .fetchRecords(
      metricType: MetricType.heartRate,
      timeRange: TimeRange(
        start: DateTime.now().subtract(const Duration(days: 1)),
        end: DateTime.now(),
      ),
    );

for (final record in records) {
  if (record is HeartRateSample) {
    print('${record.beatsPerMinute} bpm @ ${record.startTime}');
    print('Source: ${record.provenance?.sourceDevice?.model}');
  }
}
```

Or use the client's query API — see [`integrate-health-forge`](../integrate-health-forge/SKILL.md) step 5.

## Provenance

HealthKit records include rich source metadata — the adapter populates:

```dart
record.provider                         // DataProvider.apple
record.providerRecordId                 // HealthKit UUID
record.provenance?.dataOrigin           // DataOrigin.native_
record.provenance?.sourceDevice?.model  // e.g. "Apple Watch Series 9"
record.provenance?.sourceApp            // Bundle ID, e.g. "com.apple.health"
```

Use `sourceApp` to deduplicate across iPhone vs. Apple Watch when both log the same metric (e.g. steps). A common pattern is to group by `(provider, sourceApp)` before summing.

## Gotchas

- **`hasPermissions` is unreliable on iOS** — after a successful `authorize()`, track auth state locally rather than polling `isAuthorized()`. iOS intentionally doesn't reveal denied read permissions.
- **Write permissions — not supported** yet. All Apple adapter metrics are read-only.
- **Sleep sessions** — HealthKit returns 6 individual stage samples (awake, core, deep, REM, inBed, asleep) with time-interval-encoded durations. The adapter aggregates and deduplicates these into one `SleepSession` per night with `SleepStageSegment`s. Your code sees one session, not six raw samples.
- **High-frequency metrics** (steps, HR) — Apple Watch writes samples every ~5 minutes. With the default merge config, records from iPhone + Watch that fall within 5 minutes will be collapsed. If you want every sample, set `ConflictStrategy.keepAll` for those metrics in `MergeConfig.perMetricStrategy`.
- **Simulator** — HealthKit works in the iOS Simulator but there's no seed data by default. Use "Simulator → Device → Trigger iCloud Sync" or write sample data manually via the Health app on the simulator.

## Related skills

- [`integrate-health-forge`](../integrate-health-forge/SKILL.md) — client setup (required)
- [`integrate-health-forge-core`](../integrate-health-forge-core/SKILL.md) — data model reference
- [`integrate-health-forge-ghc`](../integrate-health-forge-ghc/SKILL.md) — Android counterpart
- [`integrate-health-forge-oura`](../integrate-health-forge-oura/SKILL.md) — cross-platform Oura data
- [`integrate-health-forge-strava`](../integrate-health-forge-strava/SKILL.md) — cross-platform Strava data
