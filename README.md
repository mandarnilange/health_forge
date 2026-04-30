# Health Forge

[![CI](https://img.shields.io/github/actions/workflow/status/mandarnilange/health_forge_workspace/ci.yaml?branch=main&label=CI)](https://github.com/mandarnilange/health_forge_workspace/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.6.0-0175C2.svg)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/flutter-%3E%3D3.27.0-02569B.svg)](https://flutter.dev)
[![style: very_good_analysis](https://img.shields.io/badge/style-very__good__analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg)](https://github.com/invertase/melos)

A federated, zero-backend Flutter toolkit for aggregating health data from multiple providers into a unified data model — without losing provider-specific metrics.

## Why Health Forge?

The Flutter health ecosystem is fragmented:

| Approach | Problem |
|----------|---------|
| `health` package | Strips provider-specific metrics (Oura readiness, Strava suffer score) |
| Individual provider wrappers | Inconsistent APIs, incomplete coverage, some GPL-licensed |
| Commercial SDKs | Vendor lock-in, backend required, closed source |

**Health Forge** solves this with a unified model that preserves every metric, a built-in conflict resolution engine for multi-source data, and a federated architecture where you only depend on the providers you use.

## Features

- **Unified data model** — 21 record types across 6 families (activity, cardiovascular, sleep, recovery, respiratory, body)
- **Provider-specific extensions** — type-safe access to Oura readiness scores, Strava suffer scores, Garmin body battery, etc.
- **Conflict resolution engine** — 5 strategies for deduplicating and merging overlapping records from multiple providers
- **Pure Dart core** — isolate-safe, zero Flutter dependencies in the core package
- **Federated architecture** — only pull the provider packages you need
- **MIT licensed** — no GPL contamination

## Packages

| Package | Version | Description | Status |
|---------|---------|-------------|--------|
| [`health_forge_core`](https://pub.dev/packages/health_forge_core) | [![pub](https://img.shields.io/pub/v/health_forge_core.svg)](https://pub.dev/packages/health_forge_core) | Models, enums, interfaces, merge engine (pure Dart) | Available |
| [`health_forge`](https://pub.dev/packages/health_forge) | [![pub](https://img.shields.io/pub/v/health_forge.svg)](https://pub.dev/packages/health_forge) | Flutter client: registry, auth, queries, cache | Available |
| [`health_forge_apple`](https://pub.dev/packages/health_forge_apple) | [![pub](https://img.shields.io/pub/v/health_forge_apple.svg)](https://pub.dev/packages/health_forge_apple) | Apple HealthKit adapter (14 metric types) | Available |
| [`health_forge_ghc`](https://pub.dev/packages/health_forge_ghc) | [![pub](https://img.shields.io/pub/v/health_forge_ghc.svg)](https://pub.dev/packages/health_forge_ghc) | Google Health Connect adapter (14 metric types) | Available |
| [`health_forge_oura`](https://pub.dev/packages/health_forge_oura) | [![pub](https://img.shields.io/pub/v/health_forge_oura.svg)](https://pub.dev/packages/health_forge_oura) | Oura Ring REST API adapter (8 metric types) | Available (not yet tested end-to-end) |
| [`health_forge_strava`](https://pub.dev/packages/health_forge_strava) | [![pub](https://img.shields.io/pub/v/health_forge_strava.svg)](https://pub.dev/packages/health_forge_strava) | Strava REST API adapter (5 metric types) | Available (not yet tested end-to-end) |
| `health_forge_garmin` | — | Garmin adapter | Planned (next) |

## Quick Start

> For a comprehensive guide covering platform setup, OAuth configuration, provider-specific extensions, and conflict resolution — see **[docs/getting_started.md](docs/getting_started.md)**.
>
> **Note:** Health Forge is in active development. The core data model, Flutter client, and Apple/GHC adapters are functional and device-tested. The Oura and Strava adapters are code-complete with full unit test coverage but have **not yet been tested end-to-end against live APIs**. Garmin adapter is planned.

### Installation

Add only the packages you need:

```yaml
dependencies:
  health_forge: ^0.1.0
  health_forge_apple: ^0.1.0   # iOS — HealthKit
  health_forge_ghc: ^0.1.0     # Android — Health Connect
  health_forge_oura: ^0.1.0    # Oura Ring — REST API
  health_forge_strava: ^0.1.0  # Strava — REST API
```

### Usage

```dart
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_apple/health_forge_apple.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';

final forge = HealthForgeClient();

// Register providers
forge.use(AppleHealthProvider());
forge.use(GhcHealthProvider());

// Authorize all registered providers
final authResults = await forge.auth.authorizeAll();

// Build and execute a query
final builder = forge.query()
  ..forMetrics([MetricType.heartRate, MetricType.sleepSession])
  ..inRange(TimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  ));

final executor = QueryExecutor(
  registry: forge.registry,
  mergeEngine: MergeEngine(config: const MergeConfig()),
);
final result = await executor.execute(builder.build());

// Access unified records
for (final record in result.records) {
  print('${record.provider}: ${record.providerRecordType}');
}

// Sync data to local cache
await forge.sync(
  provider: DataProvider.apple,
  metric: MetricType.heartRate,
  range: TimeRange(
    start: DateTime.now().subtract(const Duration(days: 1)),
    end: DateTime.now(),
  ),
);
```

## Data Model

### Record Families

| Family | Records |
|--------|---------|
| **Activity** | ActivitySession, WorkoutRoute, StepCount, DistanceSample, CaloriesBurned, ElevationGain |
| **Cardiovascular** | HeartRateSample, RestingHeartRate, HeartRateVariability |
| **Sleep** | SleepSession, SleepStageSegment, SleepScore |
| **Recovery** | ReadinessScore, StressScore, RecoveryMetric |
| **Respiratory** | RespiratoryRate, BloodOxygenSample |
| **Body** | Weight, BodyFat, BloodPressure, BloodGlucose |

Every record implements `HealthRecordMixin`, providing a consistent envelope with provider, timestamps, provenance, and type-safe extension slots.

### Conflict Resolution

When multiple providers report overlapping data (e.g., Apple Watch and Oura both tracking sleep), Health Forge's merge engine groups likely duplicates by **metric type** and **time overlap** (configurable threshold), then resolves each group using configurable strategies:

| Strategy | Behavior |
|----------|----------|
| **Priority-based** | Pick from the highest-priority provider per metric |
| **Keep all** | Preserve all records with attribution and conflict report |
| **Average** | Average numeric values across providers |
| **Most granular** | Keep the record with highest temporal resolution |
| **Custom** | Your own resolution callback |

## Architecture

```
health_forge_core (pure Dart)
    ├── enums/          7 enum types
    ├── models/         21 record types + envelope
    ├── interfaces/     HealthProvider, ProviderCapabilities
    └── merge/          MergeEngine + 5 strategies

health_forge (Flutter)
    ├── HealthForgeClient      main entry point
    ├── ProviderRegistry       register/discover providers
    ├── AuthOrchestrator       authorize/deauthorize flows
    ├── QueryBuilder/Executor  fluent query API
    ├── CacheManager           InMemory or DriftCacheManager (SQLite)
    ├── SyncManager            sync coordination + dedup
    └── TokenStore             secure OAuth token persistence

health_forge_apple / health_forge_ghc
    ├── {Provider}HealthProvider   implements HealthProvider
    ├── {Provider}Capabilities     14 supported metrics
    ├── HealthDataRecord           platform-agnostic DTO
    └── mappers/                   5 mapper classes per provider

health_forge_oura (REST API adapter)
    ├── OuraHealthProvider         implements HealthProvider (8 metrics)
    ├── auth/                      OAuth 2.0 PKCE + token management
    ├── api/                       Dio client + rate limiter + pagination
    ├── models/                    7 response DTOs
    └── mappers/                   7 mapper classes

health_forge_strava (REST API adapter)
    ├── StravaHealthProvider       implements HealthProvider (5 metrics)
    ├── auth/                      OAuth 2.0 PKCE + client_secret
    ├── api/                       Dio client + dual rate limiter + page pagination
    ├── models/                    3 response DTOs (bare array support)
    └── mappers/                   5 mapper classes (kJ→kcal, streams→HR)

example/ (Flutter demo app)
    ├── Real OAuth                 Oura PKCE + Strava OAuth via deep links
    ├── Mock providers             Apple + Oura + Strava with fake data (desktop)
    ├── Dashboard                  10 metric cards with source-aware aggregation
    ├── Provider Status            Auth management with local state tracking
    └── Data Browser               Query by MetricType + date range + detail sheet
```

See `design/adr/` for architectural decision records.

## Development

### Prerequisites

- Dart SDK >= 3.6.0
- Flutter >= 3.27.0 (for Flutter packages)
- Melos (`dart pub global activate melos`)

### Setup

```bash
git clone https://github.com/mandarnilange/health_forge_workspace.git
cd health_forge_workspace
dart pub get
dart run melos bootstrap
```

### Common Commands

```bash
dart run melos run analyze    # Lint all packages (zero warnings required)
dart run melos run test       # Run all tests
dart run melos run test:coverage   # Packages only; writes coverage/lcov.info per package (example excluded)
dart run melos run coverage:verify # ≥90% line coverage per packages/* (same excludes as CI; example not gated)
bash tool/merge_lcov.sh      # Requires `lcov` on PATH; merges package lcov into coverage/lcov.info
dart run melos run format     # Check formatting
dart run melos run generate   # Run code generation (freezed, json_serializable)
```

### Contributing

- Follow TDD: write a failing test before implementing
- Run `dart run melos run analyze` — zero warnings required
- CI requires **≥90% line coverage per package** under `packages/` (after excluding `*.g.dart` / `*.freezed.dart` / `*.part.dart`, and the declarative Drift schema file `health_cache_database.dart` in `health_forge`). The **example** app is not included in that gate; run `cd example && flutter test` separately. Use `dart run melos run coverage:verify` locally (optional: `COVERAGE_MIN_PERCENT=85`).
- Architecture changes need an ADR in `design/adr/`
- No Flutter imports in `health_forge_core`
- No GPL dependencies

## License

MIT — see [LICENSE](LICENSE).
