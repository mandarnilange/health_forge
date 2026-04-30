# Getting Started with Health Forge

Health Forge is a federated Flutter toolkit that aggregates health data from multiple providers (Apple HealthKit, Google Health Connect, Oura Ring, Strava) into a unified data model — preserving provider-specific metrics like Oura readiness scores and Strava suffer scores.

## Table of Contents

- [How It Works](#how-it-works)
- [Installation](#installation)
- [Platform Setup](#platform-setup)
  - [iOS (HealthKit)](#ios-healthkit)
  - [Android (Health Connect)](#android-health-connect)
  - [Oura Ring](#oura-ring)
  - [Strava](#strava)
- [Basic Usage](#basic-usage)
  - [Create a Client](#create-a-client)
  - [Register Providers](#register-providers)
  - [Authorize](#authorize)
  - [Query Data](#query-data)
  - [Sync to Cache](#sync-to-cache)
- [Supported Metrics](#supported-metrics)
- [Provider-Specific Extensions](#provider-specific-extensions)
  - [Oura Sleep Extension](#oura-sleep-extension)
  - [Strava Workout Extension](#strava-workout-extension)
- [Conflict Resolution](#conflict-resolution)
  - [Strategies](#strategies)
  - [Custom Configuration](#custom-configuration)
- [Platform Detection](#platform-detection)
- [Running the Example App](#running-the-example-app)

---

## How It Works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Flutter App                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    HealthForgeClient                        │
│                                                             │
│  ┌─────────────┐  ┌──────────┐  ┌────────┐  ┌───────────┐ │
│  │  Registry    │  │   Auth   │  │ Query  │  │   Sync    │ │
│  │  .use()      │  │  .auth   │  │ .query │  │  .sync()  │ │
│  └──────┬──────┘  └────┬─────┘  └───┬────┘  └─────┬─────┘ │
└─────────┼──────────────┼────────────┼──────────────┼───────┘
          │              │            │              │
          ▼              ▼            ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Provider Registry                         │
│                                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  Apple   │ │   GHC    │ │   Oura   │ │  Strava  │      │
│  │ HealthKit│ │  Health  │ │  Ring    │ │          │      │
│  │          │ │ Connect  │ │ REST API │ │ REST API │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow: Two Ways to Get Data

There are two paths to retrieve health data — **Query** (on-demand) and **Sync** (fetch + cache).

#### Path 1: Query (Direct Fetch)

Fetches data live from providers, optionally merges overlapping records, and returns results. Nothing is cached.

```
  App                    QueryExecutor            Providers
   │                          │                      │
   │  forge.query()           │                      │
   │  ..forMetric(heartRate)  │                      │
   │  ..from(apple)           │                      │
   │  ..inRange(lastWeek)     │                      │
   │                          │                      │
   │  executor.execute(query) │                      │
   │ ─────────────────────────>                      │
   │                          │  fetchRecords()      │
   │                          │ ─────────────────────>
   │                          │                      │
   │                          │  [HeartRateSample,   │
   │                          │   HeartRateSample,   │
   │                          │   ...]               │
   │                          │ <─────────────────────
   │                          │                      │
   │                          │  ┌────────────────┐  │
   │                          │  │  MergeEngine   │  │
   │                          │  │  (if multiple  │  │
   │                          │  │   providers)   │  │
   │                          │  └────────────────┘  │
   │                          │                      │
   │  QueryResult             │                      │
   │  .records                │                      │
   │  .mergeResult            │                      │
   │  .errors                 │                      │
   │ <─────────────────────────                      │
```

**When to use:** One-off data fetches, real-time displays, when you don't need offline access.

#### Path 2: Sync (Fetch + Merge + Cache)

Fetches data from a provider, merges it with existing cached records (deduplicating across providers), stores the result in the local cache, and tracks sync metadata.

```
  App                     SyncManager           Provider       Cache
   │                          │                    │              │
   │  forge.sync(             │                    │              │
   │    provider: apple,      │                    │              │
   │    metric: heartRate,    │                    │              │
   │    range: lastDay)       │                    │              │
   │ ─────────────────────────>                    │              │
   │                          │                    │              │
   │                          │  fetchRecords()    │              │
   │                          │ ───────────────────>              │
   │                          │  [new records]     │              │
   │                          │ <───────────────────              │
   │                          │                    │              │
   │                          │  cache.get()       │              │
   │                          │ ──────────────────────────────────>
   │                          │  [existing records]│              │
   │                          │ <──────────────────────────────────
   │                          │                    │              │
   │                          │  ┌────────────────┐│              │
   │                          │  │  MergeEngine   ││              │
   │                          │  │  deduplicate   ││              │
   │                          │  │  new+existing  ││              │
   │                          │  └────────────────┘│              │
   │                          │                    │              │
   │                          │  cache.put()       │              │
   │                          │ ──────────────────────────────────>
   │                          │  update metadata   │              │
   │                          │ ──────────────────────────────────>
   │                          │                    │              │
   │  SyncResult              │                    │              │
   │  .recordsFetched         │                    │              │
   │  .recordsCached          │                    │              │
   │  .duplicatesDetected     │                    │              │
   │ <─────────────────────────                    │              │
   │                          │                    │              │
   │  // Later: read from cache                    │              │
   │  forge.cache.get(        │                    │              │
   │    metric: heartRate,    │                    │              │
   │    range: lastDay)       │                    │              │
   │ ──────────────────────────────────────────────────────────────>
   │  [cached records]        │                    │              │
   │ <──────────────────────────────────────────────────────────────
```

**When to use:** Periodic background data pulls, offline-first apps, when you want deduplication across multiple syncs.

### What Each Component Does

| Component | Role | Created by |
|-----------|------|------------|
| **HealthForgeClient** | Main entry point. Creates and wires everything together. | You (`HealthForgeClient()`) |
| **ProviderRegistry** | Stores which providers are available. Finds providers that support a given metric. | Client (internal) |
| **AuthOrchestrator** | Requests permissions from providers (HealthKit prompt, OAuth flow, etc.). | Client (via `forge.auth`) |
| **QueryBuilder** | Fluent API to specify what data you want (metrics, providers, time range). | `forge.query()` |
| **QueryExecutor** | Runs a query against providers, collects results, optionally merges. | You (`QueryExecutor(...)`) |
| **SyncManager** | Fetches from a provider, deduplicates against cache, stores results. | Client (via `forge.sync()`) |
| **CacheManager** | Interface for local record storage. `InMemoryCacheManager` (default) or `DriftCacheManager` (persistent). | Client or You |
| **DriftCacheManager** | Persistent cache backed by SQLite via Drift. Deduplicates by natural key (provider + metric + time + device). | You (`DriftCacheManager(database: db)`) |
| **MergeEngine** | Detects overlapping records across providers and resolves conflicts using configurable strategies. | Client (internal) |
| **HealthProvider** | Adapter for a specific data source. Handles auth + data fetching. | Each adapter package |
| **TokenStore** | Secure storage wrapper for OAuth tokens via `flutter_secure_storage`. | You (optional) |

### Lifecycle: Typical Integration

```
1. SETUP           forge = HealthForgeClient()
                   forge.use(AppleHealthProvider())
                   forge.use(OuraHealthProvider(...))

2. AUTHORIZE       await forge.auth.authorizeAll()
                   // User sees HealthKit permission dialog
                   // User completes Oura OAuth in browser

3. SYNC            await forge.sync(
   (periodic)        provider: apple, metric: heartRate,
                     range: last24Hours)
                   // Fetches → merges → caches

4. QUERY           result = await executor.execute(query)
   (on demand)     // Live fetch from providers
                   // OR read from cache:
                   cached = await forge.cache.get(
                     metric: heartRate, range: today)

5. DISPLAY         for (record in result.records)
                     show(record.provider, record.beatsPerMinute)
```

## Installation

Add only the packages you need to your `pubspec.yaml`:

```yaml
dependencies:
  health_forge: ^0.1.0

  # Platform adapters (pick one or both)
  health_forge_apple: ^0.1.0   # iOS — Apple HealthKit
  health_forge_ghc: ^0.1.0     # Android — Google Health Connect

  # REST API adapters (optional)
  health_forge_oura: ^0.1.0    # Oura Ring
  health_forge_strava: ^0.1.0  # Strava
```

Then run:

```bash
flutter pub get
```

---

## Platform Setup

### iOS (HealthKit)

**1. Add HealthKit entitlement**

Create or update `ios/Runner/Runner.entitlements`:

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

**2. Add usage descriptions to `ios/Runner/Info.plist`**

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app reads health data to show your fitness metrics.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>This app writes health data to sync your records.</string>
```

**3. Enable HealthKit in Xcode**

Open `ios/Runner.xcworkspace` in Xcode → select the Runner target → Signing & Capabilities → click "+ Capability" → add "HealthKit".

### Android (Health Connect)

**1. Add permissions to `android/app/src/main/AndroidManifest.xml`**

Add inside the `<manifest>` tag, before `<application>`:

```xml
<uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_SLEEP"/>
<uses-permission android:name="android.permission.health.READ_EXERCISE"/>
<uses-permission android:name="android.permission.health.READ_DISTANCE"/>
<uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED"/>
```

Add more permissions as needed for the metrics you use (e.g., `READ_WEIGHT`, `READ_BODY_FAT`, `READ_BLOOD_GLUCOSE`, `READ_BLOOD_PRESSURE`, `READ_OXYGEN_SATURATION`, `READ_RESPIRATORY_RATE`).

**2. Ensure Health Connect is installed**

Health Connect is pre-installed on Android 14+. On Android 13, users need to install the [Health Connect app](https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata) from the Play Store.

### Oura Ring

Oura uses OAuth 2.0 with PKCE. You need to register an app in the [Oura Developer Portal](https://cloud.ouraring.com/oauth/applications).

**1. Register your app and note your:**
- Client ID
- Redirect URI (e.g., `com.yourapp://oura-callback`)

**2. Create the auth manager and provider:**

```dart
import 'package:health_forge_oura/health_forge_oura.dart';

final ouraAuth = OuraAuthManager(
  clientId: 'YOUR_OURA_CLIENT_ID',
  redirectUri: 'com.yourapp://oura-callback',
  urlLauncher: (authUrl) async {
    // Launch authUrl in a browser/webview.
    // Return the redirect URL containing the auth code,
    // or null if the user cancels.
    return await launchAndWaitForRedirect(authUrl);
  },
  // Restore token from previous session (see Token Persistence below)
  initialToken: savedOuraToken,
  // Persist token whenever it changes
  onTokenChanged: (token) => saveOuraToken(token),
);

final ouraApi = OuraApiClient(authManager: ouraAuth);
final ouraProvider = OuraHealthProvider(
  authManager: ouraAuth,
  apiClient: ouraApi,
);
```

The `urlLauncher` callback is how you handle the OAuth browser flow — use packages like `url_launcher` + `app_links` or a custom in-app browser.

### Strava

Strava uses OAuth 2.0 with PKCE. Strava’s token endpoint also expects a **client secret** on code exchange and refresh — there is no public-only client flow.

**1. Register your app at [Strava API Settings](https://www.strava.com/settings/api)** and note your:
- Client ID
- Client Secret (keep on a server for production)
- Authorization Callback Domain (e.g., `com.yourapp`)

**2a. Production — backend token exchange (no secret in the app)**

Implement `StravaTokenExchange` to call your backend; the server holds `client_secret` and forwards to Strava’s token URL. Have your API return Strava’s token JSON (`access_token`, `refresh_token`, `expires_in`) and map it to `StravaToken`:

```dart
import 'package:dio/dio.dart';
import 'package:health_forge_strava/health_forge_strava.dart';

StravaToken stravaTokenFromApi(Map<String, dynamic> body) {
  return StravaToken(
    accessToken: body['access_token'] as String,
    refreshToken: body['refresh_token'] as String,
    expiresAt: DateTime.now().add(
      Duration(seconds: (body['expires_in'] as num).toInt()),
    ),
  );
}

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
    return stravaTokenFromApi(res.data!);
  }

  @override
  Future<StravaToken> refreshAccessToken({required String refreshToken}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/strava/token',
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );
    return stravaTokenFromApi(res.data!);
  }
}

final stravaAuth = StravaAuthManager(
  clientId: 'YOUR_STRAVA_CLIENT_ID',
  tokenExchange: BackendStravaExchange(dio, baseUrl: 'https://api.yourapp.com'),
  redirectUri: 'com.yourapp://strava-callback',
  urlLauncher: (authUrl) async => launchAndWaitForRedirect(authUrl),
  initialToken: savedStravaToken,
  onTokenChanged: saveStravaToken,
);

final stravaApi = StravaApiClient(authManager: stravaAuth);
final stravaProvider = StravaHealthProvider(
  authManager: stravaAuth,
  apiClient: stravaApi,
);
```

**2b. Development — direct exchange (secret in the app)**

```dart
import 'package:health_forge_strava/health_forge_strava.dart';

final stravaAuth = StravaAuthManager(
  clientId: 'YOUR_STRAVA_CLIENT_ID',
  clientSecret: 'YOUR_STRAVA_CLIENT_SECRET',
  redirectUri: 'com.yourapp://strava-callback',
  urlLauncher: (authUrl) async {
    return await launchAndWaitForRedirect(authUrl);
  },
  initialToken: savedStravaToken,
  onTokenChanged: (token) => saveStravaToken(token),
);

final stravaApi = StravaApiClient(authManager: stravaAuth);
final stravaProvider = StravaHealthProvider(
  authManager: stravaAuth,
  apiClient: stravaApi,
);
```

> **Security:** Prefer **2a** for release builds. **2b** embeds recoverable credentials; use only for local/dev or if you accept that risk.

---

## Basic Usage

### Create a Client

```dart
import 'package:health_forge/health_forge.dart';

final forge = HealthForgeClient();
```

You can optionally pass a custom `MergeConfig` and/or a persistent cache:

```dart
// With custom merge configuration
final forge = HealthForgeClient(
  mergeConfig: MergeConfig(
    defaultStrategy: ConflictStrategy.priorityBased,
    providerPriority: [DataProvider.apple, DataProvider.oura],
  ),
);
```

**For persistent storage** (recommended for production), use the built-in `DriftCacheManager`:

```dart
import 'package:drift/native.dart';
import 'package:health_forge/health_forge.dart';

// Create a Drift database backed by a file
final db = HealthCacheDatabase(
  NativeDatabase.createInBackground(File('health_cache.db')),
);

final forge = HealthForgeClient(
  cache: DriftCacheManager(database: db),
);
```

Without `DriftCacheManager`, the default `InMemoryCacheManager` is used — data is lost on app restart.

### Register Providers

Register each provider you want to use:

```dart
import 'package:health_forge_apple/health_forge_apple.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';

// Platform providers
forge.use(AppleHealthProvider());   // iOS
forge.use(GhcHealthProvider());     // Android

// REST API providers (see Platform Setup for auth config)
forge.use(ouraProvider);
forge.use(stravaProvider);
```

### Authorize

Request permissions from all registered providers:

```dart
// Authorize all at once
final results = await forge.auth.authorizeAll();
// results: {DataProvider.apple: AuthResult.success(), ...}

// Or authorize individually
final result = await forge.auth.authorize(DataProvider.apple);
if (result.isSuccess) {
  print('Authorized!');
}

// Check authorization status
final isAuthed = await forge.auth.isAuthorized(DataProvider.apple);

// Check all providers
final statuses = await forge.auth.checkAll();
// statuses: {DataProvider.apple: true, DataProvider.oura: false}
```

### Query Data

Build and execute queries using the fluent API:

```dart
// Build a query
final builder = forge.query()
  ..forMetric(MetricType.heartRate)
  ..inRange(TimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  ));

// Execute it
final executor = QueryExecutor(
  registry: forge.registry,
  mergeEngine: MergeEngine(config: const MergeConfig()),
);
final result = await executor.execute(builder.build());

// Access records
for (final record in result.records) {
  if (record is HeartRateSample) {
    print('${record.provider}: ${record.beatsPerMinute} bpm');
  }
}

// Check for errors (provider failures don't block other providers)
if (result.errors.isNotEmpty) {
  for (final entry in result.errors.entries) {
    print('${entry.key} failed: ${entry.value}');
  }
}
```

**Query multiple metrics:**

```dart
final builder = forge.query()
  ..forMetrics([MetricType.heartRate, MetricType.sleepSession, MetricType.workout])
  ..inRange(TimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  ));
```

**Query from a specific provider:**

```dart
final builder = forge.query()
  ..forMetric(MetricType.sleepSession)
  ..from(DataProvider.oura)
  ..inRange(lastWeek);
```

**Query from multiple specific providers:**

```dart
final builder = forge.query()
  ..forMetric(MetricType.heartRate)
  ..fromProviders([DataProvider.apple, DataProvider.strava])
  ..inRange(lastWeek);
```

### Sync to Cache

Sync fetches data from a provider and stores it in the local cache:

```dart
final syncResult = await forge.sync(
  provider: DataProvider.apple,
  metric: MetricType.heartRate,
  range: TimeRange(
    start: DateTime.now().subtract(const Duration(days: 1)),
    end: DateTime.now(),
  ),
);

print('Fetched: ${syncResult.recordsFetched}');
print('Cached: ${syncResult.recordsCached}');
print('Duration: ${syncResult.duration}');

if (syncResult.error != null) {
  print('Error: ${syncResult.error}');
}

// Read from cache
final cached = await forge.cache.get(
  metric: MetricType.heartRate,
  range: lastDay,
);
```

---

## Supported Metrics

Each provider supports a different subset of the 19 available `MetricType` values:

| MetricType | Apple | GHC | Oura | Strava |
|------------|:-----:|:---:|:----:|:------:|
| heartRate | R | R | R | R |
| steps | R | R | R | |
| sleepSession | R | R | R | |
| hrv | R | R | | |
| restingHeartRate | R | R | | |
| bloodOxygen | R | R | R | |
| respiratoryRate | R | R | | |
| weight | R | R | | |
| bodyFat | R | R | | |
| bloodPressure | R | R | | |
| bloodGlucose | R | R | | |
| calories | R | R | R | R |
| distance | R | R | | R |
| elevation | | | | R |
| workout | R | R | | R |
| readiness | | | R | |
| stress | | | R | |
| sleepScore | | | R | |
| recovery | | | | |

**R** = read access supported.

Check capabilities programmatically:

```dart
final caps = provider.capabilities;
if (caps.supports(MetricType.heartRate)) {
  // This provider can fetch heart rate data
}
```

### Record Envelope Fields

Every record carries these metadata fields via `HealthRecordMixin`:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Internal UUID for cache storage |
| `provider` | `DataProvider` | Which provider sourced this record |
| `providerRecordType` | `String` | Provider's name for this data type (e.g., "heartrate", "HEART_RATE") |
| `providerRecordId` | `String?` | Native ID from the provider's API (HealthKit UUID, Oura ID, Strava activity ID) |
| `startTime` / `endTime` | `DateTime` | Measurement time interval |
| `capturedAt` | `DateTime` | When the record was ingested |
| `provenance` | `Provenance?` | Source device, app, and data origin |
| `freshness` | `Freshness` | `live` or `cached` |
| `extensions` | `Map` | Provider-specific data (see Extensions section) |

### Provenance and Traceability

All adapters automatically populate `Provenance` on every record:

```dart
final record = result.records.first as HeartRateSample;

// Where did this data come from?
print(record.provider);                         // DataProvider.apple
print(record.providerRecordId);                 // "ABC-123-DEF" (HealthKit UUID)
print(record.provenance?.dataOrigin);           // DataOrigin.native_
print(record.provenance?.sourceDevice?.model);  // "Apple Watch Series 9"
print(record.provenance?.sourceApp);            // "com.apple.health"
```

| Adapter | `dataOrigin` | `sourceDevice` | `sourceApp` |
|---------|-------------|----------------|-------------|
| Apple HealthKit | `native_` | From HealthKit (model + manufacturer) | Bundle ID (e.g., "com.apple.health") |
| Google Health Connect | `native_` | From Health Connect | Package name |
| Oura Ring | `mapped` | Not available (REST API) | "com.ouraring.oura" |
| Strava | `mapped` | Not available (REST API) | "com.strava" |

---

## Provider-Specific Extensions

Health Forge preserves provider-specific data that doesn't fit the common model using typed extensions on records.

### Oura Sleep Extension

When fetching sleep data from Oura, each `SleepSession` includes Oura-specific metrics:

```dart
final records = await ouraProvider.fetchRecords(
  metricType: MetricType.sleepSession,
  timeRange: lastNight,
);

for (final record in records) {
  if (record is SleepSession) {
    // Standard fields available from any provider
    print('Total sleep: ${record.totalSleepMinutes} min');
    print('Deep sleep: ${record.deepMinutes} min');

    // Oura-specific extension data
    final ext = OuraSleepExtension.fromJson(record.extensions);
    print('Readiness score: ${ext.readinessScore}');
    print('Temperature deviation: ${ext.temperatureDeviation}');
    print('Sleep contribution: ${ext.readinessContributorSleep}');
  }
}
```

### Strava Workout Extension

When fetching workouts from Strava, each `ActivitySession` includes Strava-specific metrics:

```dart
final records = await stravaProvider.fetchRecords(
  metricType: MetricType.workout,
  timeRange: lastWeek,
);

for (final record in records) {
  if (record is ActivitySession) {
    // Standard fields available from any provider
    print('${record.activityName}: ${record.distanceMeters}m');
    print('Avg HR: ${record.averageHeartRate} bpm');

    // Strava-specific extension data
    final ext = StravaWorkoutExtension.fromJson(record.extensions);
    print('Suffer score: ${ext.sufferScore}');
    print('Route polyline: ${ext.routePolyline}');
    if (ext.segmentEfforts != null) {
      print('Segments: ${ext.segmentEfforts!.length}');
    }
  }
}
```

---

## Conflict Resolution

When multiple providers report overlapping data (e.g., Apple Watch and Strava both tracking a run), Health Forge's merge engine partitions by metric type, clusters records that **overlap in time** (with a configurable padding threshold), then resolves each cluster with the strategy you choose.

### Strategies

| Strategy | Behavior |
|----------|----------|
| `priorityBased` | Keep the record from the highest-priority provider (default) |
| `keepAll` | Keep all records, with attribution and a conflict report |
| `average` | Average numeric values across providers |
| `mostGranular` | Keep the record with the highest temporal resolution |
| `custom` | Your own resolution callback |

### Custom Configuration

```dart
final config = MergeConfig(
  // Default strategy for all metrics
  defaultStrategy: ConflictStrategy.priorityBased,

  // Global provider priority (higher = preferred)
  providerPriority: [
    DataProvider.apple,              // highest priority
    DataProvider.googleHealthConnect,
    DataProvider.oura,
    DataProvider.strava,             // lowest priority
  ],

  // Override strategy per metric
  perMetricStrategy: {
    MetricType.heartRate: ConflictStrategy.average,
    MetricType.workout: ConflictStrategy.keepAll,
  },

  // Override priority per metric
  perMetricPriority: {
    MetricType.sleepSession: [DataProvider.oura, DataProvider.apple],
  },

  // Tuning: how close values must be to count as "similar" (5% default)
  valueSimilarityThreshold: 0.05,

  // Tuning: max seconds apart for records to be considered overlapping
  timeOverlapThresholdSeconds: 300,  // 5 minutes
);

final forge = HealthForgeClient(mergeConfig: config);
```

**Using with queries:**

```dart
final builder = forge.query()
  ..forMetric(MetricType.heartRate)
  ..inRange(lastWeek)
  ..withMerge(MergeConfig(
    defaultStrategy: ConflictStrategy.average,
  ));
```

---

## Platform Detection

For apps that run on multiple platforms, use runtime detection to register real providers on-device and fall back to mocks on desktop/web:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = HealthForgeClient();

  if (!kIsWeb && Platform.isIOS) {
    client.use(AppleHealthProvider());
  } else if (!kIsWeb && Platform.isAndroid) {
    client.use(GhcHealthProvider());
  } else {
    // Desktop/web — use mocks for development
    client.use(MockAppleProvider());
  }

  // REST API providers work on all platforms
  client.use(ouraProvider);
  client.use(stravaProvider);

  runApp(MyApp(client: client));
}
```

---

## Running the Example App

The repository includes a full example app at `example/` that demonstrates all features including real OAuth flows for Oura and Strava:

```bash
cd example

# Desktop (uses mock providers, auto-authorized)
flutter run -d macos

# iOS device (real Apple HealthKit + real Oura/Strava OAuth)
flutter run -d <device-id>

# Android device (real Health Connect + real Oura/Strava OAuth)
flutter run -d <device-id>
```

### OAuth Setup

To use real Oura and Strava on mobile devices:

1. **Oura** — Create an app at [Oura Developer Portal](https://cloud.ouraring.com/oauth/applications), set redirect URI to `healthforge://oura/callback`, update `_ouraClientId` in `example/lib/main.dart`
2. **Strava** — Create an app at [Strava API Settings](https://www.strava.com/settings/api), set redirect URI to `healthforge://strava/callback`, update `_stravaClientId` and `_stravaClientSecret` in `example/lib/main.dart`

The `healthforge://` URL scheme is pre-configured in `Info.plist` (iOS) and `AndroidManifest.xml` (Android).

### Merge Configuration

The example app configures per-metric conflict resolution to handle high-frequency wearable data:

```dart
final client = HealthForgeClient(
  mergeConfig: const MergeConfig(
    perMetricStrategy: {
      MetricType.steps: ConflictStrategy.keepAll,
      MetricType.heartRate: ConflictStrategy.keepAll,
      MetricType.calories: ConflictStrategy.keepAll,
      // ... other high-frequency metrics
    },
  ),
);
```

This preserves all readings from Apple Watch (which records steps/HR in small increments every ~5 minutes) instead of merging them with the default 300s overlap threshold.

### Screens

The example app has three screens:
- **Dashboard** — 10 metric cards (steps, calories, distance, workouts, HR, resting HR, sleep, readiness, SpO2, weight) with source-aware aggregation that avoids double-counting from iPhone + Apple Watch
- **Providers** — connect/disconnect providers with local auth state tracking (works around iOS HealthKit's unreliable `hasPermissions`)
- **Browse** — query any metric type by date range; tap a record to see all fields in a detail bottom sheet

See `example/README.md` for full details.

---

## FAQ

### Can I use my own database instead of the built-in cache?

Yes. Health Forge ships with two cache implementations:

- **`InMemoryCacheManager`** — default, data lost on restart (good for prototyping)
- **`DriftCacheManager`** — persistent SQLite storage via Drift (recommended for production)

```dart
// Use the built-in persistent cache
final db = HealthCacheDatabase(NativeDatabase.createInBackground(file));
final forge = HealthForgeClient(cache: DriftCacheManager(database: db));
```

You can also implement your own by extending `CacheManager`:

```dart
class MyHiveCacheManager implements CacheManager {
  // Implement put(), get(), invalidate(), clear(),
  // lastSyncTime(), updateSyncMetadata()
}

final forge = HealthForgeClient(cache: MyHiveCacheManager());
```

### Do I need the cache? Can I just query directly?

Yes. Cache and sync are optional. If you only need real-time data, use `QueryExecutor` directly:

```dart
final result = await executor.execute(query);
```

This fetches live from providers without touching the cache. Use sync when you want offline access or deduplication across multiple fetch cycles.

### What happens when two providers report the same workout?

The `MergeEngine` first **splits records by metric type**, then clusters records in each bucket whose time ranges **overlap** (each end time is extended by `timeOverlapThresholdSeconds`, default **5 minutes**). That cluster is treated as one conflict group. Finer matching using provider IDs, numeric similarity (`valueSimilarityThreshold` is reserved for this), or device identity is **not** applied in the current `DuplicateDetector`.

When a group has more than one record, the configured `ConflictStrategy` resolves it. Default is `priorityBased` — the highest-priority provider's record wins.

### Does querying one provider block others?

No. If one provider throws an exception during a query, the error is captured in `QueryResult.errors` and records from other providers are still returned:

```dart
final result = await executor.execute(query);
print(result.records);  // Records from successful providers
print(result.errors);   // {DataProvider.oura: "timeout"}
```

### Can I write data back to HealthKit or Health Connect?

Not yet. All adapters are currently read-only. Write support is planned for a future release.

### How do I handle OAuth token refresh for Oura/Strava?

When a token expires, call `refreshToken()`:

```dart
final currentToken = ouraAuth.currentToken;
if (currentToken != null && currentToken.isExpired) {
  final newToken = await ouraAuth.refreshToken(currentToken);
  // newToken is automatically set as currentToken
}
```

**Token persistence** is built into the auth managers via two constructor parameters:

```dart
final ouraAuth = OuraAuthManager(
  clientId: '...',
  redirectUri: '...',
  urlLauncher: launchAndWaitForRedirect,
  // Restore from secure storage on app start
  initialToken: await loadSavedToken(),
  // Auto-save whenever token changes (authorize, refresh, clear)
  onTokenChanged: (token) async {
    if (token != null) {
      await tokenStore.save(DataProvider.oura, jsonEncode(token.toJson()));
    } else {
      await tokenStore.delete(DataProvider.oura);
    }
  },
);
```

Both `OuraToken` and `StravaToken` support `toJson()`/`fromJson()` for serialization. The `TokenStore` class wraps `flutter_secure_storage` for encrypted persistence.

### How do I add a custom health provider?

Implement the `HealthProvider` interface:

```dart
class MyWearableProvider implements HealthProvider {
  @override
  DataProvider get providerType => DataProvider.garmin; // or a custom value

  @override
  String get displayName => 'My Wearable';

  @override
  ProviderCapabilities get capabilities => const ProviderCapabilities(
    supportedMetrics: {MetricType.heartRate: AccessMode.read},
    syncModel: SyncModel.fullWindow,
  );

  @override
  Future<bool> isAuthorized() async => true;

  @override
  Future<AuthResult> authorize() async => AuthResult.success();

  @override
  Future<void> deauthorize() async {}

  @override
  Future<List<HealthRecordMixin>> fetchRecords({
    required MetricType metricType,
    required TimeRange timeRange,
  }) async {
    // Fetch from your API and return unified records
    return [...];
  }
}
```

### What's the difference between `forge.query()` and `forge.sync()`?

| | `query()` + `execute()` | `sync()` |
|---|---|---|
| **Fetches from** | All matching providers (or filtered) | One provider at a time |
| **Caches data** | No | Yes |
| **Merges** | Only if `withMerge()` is set | Always (new + existing cache) |
| **Returns** | `QueryResult` with records | `SyncResult` with counts |
| **Use case** | Real-time display | Background data pull, offline access |

A typical app uses **sync** on a timer to keep the cache fresh, then reads from **cache** for display. Use **query** for one-off fetches or when you want data from multiple providers merged in a single call.
