# 0005. Type-Safe Provider Extensions via Type Map

**Status:** Accepted
**Date:** 2026-03-17

## Context

Each health data provider offers unique metrics not in the normalized schema — Oura has a Readiness Score, Garmin has Body Battery, Strava has Suffer Score. These provider-specific values must be preserved without polluting the core record types with provider-specific fields. Extensions must survive JSON serialization for caching and isolate transfer.

## Decision

Implement a type-map-based extension mechanism:

### Extension Storage

Each health record carries `Map<Type, ProviderExtension> extensions`, where:

- **`ProviderExtension`** is an abstract class requiring:
  - `Map<String, dynamic> toJson()` — serialization
  - `String get typeKey` — unique string identifier for deserialization dispatch

### Typed Retrieval

Type-safe access via generic method:

```dart
T? extension<T extends ProviderExtension>() => extensions[T] as T?;
```

Usage: `record.extension<OuraSleepExtension>()` returns `OuraSleepExtension?`

### Serialization

- **`ProviderExtensionRegistry`** maps `typeKey` strings to factory functions: `Map<String, ProviderExtension Function(Map<String, dynamic>)>`
- Each provider package registers its extensions at initialization (e.g., in `HealthForgeOura.init()`)
- JSON format: `{"typeKey": "oura_sleep", ...extensionFields}`

### Known Extensions

- **`OuraSleepExtension`** — readinessScore, temperatureDeviation, restingHeartRate
- **`StravaWorkoutExtension`** — sufferScore, segmentEfforts, weightedAveragePower
- **`GarminSleepExtension`** — bodyBatteryChange, stressQualifier, respirationRate

## Consequences

### Positive

- Provider-specific metrics preserved without core schema changes
- Type-safe retrieval with compile-time checking of extension types
- Serialization-friendly for caching and isolate transfer
- Extensible by third parties — any package can define and register extensions
- Core remains agnostic to provider-specific data

### Negative

- Runtime type checking (`Map<Type, ...>`) — no compile-time guarantee that extensions are present
- Extension registry requires manual registration at app startup; missing registration causes silent deserialization failures
- Unknown extensions are silently dropped during deserialization — could lose data if registry is incomplete
- Extensions are not included in record equality checks by default — two records with different extensions may appear equal
- Type keys must be globally unique across all providers; no namespace enforcement beyond convention
