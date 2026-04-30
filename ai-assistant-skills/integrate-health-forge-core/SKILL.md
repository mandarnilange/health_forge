---
name: integrate-health-forge-core
description: >
  Integrate `health_forge_core` (pure Dart) into a user's project — the unified
  health data model, provider interfaces, and conflict-resolution MergeEngine.
  Trigger when the user wants the data model or merge engine without Flutter
  (server-side Dart, CLI tools, isolates), or when implementing a custom
  `HealthProvider`. For Flutter apps that consume data from built-in adapters,
  prefer `integrate-health-forge` — it pulls this package in transitively.
---

# Integrate health_forge_core

`health_forge_core` is the pure-Dart foundation of Health Forge. No Flutter dependencies; safe to use in isolates, CLIs, and server-side Dart.

## When to use this package directly

- You are **not** using the `health_forge` Flutter client (e.g. pure Dart server, isolate worker, CLI).
- You are **implementing a custom `HealthProvider`** and only need the interfaces + data model.
- You want to run the `MergeEngine` on records you already have (e.g. imported JSON).

For Flutter apps that consume data from the official adapters (`health_forge_apple`, `health_forge_ghc`, `health_forge_oura`, `health_forge_strava`), use [`integrate-health-forge`](../integrate-health-forge/SKILL.md) instead — it includes the core transitively.

## Integration steps

### 1. Add dependency

```yaml
dependencies:
  health_forge_core: ^0.1.1
```

Run `dart pub get` (or `flutter pub get`).

### 2. Import

```dart
import 'package:health_forge_core/health_forge_core.dart';
```

One barrel file exports everything: enums, models, interfaces, merge engine.

### 3. Common usage patterns

**Construct a record manually:**

```dart
final sample = HeartRateSample(
  id: IdGenerator.uuid(),
  provider: DataProvider.apple,
  providerRecordType: 'HEART_RATE',
  startTime: DateTime.utc(2026, 4, 18, 9, 0),
  endTime: DateTime.utc(2026, 4, 18, 9, 0, 1),
  capturedAt: DateTime.now().toUtc(),
  beatsPerMinute: 68,
  freshness: Freshness.live,
);
```

**Merge records from multiple sources:**

```dart
final engine = MergeEngine(
  config: const MergeConfig(
    defaultStrategy: ConflictStrategy.priorityBased,
    providerPriority: [DataProvider.oura, DataProvider.apple],
    timeOverlapThresholdSeconds: 300,
  ),
);

final result = engine.merge(allRecords);
print('Resolved: ${result.records.length}');
print('Conflicts: ${result.conflictReport.conflicts.length}');
```

**Implement a custom provider:**

```dart
class MyProvider implements HealthProvider {
  @override
  DataProvider get providerType => DataProvider.garmin;

  @override
  String get displayName => 'My Custom Provider';

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
    supportedMetrics: {MetricType.heartRate: AccessMode.read},
    syncModel: SyncModel.fullWindow,
  );

  @override
  Future<AuthResult> authorize() async => AuthResult.success();

  @override
  Future<void> deauthorize() async {}

  @override
  Future<bool> isAuthorized() async => true;

  @override
  Future<List<HealthRecordMixin>> fetchRecords({
    required MetricType metricType,
    required TimeRange timeRange,
  }) async {
    // Call your API, convert to health_forge records, return.
    return const [];
  }
}
```

## Key types

| Type | Purpose |
|---|---|
| `HealthRecordMixin` | Envelope on every record (id, provider, timestamps, provenance, extensions) |
| `DataProvider` / `MetricType` | Enums identifying source and metric |
| `TimeRange` | start + end + timezone |
| `Provenance` | sourceDevice, sourceApp, dataOrigin |
| `HealthProvider` | Adapter interface |
| `ProviderCapabilities` | Declares which metrics a provider supports |
| `MergeEngine` + `MergeConfig` | Conflict resolution across providers |
| `DuplicateDetector` | Clusters overlapping records per `MetricType` |
| `ProviderExtension` | Base for provider-specific metric extensions (e.g. `OuraSleepExtension`) |

## Record families (21 record types)

| Family | Records |
|---|---|
| Activity | `ActivitySession`, `WorkoutRoute`, `StepCount`, `DistanceSample`, `CaloriesBurned`, `ElevationGain` |
| Cardiovascular | `HeartRateSample`, `RestingHeartRate`, `HeartRateVariability` |
| Sleep | `SleepSession`, `SleepStageSegment`, `SleepScore` |
| Recovery | `ReadinessScore`, `StressScore`, `RecoveryMetric` |
| Respiratory | `RespiratoryRate`, `BloodOxygenSample` |
| Body | `Weight`, `BodyFat`, `BloodPressure`, `BloodGlucose` |

All records are `@freezed` — immutable, with `copyWith`, `==`, and `toJson`/`fromJson`.

## Gotchas

- **No Flutter imports** — this package must stay isolate-safe. If you need `flutter_secure_storage`, token persistence, or platform channels, use `health_forge` instead.
- **IDs** — use `IdGenerator.uuid()` for internal UUIDs. `providerRecordId` is the native ID from the source API (keep separate).
- **Time zones** — prefer UTC for `startTime`/`endTime`. `TimeRange` carries an optional timezone name for display.
- **Extensions** — store via `Map<Type, ProviderExtension>` on records; deserialize with `ExtensionType.fromJson(record.extensions)`.

## Related skills

- [`integrate-health-forge`](../integrate-health-forge/SKILL.md) — Flutter client (most users want this)
- [`integrate-health-forge-apple`](../integrate-health-forge-apple/SKILL.md)
- [`integrate-health-forge-ghc`](../integrate-health-forge-ghc/SKILL.md)
- [`integrate-health-forge-oura`](../integrate-health-forge-oura/SKILL.md)
- [`integrate-health-forge-strava`](../integrate-health-forge-strava/SKILL.md)
