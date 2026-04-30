# Health Forge Example App

A Flutter demo app showcasing the health_forge package — multi-provider health data aggregation with conflict resolution.

## How It Works

```
┌──────────────┐
│  Example App │
└──────┬───────┘
       │ HealthForgeClient
       ▼
┌──────────────────────────────────────────────┐
│              Provider Registry                │
│  ┌────────┐ ┌────────┐ ┌──────┐ ┌────────┐  │
│  │ Apple  │ │  GHC   │ │ Oura │ │ Strava │  │
│  │HealthKit│ │ Health │ │ Ring │ │        │  │
│  │(real)  │ │Connect │ │(real │ │ (real  │  │
│  │        │ │(real)  │ │OAuth)│ │ OAuth) │  │
│  └───┬────┘ └───┬────┘ └──┬───┘ └───┬────┘  │
└──────┼──────────┼─────────┼─────────┼────────┘
       │          │         │         │
       ▼          ▼         ▼         ▼
   authorize → fetch records → merge → display
                                │
                            ┌───┴───┐
                            │ Cache │ (in-memory)
                            └───────┘
```

The app registers providers on startup (real on-device, mocks on desktop), authorizes them, then syncs/queries health data for display. See [docs/getting_started.md](../docs/getting_started.md) for the full architecture guide.

## What It Demonstrates

- **Multi-provider aggregation** — real Apple HealthKit/Google Health Connect + real Oura and Strava OAuth on mobile devices, mock providers on desktop/web
- **OAuth deep-link flow** — Oura (PKCE) and Strava (PKCE + client secret) via `url_launcher` + `app_links` with `healthforge://` custom URL scheme
- **Smart conflict resolution** — `keepAll` strategy for high-frequency metrics (HR, steps, calories, SpO2), default dedup for daily aggregates (sleep, readiness, weight)
- **Source-aware aggregation** — steps/calories/distance grouped by `(provider, sourceApp)` and max'd to avoid double-counting from iPhone + Apple Watch
- **10-metric dashboard** — steps, calories, distance, workouts, heart rate, resting HR, sleep, readiness, SpO2, weight
- **Record detail inspection** — tap any record in the browse screen to see all fields in a bottom sheet
- **Pull-to-refresh** — re-syncs from all providers with stale state cleared
- **Provider auth management** — connect/disconnect providers with local state tracking (works around iOS HealthKit's unreliable `hasPermissions`)

## Screens

### Dashboard
10 metric cards showing today's health summary. Data is synced from all authorized providers on load. Pull down to refresh.

| Row | Metrics |
|-----|---------|
| 1 | Steps (sum by source) · Calories (sum by source) |
| 2 | Distance (km) · Workouts (count) |
| 3 | Heart Rate (latest bpm) · Resting HR (latest bpm) |
| 4 | Sleep (duration) · Readiness (score /100) |
| 5 | SpO2 (latest %) · Weight (latest kg) |

### Providers
Lists all registered providers with connection status. Tap Connect/Disconnect to manage authorization. Apple Health auto-authorizes on startup.

### Browse
Select a metric type and date range to query records from all providers. Tap any record to open a bottom sheet with all data fields (ID, provider, timestamps, provenance, metric-specific values, extensions).

## OAuth Setup

The example uses real Oura and Strava OAuth on mobile. To enable:

1. **Oura**: Create an app at [Oura Developer Portal](https://cloud.ouraring.com/oauth/applications), set redirect URI to `healthforge://oura/callback`, then update `_ouraClientId` in `lib/main.dart`.

2. **Strava**: Create an app at [Strava API Settings](https://www.strava.com/settings/api), set redirect URI to `healthforge://strava/callback`, then update `_stravaClientId` and `_stravaClientSecret` in `lib/main.dart`.

The `healthforge://` URL scheme is already configured in `Info.plist` (iOS) and `AndroidManifest.xml` (Android).

## Running

```bash
cd example

# Desktop (mock providers, auto-authorized)
flutter run -d macos
flutter run -d linux
flutter run -d windows

# iOS Device (real Apple HealthKit + real Oura/Strava OAuth)
flutter run -d <device-id>

# Android Device (real Health Connect + real Oura/Strava OAuth)
flutter run -d <device-id>
```

## Platform Behavior

| Platform | Health Provider | Oura | Strava |
|----------|----------------|------|--------|
| iOS device | Real `AppleHealthProvider` (auto-auth) | Real OAuth | Real OAuth |
| Android device | Real `GhcHealthProvider` (auto-auth) | Real OAuth | Real OAuth |
| Desktop / Web | Mock Apple | Mock | Mock |

On real devices, Apple Health / Health Connect permissions are requested automatically on startup. Oura and Strava require manual connection via the Providers screen (opens browser for OAuth).

## Merge Strategy

The example configures per-metric conflict resolution:

| Strategy | Metrics | Reason |
|----------|---------|--------|
| `keepAll` | steps, heartRate, calories, distance, elevation, bloodOxygen, bloodGlucose, bloodPressure, hrv, restingHeartRate, respiratoryRate, workout | High-frequency samples from wearables (e.g. Apple Watch HR every ~5 min) would be incorrectly merged by the default 300s overlap threshold |
| `priorityBased` (default) | sleepSession, sleepScore, readiness, stress, weight, bodyFat, recovery | Daily aggregates where cross-provider dedup is desired |

## Project Structure

```
example/
├── lib/
│   ├── main.dart                    # Entry point, provider setup, merge config
│   ├── oauth_helper.dart            # Bridges url_launcher + app_links for OAuth
│   ├── mock/
│   │   ├── mock_apple_provider.dart
│   │   ├── mock_oura_provider.dart
│   │   ├── mock_strava_provider.dart
│   │   └── mock_data_generator.dart # Generates realistic fake health data
│   ├── screens/
│   │   ├── home_screen.dart         # 10-metric dashboard with pull-to-refresh
│   │   ├── provider_status_screen.dart  # Provider auth management
│   │   └── data_browser_screen.dart     # Query by metric + date range + detail sheet
│   └── widgets/
│       ├── metric_card.dart         # Summary card for a single metric
│       ├── provider_status_tile.dart # Provider row with auth badge
│       └── record_list_item.dart    # Record display with tap callback
├── test/
│   └── widget_test.dart             # Smoke tests for navigation
├── ios/
│   └── Runner/
│       ├── Info.plist               # HealthKit descriptions + healthforge:// scheme
│       └── Runner.entitlements      # HealthKit capability
└── android/
    └── app/src/main/
        └── AndroidManifest.xml      # Health Connect permissions + deep link intent
```

## Tests

```bash
cd example && flutter test
```

4 widget smoke tests verify the app launches, navigates between screens, and displays all provider names.
